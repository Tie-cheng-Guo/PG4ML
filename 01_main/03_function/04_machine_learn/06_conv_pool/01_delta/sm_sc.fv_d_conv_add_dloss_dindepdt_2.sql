-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_add_dloss_dindepdt_2(anyarray, anyarray, int[2], int[4], anyelement);
create or replace function sm_sc.fv_d_conv_add_dloss_dindepdt_2
(
  i_background            anyarray           ,
  i_background_len        int[2]             ,
  i_window                anyarray           ,
  i_window_len            int[2]             ,
  -- i_input_arr_asso        float[]         ,
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
      select 
        sm_sc_fa_mx_sum
        (
          i_dloss_ddepdt[(a_cur_y - 1) * i_window_len[1] + 1 : a_cur_y * i_window_len[1]]
                        [(a_cur_x - 1) * i_window_len[2] + 1 : a_cur_x * i_window_len[2]] -- 损失函数导数的独立窗口分组
          -- *` array_fill[1.0, i_window_len] -- 矩阵点算求导
        )
      from generate_series(1, (coalesce(i_padding[1], 0) + i_background_len[1] + coalesce(i_padding[2], 0) - i_window_len[1]) / i_stride[1]) tb_a_cur_y(a_cur_y)
        , generate_series(1, (coalesce(i_padding[3], 0) + i_background_len[2] + coalesce(i_padding[4], 0) - i_window_len[2]) / i_stride[2]) tb_a_cur_x(a_cur_x)
    )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_add_dloss_dindepdt_2
--   (
--     array[array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[-1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , array[-10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0]
--          ]
--    , array[[1.0 :: float, 2.0, 3.0], [-1.0, -2.0, -3.0], [3.0, -2.0, 1.0]]
--    , array[2, 2]
--   );


