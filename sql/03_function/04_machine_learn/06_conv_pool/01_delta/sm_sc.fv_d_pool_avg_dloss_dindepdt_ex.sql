-- -- 卷积的矩阵乘法实现：
-- --   https://www.cnblogs.com/shine-lee/p/10775831.html
-- --   https://blog.csdn.net/qq_40263477/article/details/104979609
-- -- 卷积的 fft 实现
-- --   https://blog.csdn.net/qq_37527608/article/details/120922348
-- -- 卷积与矩阵乘法算法调优：
-- --  https://blog.csdn.net/lizhengx/article/details/83246833
-- -- 卷积求导
-- --  https://blog.csdn.net/wangjianyu0115/article/details/62222301

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_avg_dloss_dindepdt_ex(int[2], float[][], int[2], int[4]);
create or replace function sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
(
  -- i_array_len          int[2]                                               ,  -- 原矩阵(卷积第一目参数)高宽，
  i_window_len         int[2]                                     ,  -- 卷积核窗口
  i_dloss_ddepdt           float[]                                     ,  -- 即已求出的损失函数对 y 的导数矩阵
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]          -- 上下左右补齐行数/列数
)
returns float[][]
as
$$
declare
  -- -- v_dloss_dindepdt               float[];     --   intact 之后的新矩阵
  -- -- v_len_y                  int             :=   coalesce(i_padding[1], 0) + i_array_len[1] + coalesce(i_padding[2], 0);     --   新矩阵高
  -- -- v_len_x                  int             :=   coalesce(i_padding[3], 0) + i_array_len[2] + coalesce(i_padding[4], 0);     --   新矩阵宽
  -- -- v_cur_y                  int             ;     --   新矩阵高游标
  -- -- v_cur_x                  int             ;     --   新矩阵宽游标
  -- -- v_windows_cnt_reciproca  float  :=   
    -- -- 1.0 :: float/ (array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) * array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) * i_window_len[1] * i_window_len[2]);     -- 开窗数量的倒数
  -- -- v_window_len_y           int             :=   array_length(i_window, array_ndims(i_window) - 1);
  -- -- v_window_len_x           int             :=   array_length(i_window, array_ndims(i_window));
  v_indepdt_len_ex         int[]    ;
  v_return                 float[]  ;
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计维度
    if array_ndims(i_dloss_ddepdt) > 4
    then 
      raise exception 'no method for such length!  Dims: %;', array_dims(i_dloss_ddepdt);
    -- -- elsif array_ndims(i_window) = 3 and array_length(i_window, 1) <> array_length(i_dloss_ddepdt, 1)
    -- --   or array_ndims(i_window) = 4 and (array_length(i_window, 1) <> array_length(i_dloss_ddepdt, 1) or array_length(i_window, 2) <> array_length(i_dloss_ddepdt, 2))
    -- -- then 
    -- --   raise exception 'unmatch length between i_window and i_dloss_ddepdt at 3d or 4d.';
    end if;
  end if;
  
  i_dloss_ddepdt := i_dloss_ddepdt /` (i_window_len[1] * i_window_len[2]);
  
  -- -- if array_ndims(i_dloss_ddepdt) - array_ndims(i_window) = 2
  -- -- then 
  -- --   i_window = array[[i_window]];
  -- -- elsif array_ndims(i_dloss_ddepdt) - array_ndims(i_window) = 1
  -- -- then 
  -- --   i_window = array[i_window];
  -- -- end if;
  if i_window_len = i_stride
  then 
    v_indepdt_len_ex :=
      (select array_agg(array_length(i_dloss_ddepdt, a_no) order by a_no) from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a(a_no))
      *`
      sm_sc.fv_lpad(i_window_len, array[1], array_ndims(i_dloss_ddepdt) - 2)        
    ;
    if array_ndims(i_dloss_ddepdt) = 2
    then 
      return (sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py(v_indepdt_len_ex, i_dloss_ddepdt))[1 + i_padding[1] : v_indepdt_len_ex[1] - i_padding[2]][1 + i_padding[3] : v_indepdt_len_ex[2] - i_padding[4]];
    elsif array_ndims(i_dloss_ddepdt) = 3
    then 
      return (sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py(v_indepdt_len_ex, i_dloss_ddepdt))[ : ][1 + i_padding[1] : v_indepdt_len_ex[2] - i_padding[2]][1 + i_padding[3] : v_indepdt_len_ex[3] - i_padding[4]];
    elsif array_ndims(i_dloss_ddepdt) = 4
    then 
      return (sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py(v_indepdt_len_ex, i_dloss_ddepdt))[ : ][ : ][1 + i_padding[1] : v_indepdt_len_ex[3] - i_padding[2]][1 + i_padding[3] : v_indepdt_len_ex[4] - i_padding[4]];
    end if;
  else
    if array_ndims(i_dloss_ddepdt) = 2
    then
      v_return :=  
        sm_sc.fv_conv_2d_im2col_py
        (
          array_fill(0.0 :: float, array[i_window_len[1] - 1, 1])  -- 上方填零扩展
          |-||
          (
            sm_sc.fv_sample_y
            (
              array_fill(0.0 :: float, array[1, i_window_len[2] - 1])  -- 左侧填零扩展
              ||||
              (
                sm_sc.fv_sample_x
                (
                  i_dloss_ddepdt
                  , 1
                  , 1     
                  , array[int4range(1, i_stride[2], '[]')] -- 前向 i_stride - 1 当作求导入参的稀释插入宽度
                  , array[array[0.0 :: float]]
                )
              )[ : ][ : (array_length(i_dloss_ddepdt, 2) - 1) * i_stride[2] + 1]     -- 结尾稀释截断，相当于仅在原矩阵间隙周期插值
              ||||
              array_fill(0.0 :: float, array[1, i_window_len[2] - 1])  -- 右侧填零扩展
              , 1
              , 1     
              , array[int4range(1, i_stride[1], '[]')]  -- 前向 i_stride - 1 当作求导入参的稀释插入宽度
              , array[array[0.0 :: float]]
            )
          )[ : (array_length(i_dloss_ddepdt, 1) - 1) * i_stride[1] + 1][ : ]
          |-||
          array_fill(0.0 :: float, array[i_window_len[1] - 1, 1])   -- 下方填零扩展
        , array_fill(1.0 :: float, i_window_len)     -- i_window_back
        -- -- , 0.0         -- i_bias_back
        -- -- , array[1, 1] -- i_stride_back
        )
      ;
    
      return 
      (
        v_return[1 + i_padding[1] : array_length(v_return, 1) - i_padding[2]][1 + i_padding[3] : array_length(v_return, 2) - i_padding[4]]
        -- -- *` v_windows_cnt_reciproca
      ) :: float[]
      ;
    
    elsif array_ndims(i_dloss_ddepdt) = 3
    then 
      v_return :=  
        sm_sc.fv_conv_2d_im2col_py
        (
          array_fill(0.0 :: float, array[1, i_window_len[1] - 1, 1])  -- 上方填零扩展
          |-||
          (
            sm_sc.fv_sample_x
            (
              array_fill(0.0 :: float, array[1, 1, i_window_len[2] - 1])  -- 左侧填零扩展
              ||||
              (
                sm_sc.fv_sample_x3
                (
                  i_dloss_ddepdt
                  , 1
                  , 1     
                  , array[int4range(1, i_stride[2], '[]')] -- 前向 i_stride - 1 当作求导入参的稀释插入宽度
                  , array[[[0.0 :: float]]]
                )
              )[ : ][ : ][ : (array_length(i_dloss_ddepdt, 3) - 1) * i_stride[2] + 1]     -- 结尾稀释截断，相当于仅在原矩阵间隙周期插值
              ||||
              array_fill(0.0 :: float, array[1, 1, i_window_len[2] - 1])  -- 右侧填零扩展
              , 1
              , 1     
              , array[int4range(1, i_stride[1], '[]')]  -- 前向 i_stride - 1 当作求导入参的稀释插入宽度
              , array[[[0.0 :: float]]]
            )
          )[ : ][ : (array_length(i_dloss_ddepdt, 2) - 1) * i_stride[1] + 1][ : ]
          |-||
          array_fill(0.0 :: float, array[1, i_window_len[1] - 1, 1])   -- 下方填零扩展
        , array_fill(1.0 :: float, i_window_len)     -- i_window_back
        -- -- , 0.0         -- i_bias_back
        -- -- , array[1, 1] -- i_stride_back
        )
      ;
    
      return 
      (
        v_return[ : ][1 + i_padding[1] : array_length(v_return, 2) - i_padding[2]][1 + i_padding[3] : array_length(v_return, 3) - i_padding[4]]
        -- -- *` v_windows_cnt_reciproca
      ) :: float[]
      ;
    
    elsif array_ndims(i_dloss_ddepdt) = 4
    then 
      v_return :=  
        sm_sc.fv_conv_2d_im2col_py
        (
          array_fill(0.0 :: float, array[1, 1, i_window_len[1] - 1, 1])  -- 上方填零扩展
          |-||
          (
            sm_sc.fv_sample_x3
            (
              array_fill(0.0 :: float, array[1, 1, 1, i_window_len[2] - 1])  -- 左侧填零扩展
              ||||
              (
                sm_sc.fv_sample_x4
                (
                  i_dloss_ddepdt
                  , 1
                  , 1     
                  , array[int4range(1, i_stride[2], '[]')] -- 前向 i_stride - 1 当作求导入参的稀释插入宽度
                  , array[[[[0.0 :: float]]]]
                )
              )[ : ][ : ][ : ][ : (array_length(i_dloss_ddepdt, 4) - 1) * i_stride[2] + 1]     -- 结尾稀释截断，相当于仅在原矩阵间隙周期插值
              ||||
              array_fill(0.0 :: float, array[1, 1, 1, i_window_len[2] - 1])  -- 右侧填零扩展
              , 1
              , 1     
              , array[int4range(1, i_stride[1], '[]')]  -- 前向 i_stride - 1 当作求导入参的稀释插入宽度
              , array[[[[0.0 :: float]]]]
            )
          )[ : ][ : ][ : (array_length(i_dloss_ddepdt, 3) - 1) * i_stride[1] + 1][ : ]
          |-||
          array_fill(0.0 :: float, array[1, 1, i_window_len[1] - 1, 1])   -- 下方填零扩展
        , array_fill(1.0 :: float, i_window_len)     -- i_window_back
        -- -- , 0.0         -- i_bias_back
        -- -- , array[1, 1] -- i_stride_back
        )
      ;
      
      return 
      (
        v_return[ : ][ : ][1 + i_padding[1] : array_length(v_return, 3) - i_padding[2]][1 + i_padding[3] : array_length(v_return, 4) - i_padding[4]]
        -- -- *` v_windows_cnt_reciproca
      ) :: float[]
      ;
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
--   (
--      -- -- array[5, 7],
--      array[3, 3]
--    , array[[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
--   (
--      -- -- array[5, 7],
--      array[3, 3]
--    , array[[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
--   (
--      -- -- array[5, 7]
--      array[3, 3]
--    , array
--       [
--         [[1.1, 1.1, 1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--       , [[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[-1.1, 1.1, -1.1]
--          ]
--       ]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
--   (
--     -- array[5, 7],
--     array[3, 3]
--   , array
--     [
--       [
--         [[1.1, 1.1, 1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--       , [[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[-1.1, 1.1, -1.1]
--          ]
--       ]
--     , [
--         [[1.1, 1.1, -1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[-1.1, 1.1, 1.1]
--          ]
--       , [[-1.1, -1.1, 1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[-1.1, 1.1, -1.1]
--          ]
--       ]
--     ]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
--   (
--      -- -- array[5, 7],
--      array[2, 2]
--    , array[[[[1.1, 1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1, 1.1]
--          ]]]
--    , array[2, 2]
--    , array[0, 0, 0, 0]
--   );