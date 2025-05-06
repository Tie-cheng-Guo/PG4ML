-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_pool_min_py(float[], int[2], int[2], int[4], anyelement);
create or replace function sm_sc.fv_pool_min_py
(
  i_array              float[]                                              ,
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      float               default  'inf'     -- 补齐填充元素值
)
returns float[]
as
$$
  import numpy as np
  
  v_background      = np.float64(i_array)
  # v_window_len      = np.int8(i_window_len)
  
  # padding
  if not np.array_equal(i_padding, np.array([0, 0, 0, 0])) :
    if v_background.ndim == 2 :
      v_background = np.pad(v_background \
      , ((i_padding[0], i_padding[1]), (i_padding[2], i_padding[3])) \
      , 'constant' \
      , constant_values = i_padding_value)
    elif v_background.ndim == 3 :
      v_background = np.pad(v_background \
      , ((0, 0), (i_padding[0], i_padding[1]), (i_padding[2], i_padding[3])) \
      , 'constant' \
      , constant_values = i_padding_value)
    elif v_background.ndim == 4 :
      v_background = np.pad(v_background \
      , ((0, 0), (0, 0), (i_padding[0], i_padding[1]), (i_padding[2], i_padding[3])) \
      , 'constant' \
      , constant_values = i_padding_value)
  
  v_ele_len = v_background.dtype.itemsize

  # im2col, matmul
  if v_background.ndim == 2 :    
    return \
    np.min( \
    np.min( \
    np.lib.stride_tricks.as_strided(v_background \
    , shape=((v_background.shape[-2] - i_window_len[0]) // i_stride[0] + 1, (v_background.shape[-1] - i_window_len[1]) // i_stride[1] + 1, i_window_len[0], i_window_len[1]) \
    , strides=(v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    , axis=-1 \
    ) \
    , axis=-1 \
    ).tolist()
  
  elif v_background.ndim == 3 :
    return \
    np.min( \
    np.min( \
    np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_background.shape[0], (v_background.shape[-2] - i_window_len[0]) // i_stride[0] + 1, (v_background.shape[-1] - i_window_len[1]) // i_stride[1] + 1, i_window_len[0], i_window_len[1]) \
    , strides=(v_ele_len * v_background.shape[-1] * v_background.shape[-2], v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    , axis=-1 \
    ) \
    , axis=-1 \
    ).tolist()

  
  elif v_background.ndim == 4 :
    return \
    np.min( \
    np.min( \
    np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_background.shape[0], v_background.shape[1], (v_background.shape[-2] - i_window_len[0]) // i_stride[0] + 1, (v_background.shape[-1] - i_window_len[1]) // i_stride[1] + 1, i_window_len[0], i_window_len[1]) \
    , strides=(v_ele_len * v_background.shape[-1] * v_background.shape[-2] * v_background.shape[-3], v_ele_len * v_background.shape[-1] * v_background.shape[-2], v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    , axis=-1 \
    ) \
    , axis=-1 \
    ).tolist()
      
$$
language plpython3u stable
parallel safe
;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_pool_min_py
--   (
--     array[[1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--          ]
--    , array[3, 3]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_pool_min_py
--   (
--     array
--       [
--         [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       , [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       ]
--    , array[3, 3]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_pool_min_py
--   (
--    array
--    [
--      [
--        [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      , [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      ]
--    , [
--        [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      , [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      ]
--    ]
--    , array[3, 3]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;


