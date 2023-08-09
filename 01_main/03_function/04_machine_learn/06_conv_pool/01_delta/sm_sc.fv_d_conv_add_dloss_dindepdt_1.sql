-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_add_dloss_dindepdt_1(anyarray, anyarray, int[2], int[4], anyelement);
create or replace function sm_sc.fv_d_conv_add_dloss_dindepdt_1
(
  i_background            anyarray           ,
  i_background_len        int[2]             ,
  i_window                anyarray           ,
  i_window_len            int[2]             ,
  i_depdt_var             anyarray           ,
  i_depdt_var_len         int[2]             ,
  i_dloss_ddepdt          anyarray           ,
  i_stride                int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding               int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value         anyelement          default  '0.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_dloss_ddepdt_len      int[2]    :=   array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2)];
begin
  if i_background_len is null
  then 
    i_background_len := array[array_length(i_background, 1), array_length(i_background, 2)];
  end if;
  if i_window_len is null
  then 
    i_window_len := array[array_length(i_window, 1), array_length(i_window, 2)];
  end if;
  if i_depdt_var_len is null
  then 
    i_depdt_var_len := array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)];
  end if;
  
  -- 审计二维长度
  if i_background is not null and array_ndims(i_background) <> 2
  then 
    return null; raise notice 'no method for such i_background length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_background), i_background_len[1], i_background_len[2];
  elsif i_window is not null and array_ndims(i_window) <> 2
  then 
    return null; raise notice 'no method for such i_window length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_window), i_window_len[1], i_window_len[2];
  elsif i_background_len is null or i_window_len is null or i_depdt_var_len is null or i_dloss_ddepdt is null 
  then 
    raise exception 'i_background_len, i_window_len, i_depdt_var_len, i_dloss_ddepdt should be not null.';
  elsif (coalesce(i_padding[1], 0) + i_background_len[1] + coalesce(i_padding[2], 0) - i_window_len[1]) % i_stride[1] <> 0
  then 
    raise exception 'imperfect window at 1d.';
  elsif (coalesce(i_padding[3], 0) + i_background_len[2] + coalesce(i_padding[4], 0) - i_window_len[2]) % i_stride[2] <> 0
  then 
    raise exception 'imperfect window at 2d.';
  elsif (coalesce(i_padding[1], 0) + i_background_len[1] + coalesce(i_padding[2], 0) - i_window_len[1]) / i_stride[1] * i_window_len[1] <> v_dloss_ddepdt_len[1]
  then 
    raise exception 'imperfect dloss_ddepdt at 1d.';
  elsif (coalesce(i_padding[3], 0) + i_background_len[2] + coalesce(i_padding[4], 0) - i_window_len[2]) / i_stride[2] * i_window_len[2] <> v_dloss_ddepdt_len[2]
  then 
    raise exception 'imperfect dloss_ddepdt at 2d.';
  elsif i_depdt_var_len is not null and i_depdt_var_len <> v_dloss_ddepdt_len
  then 
    raise exception 'unmatched sizes of dloss_ddepdt and depdt_var_len.';
  else
    return     
    (    
      with
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_y_window,
          a_cur_x_window,
          i_dloss_ddepdt[(a_cur_y_window - 1) * i_window_len[1] + 1 : a_cur_y_window * i_window_len[1]]
                        [(a_cur_x_window - 1) * i_window_len[2] + 1 : a_cur_x_window * i_window_len[2]] -- 损失函数导数的独立窗口分组
          -- *` array_fill[1.0, i_window_len] -- 独立窗口矩阵点算求导 ddepdt_dindepdt
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + i_background_len[1] + coalesce(i_padding[2], 0) - i_window_len[1]) / i_stride[1]) tb_a_cur_y_window(a_cur_y_window)
          , generate_series(1, (coalesce(i_padding[3], 0) + i_background_len[2] + coalesce(i_padding[4], 0) - i_window_len[2]) / i_stride[2]) tb_a_cur_x_window(a_cur_x_window)
      ),
      cte_ele_dloss_dindepdt as
      (
        select 
          a_cur_y,
          a_cur_x,
          coalesce
          (
            sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
              [tb_a_cur_y.a_cur_y - ((tb_a_slice.a_cur_y_window - 1) * i_stride[1])]
              [tb_a_cur_x.a_cur_x - ((tb_a_slice.a_cur_x_window - 1) * i_stride[2])]
            )
            , 0.0
          ) as a_dloss_dindepdt_ele
        from generate_series(1, i_background_len) tb_a_cur_y(a_cur_y)
          , generate_series(1, i_background_len) tb_a_cur_x(a_cur_x)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_y.a_cur_y between (tb_a_slice.a_cur_y_window - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_y_window * i_stride[1]
          and tb_a_cur_x.a_cur_x between (tb_a_slice.a_cur_x_window - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_x_window * i_stride[2]
        group by a_cur_y, a_cur_x
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_y,
          array_agg(a_dloss_dindepdt_ele order by a_cur_x) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_y
      )
      select 
        sm_sc.fv_augmented
		(
		  array_agg(a_dloss_dindepdt_y_slice order by a_cur_y), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[i_background_len[1] + i_padding[2], i_background_len[2] + i_padding[4]], 
		  0.0
		)
      from cte_y_slice_dloss_dindepdt
    )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_add_dloss_dindepdt_1
-- (
--   null,              ,                           -- i_background            anyarray  
--   array[9, 6]        ,                           -- i_background_len        int[2]    
--   null,              ,                           -- i_window                anyarray  
--   array[3, 3]        ,                           -- i_window_len            int[2]    
--   null,              ,                           -- i_depdt_var             anyarray  
--   array[9, 6]        ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[1, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]],        -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                           -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                           -- i_padding               int[4]    
--   0.0                                            -- i_padding_value         anyelement
-- );