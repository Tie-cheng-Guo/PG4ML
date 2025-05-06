-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_add_dloss_dindepdt_1
-- (
--   -- anyarray, 
--   int[]
-- -- , anyarray
-- , int[2]
-- -- , anyarray
-- -- , int[]
-- , anyarray
-- , int[2]
-- , int[4]
-- -- , anyelement
-- );
create or replace function sm_sc.fv_d_conv_add_dloss_dindepdt_1
(
  -- i_background            anyarray           ,
  i_background_len        int[]             ,
  -- i_window                anyarray           ,
  i_window_len            int[]             ,
  -- i_depdt_var             anyarray           ,
  -- i_depdt_var_len         int[]             ,
  i_dloss_ddepdt          anyarray           ,
  i_stride                int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding               int[4]              default  array[0, 0, 0, 0]       -- ,  -- 上下左右补齐行数/列数
  -- i_padding_value         anyelement          default  '0.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_dloss_ddepdt_len_2d      int[2]    :=   array[array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1), array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt))];
  v_background_len        -- int[2]    :=   array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
                             int[2]    :=   i_background_len[array_length(i_background_len, 1) - 1 : array_length(i_background_len, 1)];
  v_window_len               int[2]    :=   i_window_len[array_length(i_window_len, 1) - 1 : array_length(i_window_len, 1)];
begin
  -- if i_background_len is null
  -- then 
  --   i_background_len := array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
  -- end if;
  -- if v_window_len is null
  -- then 
  --   v_window_len := array[array_length(i_window, 1), array_length(i_window, 2)];
  -- end if;
  -- if i_depdt_var_len is null
  -- then 
  --   i_depdt_var_len := array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)];
  -- end if;

  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计二维长度
    if array_ndims(i_dloss_ddepdt) not between 2 and 4
    then 
      raise exception 'unsupport ndims of i_dloss_ddepdt';
    -- elsif -- -- i_background is not null and 
    --   array_ndims(i_background) <> array_ndims(i_dloss_ddepdt)
    -- then 
    --   raise exception 'unmatched ndims between i_background and i_dloss_ddepdt';
    -- elsif i_window is not null and array_ndims(i_window) <> 2 and array_ndims(i_window) <> array_ndims(i_dloss_ddepdt)
    -- then 
    --   raise exception 'no method for such i_window length!  Dims: %;', array_dims(i_window);
    -- elsif i_background_len is null or v_window_len is null or i_depdt_var_len is null or i_dloss_ddepdt is null 
    -- then 
    --   raise exception 'i_background_len, v_window_len, i_depdt_var_len, i_dloss_ddepdt should be not null.';
    elsif (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) % i_stride[1] <> 0
    then 
      raise exception 'imperfect window at 1d.';
    elsif (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) % i_stride[2] <> 0
    then 
      raise exception 'imperfect window at 2d.';
    elsif (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1 <> v_dloss_ddepdt_len_2d[1] / v_window_len[1]
    then                                                                                                                                         
      raise exception 'imperfect dloss_ddepdt at 1d.';                                                                                           
    elsif (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1 <> v_dloss_ddepdt_len_2d[2] / v_window_len[2]
    then 
      raise exception 'imperfect dloss_ddepdt at 2d.';
    -- elsif i_depdt_var_len is not null and i_depdt_var_len <> v_dloss_ddepdt_len_2d
    -- then 
    --   raise exception 'unmatched sizes of dloss_ddepdt and depdt_var_len.';
    elsif array_length(v_window_len, 1) = 3 and v_window_len[1] <> array_length(i_dloss_ddepdt, 1)
      or array_length(v_window_len, 1) = 4 and (v_window_len[1] <> array_length(i_dloss_ddepdt, 1) or v_window_len[2] <> array_length(i_dloss_ddepdt, 2))
    then 
      raise exception 'unmatch length between i_window and i_dloss_ddepdt at 3d or 4d.';
    end if;
  end if;
  
  if array_ndims(i_dloss_ddepdt) = 2
  then
    return     
    (    
      with
      -- dloss_ddepdt 的各个独立窗口
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_heigh,
          a_cur_width,
          i_dloss_ddepdt[(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
                        [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]] -- 损失函数导数的独立窗口分组
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_width(a_cur_width)
      ),
      -- 
      cte_ele_dloss_dindepdt as
      (
        select 
          tb_a_cur_heigh.a_cur_heigh,
          tb_a_cur_width.a_cur_width,
          coalesce
          (
            sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
              [tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1])]
              [tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2])]
            )
            , 0.0
          ) as a_dloss_dindepdt_ele
        from generate_series(1, v_background_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, v_background_len[2]) tb_a_cur_width(a_cur_width)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_heigh.a_cur_heigh between (tb_a_slice.a_cur_heigh - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_heigh * i_stride[1] + v_window_len[1]
          and tb_a_cur_width.a_cur_width between (tb_a_slice.a_cur_width - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_width * i_stride[2] + v_window_len[2]
        group by tb_a_cur_heigh.a_cur_heigh, tb_a_cur_width.a_cur_width
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_heigh,
          array_agg(a_dloss_dindepdt_ele order by a_cur_width) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_heigh
      )
      select 
        sm_sc.fv_augmented
		(
		  array_agg(a_dloss_dindepdt_y_slice order by a_cur_heigh), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
		  0.0 :: float
		)
      from cte_y_slice_dloss_dindepdt
    )
    ;
    
  elsif array_ndims(i_dloss_ddepdt) = 3
  then
    return     
    (    
      with
      -- dloss_ddepdt 的各个独立窗口
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_heigh,
          a_cur_width,
          i_dloss_ddepdt
            [ : ]
            [(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
            [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]] -- 损失函数导数的独立窗口分组
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_width(a_cur_width)
      ),
      -- 
      cte_ele_dloss_dindepdt as
      (
        select 
          tb_a_cur_heigh.a_cur_heigh,
          tb_a_cur_width.a_cur_width,
          coalesce
          (
            sm_sc.fa_mx_sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
                [ : ]
                [tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1]) : tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1])]
                [tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2]) : tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2])]
            )
            , array_fill(0.0, array[array_length(i_dloss_ddepdt, 1), 1, 1])
          ) as a_dloss_dindepdt_ele
        from generate_series(1, v_background_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, v_background_len[2]) tb_a_cur_width(a_cur_width)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_heigh.a_cur_heigh between (tb_a_slice.a_cur_heigh - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_heigh * i_stride[1] + v_window_len[1]
          and tb_a_cur_width.a_cur_width between (tb_a_slice.a_cur_width - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_width * i_stride[2] + v_window_len[2]
        group by tb_a_cur_heigh.a_cur_heigh, tb_a_cur_width.a_cur_width
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_heigh,
          sm_sc.fa_mx_concat_x3(a_dloss_dindepdt_ele order by a_cur_width) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_heigh
      )
      select 
        sm_sc.fv_augmented
		(
		  sm_sc.fa_mx_concat_x(a_dloss_dindepdt_y_slice order by a_cur_heigh), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
		  0.0 :: float
		)
      from cte_y_slice_dloss_dindepdt
    )
    ;
    
  elsif array_ndims(i_dloss_ddepdt) = 4
  then
    return     
    (    
      with
      -- dloss_ddepdt 的各个独立窗口
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_heigh,
          a_cur_width,
          i_dloss_ddepdt
            [ : ]
            [ : ]
            [(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
            [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]] -- 损失函数导数的独立窗口分组
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_width(a_cur_width)
      ),
      -- 
      cte_ele_dloss_dindepdt as
      (
        select 
          tb_a_cur_heigh.a_cur_heigh,
          tb_a_cur_width.a_cur_width,
          coalesce
          (
            sm_sc.fa_mx_sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
                [ : ]
                [ : ]
                [tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1]) : tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1])]
                [tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2]) : tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2])]
            )
            , array_fill(0.0, array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2), 1, 1])
          ) as a_dloss_dindepdt_ele
        from generate_series(1, v_background_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, v_background_len[2]) tb_a_cur_width(a_cur_width)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_heigh.a_cur_heigh between (tb_a_slice.a_cur_heigh - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_heigh * i_stride[1] + v_window_len[1]
          and tb_a_cur_width.a_cur_width between (tb_a_slice.a_cur_width - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_width * i_stride[2] + v_window_len[2]
        group by tb_a_cur_heigh.a_cur_heigh, tb_a_cur_width.a_cur_width
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_heigh,
          sm_sc.fa_mx_concat_x4(a_dloss_dindepdt_ele order by a_cur_width) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_heigh
      )
      select 
        sm_sc.fv_augmented
		(
		  sm_sc.fa_mx_concat_x3(a_dloss_dindepdt_y_slice order by a_cur_heigh), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
		  0.0 :: float
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
--   -- null :: float[]               ,                           -- i_background            anyarray  
--   array[4, 5]                   ,                           -- i_background_len        int[2]    
--   -- null :: float[]               ,                           -- i_window                anyarray  
--   array[3, 3]                   ,                           -- v_window_len            int[2]    
--   -- null :: float[]               ,                           -- i_depdt_var             anyarray  
--   -- array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[1, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[1, 1]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  -- ,                                      -- i_padding               int[4]    
--   -- 0.0  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_add_dloss_dindepdt_1
-- (
--   -- null :: float[]               ,                           -- i_background            anyarray  
--   array[6, 9]                   ,                           -- i_background_len        int[2]    
--   -- null :: float[]               ,                           -- i_window                anyarray  
--   array[3, 3]                   ,                           -- v_window_len            int[2]    
--   -- null :: float[]               ,                           -- i_depdt_var             anyarray  
--   -- array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[1, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  -- ,                                      -- i_padding               int[4]    
--   -- 0.0  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_add_dloss_dindepdt_1
-- (
--   -- null :: float[]               ,                           -- i_background            anyarray  
--   array[6, 9]                   ,                           -- i_background_len        int[2]    
--   -- null :: float[]               ,                           -- i_window                anyarray  
--   array[3, 3]                   ,                           -- v_window_len            int[2]    
--   -- null :: float[]               ,                           -- i_depdt_var             anyarray  
--   -- array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [
--     [
--       [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]                
--     , [1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--     , [2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--     , [3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--     , [4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--     , [5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--     ] 
--   , [ 
--       [-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0, -9.0]                
--     , [-1.1, 1.2, -1.3, 1.4, -1.5, 1.6, -1.7, 1.8, -1.9]                
--     , [-2.1, 2.2, -2.3, 2.4, -2.5, 2.6, -2.7, 2.8, -2.9]                       
--     , [-3.1, 3.2, -3.3, 3.4, -3.5, 3.6, -3.7, 3.8, -3.9]                
--     , [-4.1, 4.2, -4.3, 4.4, -4.5, 4.6, -4.7, 4.8, -4.9]           
--     , [-5.1, 5.2, -5.3, 5.4, -5.5, 5.6, -5.7, 5.8, -5.9]
--     ]
--   ] :: float[],                                                -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                         -- i_stride                int[2]    
--   array[0, 0, 0, 0]  -- ,                                      -- i_padding               int[4]    
--   -- 0.0  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_add_dloss_dindepdt_1
-- (
--   -- null :: float[]               ,                           -- i_background            anyarray  
--   array[2, 2, 6, 9]                   ,                           -- i_background_len        int[2]    
--   -- null :: float[]               ,                           -- i_window                anyarray  
--   array[3, 3]                   ,                           -- v_window_len            int[2]        -- array[2, 2, 3, 3]
--   -- null :: float[]               ,                           -- i_depdt_var             anyarray  
--   -- array[2, 2, 6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [
--     [
--       [
--         [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]                
--       , [1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--       , [2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--       , [3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--       , [4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--       , [5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--       ] 
--     , [ 
--         [-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0, -9.0]                
--       , [-1.1, 1.2, -1.3, 1.4, -1.5, 1.6, -1.7, 1.8, -1.9]                
--       , [-2.1, 2.2, -2.3, 2.4, -2.5, 2.6, -2.7, 2.8, -2.9]                       
--       , [-3.1, 3.2, -3.3, 3.4, -3.5, 3.6, -3.7, 3.8, -3.9]                
--       , [-4.1, 4.2, -4.3, 4.4, -4.5, 4.6, -4.7, 4.8, -4.9]           
--       , [-5.1, 5.2, -5.3, 5.4, -5.5, 5.6, -5.7, 5.8, -5.9]
--       ]
--     ]
--   , [
--       [
--         [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]                
--       , [1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--       , [2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--       , [3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--       , [4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--       , [5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--       ] 
--     , [ 
--         [-1.0, 2.0, -3.0, 4.0, -5.0, 6.0, -7.0, 8.0, -9.0]                
--       , [-1.1, 1.2, -1.3, 1.4, -1.5, 1.6, -1.7, 1.8, -1.9]                
--       , [-2.1, 2.2, -2.3, 2.4, -2.5, 2.6, -2.7, 2.8, -2.9]                       
--       , [-3.1, 3.2, -3.3, 3.4, -3.5, 3.6, -3.7, 3.8, -3.9]                
--       , [-4.1, 4.2, -4.3, 4.4, -4.5, 4.6, -4.7, 4.8, -4.9]           
--       , [-5.1, 5.2, -5.3, 5.4, -5.5, 5.6, -5.7, 5.8, -5.9]
--       ]
--     ]
--   ] :: float[],                                                -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  -- ,                                      -- i_padding               int[4]    
--   -- 0.0  :: float                                             -- i_padding_value         anyelement
-- );


