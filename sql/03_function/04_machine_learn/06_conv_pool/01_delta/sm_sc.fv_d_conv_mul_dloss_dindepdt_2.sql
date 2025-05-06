-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_mul_dloss_dindepdt_2
-- (
--   anyarray
-- -- , int[]
-- -- , anyarray
-- , int[2]
-- -- , anyarray
-- -- , int[]
-- , anyarray
-- , int[2]
-- , int[4]
-- , anyelement
-- );
create or replace function sm_sc.fv_d_conv_mul_dloss_dindepdt_2
(
  i_background            anyarray           ,
  -- i_background_len        int[]             ,
  -- i_window                anyarray           ,
  i_window_len            int[2]             ,
  -- i_depdt_var             anyarray           ,
  -- i_depdt_var_len         int[]             ,
  i_dloss_ddepdt          anyarray           ,
  i_stride                int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding               int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value         anyelement          default  '0.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_dloss_ddepdt_len_ex      int[2]    :=   array[array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1), array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt))];
  v_background_len_ex        int[2]    :=   array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
                          -- int[2]    :=   i_background_len[array_length(i_background_len, 1) - 1 : array_length(i_background_len, 1)];
  v_window_len            -- int[2]    :=   array[array_length(i_window, 1), array_length(i_window, 2)];
                          -- alias for i_window_len;
                             int[2]    :=   i_window_len[array_length(i_window_len, 1) - 1 : array_length(i_window_len, 1)];
  v_ret                      i_dloss_ddepdt%type;
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- if v_background_len_ex is null
    -- then 
    --   v_background_len_ex := array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
    -- end if;
    -- if v_window_len is null
    -- then 
    --   v_window_len := array[array_length(i_window, 1), array_length(i_window, 2)];
    -- end if;
    -- if i_depdt_var_len is null
    -- then 
    --   i_depdt_var_len := array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)];
    -- end if;
    
    -- 审计二维长度
    if array_ndims(i_background) not between 2 and 4 
      or array_ndims(i_dloss_ddepdt) not between 2 and 4
      or array_ndims(i_dloss_ddepdt) <> array_ndims(i_background)
    then 
      raise exception 'no method for such ndims!';
    -- elsif i_window is not null and array_ndims(i_window) <> 2
    -- then 
    --   raise exception 'no method for such i_window length!  Dims: %;', array_dims(i_window);
    elsif v_background_len_ex is null or v_window_len is null 
      -- or i_depdt_var_len is null 
      or i_dloss_ddepdt is null 
    then 
      raise exception 'v_background_len_ex, v_window_len, i_depdt_var_len, i_dloss_ddepdt should be not null.';
    elsif (coalesce(i_padding[1], 0) + v_background_len_ex[1] + coalesce(i_padding[2], 0) - v_window_len[1]) % i_stride[1] <> 0
    then 
      raise exception 'imperfect window at 1d.';
    elsif (coalesce(i_padding[3], 0) + v_background_len_ex[2] + coalesce(i_padding[4], 0) - v_window_len[2]) % i_stride[2] <> 0
    then 
      raise exception 'imperfect window at 2d.';
    elsif (coalesce(i_padding[1], 0) + v_background_len_ex[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1 <> v_dloss_ddepdt_len_ex[1] / v_window_len[1]
    then                                                                                                                                         
      raise exception 'imperfect dloss_ddepdt at 1d.';                                                                                           
    elsif (coalesce(i_padding[3], 0) + v_background_len_ex[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1 <> v_dloss_ddepdt_len_ex[2] / v_window_len[2]
    then 
      raise exception 'imperfect dloss_ddepdt at 2d.';
    -- elsif i_depdt_var_len is not null and i_depdt_var_len <> v_dloss_ddepdt_len_ex
    -- then 
    --   raise exception 'unmatched sizes of dloss_ddepdt and depdt_var_len.';
    end if;
  end if;
  
  i_background := 
    sm_sc.fv_augmented
    (
      i_background, 
      array[-i_padding[1] + 1, -i_padding[3] + 1], 
      array[v_background_len_ex[1] + i_padding[2], v_background_len_ex[2] + i_padding[4]], 
      i_padding_value
    );
  
  if array_ndims(i_dloss_ddepdt) = 2
  then 
    return     
    (    
      select 
        sm_sc.fa_mx_sum
        (
          i_dloss_ddepdt[(a_cur_y - 1) * v_window_len[1] + 1 : a_cur_y * v_window_len[1]]
                        [(a_cur_x - 1) * v_window_len[2] + 1 : a_cur_x * v_window_len[2]] -- 损失函数导数的独立窗口分组
          *` 
          sm_sc.fv_d_mul
          (
            i_background[(a_cur_y - 1) * i_stride[1] + 1 : (a_cur_y - 1) * i_stride[1] + v_window_len[1]]
                        [(a_cur_x - 1) * i_stride[2] + 1 : (a_cur_x - 1) * i_stride[2] + v_window_len[2]]
          )
        )
      from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len_ex[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_y(a_cur_y)
        , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len_ex[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_x(a_cur_x)
    )
    ;
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    v_ret := 
      (    
        select 
          sm_sc.fa_mx_sum
          (
            i_dloss_ddepdt
              [ : ]
              [(a_cur_y - 1) * v_window_len[1] + 1 : a_cur_y * v_window_len[1]]
              [(a_cur_x - 1) * v_window_len[2] + 1 : a_cur_x * v_window_len[2]] -- 损失函数导数的独立窗口分组
            *` 
            sm_sc.fv_d_mul
            (
              i_background
                [ : ]
                [(a_cur_y - 1) * i_stride[1] + 1 : (a_cur_y - 1) * i_stride[1] + v_window_len[1]]
                [(a_cur_x - 1) * i_stride[2] + 1 : (a_cur_x - 1) * i_stride[2] + v_window_len[2]]
            )
          )
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len_ex[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_y(a_cur_y)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len_ex[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_x(a_cur_x)
      );
    
    if array_length(i_window_len, 1) = 2
    then
      return 
        sm_sc.fv_mx_ele_3d_2_2d
        (
          sm_sc.fv_aggr_slice_sum
          (
            v_ret
          , array[array_length(i_dloss_ddepdt, 1), 1, 1]
          )
        , array[1, 2]
        , 2
        )
      ;
    else 
      return v_ret;
    end if;
    
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    v_ret := 
      (    
        select 
          sm_sc.fa_mx_sum
          (
            i_dloss_ddepdt
              [ : ]
              [ : ]
              [(a_cur_y - 1) * v_window_len[1] + 1 : a_cur_y * v_window_len[1]]
              [(a_cur_x - 1) * v_window_len[2] + 1 : a_cur_x * v_window_len[2]] -- 损失函数导数的独立窗口分组
            *` 
            sm_sc.fv_d_mul
            (
              i_background
                [ : ]
                [ : ]
                [(a_cur_y - 1) * i_stride[1] + 1 : (a_cur_y - 1) * i_stride[1] + v_window_len[1]]
                [(a_cur_x - 1) * i_stride[2] + 1 : (a_cur_x - 1) * i_stride[2] + v_window_len[2]]
            )
          )
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len_ex[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_y(a_cur_y)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len_ex[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_x(a_cur_x)
      );
    
    if array_length(i_window_len, 1) = 2
    then
      return 
        sm_sc.fv_mx_slice_4d_2_2d
        (
          sm_sc.fv_aggr_slice_sum
          (
            v_ret
          , array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2), 1, 1]
          )
        , array[1, 2]
        , array[1, 1]
        )
      ;
    else 
      return v_ret;
    end if;
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_mul_dloss_dindepdt_2
-- (
--   array[[1,2,3,4,5],[3,4,5,6,7],[2,4,6,8,5],[7,5,3,4,8]] :: float[],   -- i_background            anyarray  
--   -- array[4, 5]                   ,                           -- v_background_len_ex        int[2]    
--   -- array[[1,4,7],[2,5,8],[3,6,9]] :: float[],                           -- i_window                anyarray  
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
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.0  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_mul_dloss_dindepdt_2
-- (
--   array              
--   [[-1, 2, 3, 4, 5, -6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, -24, 25, 26, -27, 28, 29]                       
--   ,[31, -32, -33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, -43, 44, 45, 46, 47, 48, -49]           
--   ,[51, -52, 53, 54, -55, 56, 57, -58, 59]] :: float[],     -- i_background            anyarray  
--   -- array[6, 9]                   ,                           -- v_background_len_ex        int[2]    
--   -- array[[1,4,-7],[-2,5,8],[3,-6,9]] :: float[],                        -- i_window                anyarray  
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
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.0  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_mul_dloss_dindepdt_2
-- (
--   array   
--   [                   
--     [[-1, 2, 3, 4, 5, -6, 7, 8, 9]                
--     ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--     ,[21, 22, 23, -24, 25, 26, -27, 28, 29]                       
--     ,[31, -32, -33, 34, 35, 36, 37, 38, 39]                
--     ,[41, 42, -43, 44, 45, 46, 47, 48, -49]           
--     ,[51, -52, 53, 54, -55, 56, 57, -58, 59]]    
--   , [[-1, 2, 3, 4, 5, -6, 7, 8, 9]                
--     ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--     ,[21, 22, 23, -24, 25, 26, -27, 28, 29]                       
--     ,[31, -32, -33, 34, 35, 36, 37, 38, 39]                
--     ,[41, 42, -43, 44, 45, 46, 47, 48, -49]           
--     ,[51, -52, 53, 54, -55, 56, 57, -58, 59]] 
--   ]:: float[],     -- i_background            anyarray  
--   -- array[6, 9]                   ,                           -- v_background_len_ex        int[2]    
--   -- array[[1,4,-7],[-2,5,8],[3,-6,9]] :: float[],                        -- i_window                anyarray  
--   array[3, 3]                   ,   -- array[2, 3, 3]          -- v_window_len            int[2]    
--   -- null :: float[]               ,                           -- i_depdt_var             anyarray  
--   -- array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array  
--   [                   
--     [[1, 2, 3, 4, 5, 6, 7, 8, 9]                
--     ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--     ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--     ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--     ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--     ,[51, 52, 53, 54, 55, 56, 57, 58, 59]]      
--   , [[1, 2, 3, 4, 5, 6, 7, 8, 9]                
--     ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--     ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--     ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--     ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--     ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] 
--   ]:: float[],        -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.0  :: float                                             -- i_padding_value         anyelement
-- );
