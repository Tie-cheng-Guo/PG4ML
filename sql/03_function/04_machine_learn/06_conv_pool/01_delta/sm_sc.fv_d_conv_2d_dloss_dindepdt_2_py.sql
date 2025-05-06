-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py(float[], float[], int[], int[2], int[4], float, int);
create or replace function sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py
(
  i_array              float[]                                                -- 原矩阵(卷积第一目参数)
, i_dloss_ddepdt       float[]                                                -- 即已求出的损失函数对 y 的导数矩阵
, i_window_len         int[]                                                  -- 卷积核窗口矩阵规格，如果是三维、四维，那么长度为三维或四维
, i_stride             int[2]              default  array[1, 1]               -- 纵向与横向步长
, i_padding            int[4]              default  array[0, 0, 0, 0]         -- 上下左右补齐行数/列数
, i_padding_value      float               default  0.0                       -- 补齐填充元素值
, i_padding_mode       int                 default 0                          -- 0: value; 1: wrap
)
returns float[]
as
$$
  import numpy as np
  
  v_dloss_ddepdt    = np.float64(i_dloss_ddepdt)
  v_background      = np.float64(i_array)
  v_window_len      = np.int8(i_window_len)
  
  # padding
  if i_padding_mode == 0 :
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
  elif i_padding_mode == 1 :
      if v_background.ndim == 2 :
        v_background = np.pad(v_background \
        , ((i_padding[0], i_padding[1]), (i_padding[2], i_padding[3])) \
        , 'wrap')
      elif v_background.ndim == 3 :
        v_background = np.pad(v_background \
        , ((0, 0), (i_padding[0], i_padding[1]), (i_padding[2], i_padding[3])) \
        , 'wrap')
      elif v_background.ndim == 4 :
        v_background = np.pad(v_background \
        , ((0, 0), (0, 0), (i_padding[0], i_padding[1]), (i_padding[2], i_padding[3])) \
        , 'wrap')
  
  v_ele_len = v_background.dtype.itemsize

  # im2col, matmul
  if v_background.ndim == 2 :
    return \
    ( \
    np.sum( \
    np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_dloss_ddepdt.shape[-2], v_dloss_ddepdt.shape[-1], v_window_len[-2], v_window_len[-1]) \
    , strides=(v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    .reshape(v_dloss_ddepdt.shape[-2] * v_dloss_ddepdt.shape[-1], v_window_len[-2], v_window_len[-1]) \
    * v_dloss_ddepdt.reshape(v_dloss_ddepdt.shape[-2] * v_dloss_ddepdt.shape[-1], 1, 1) \
    , axis=0) \
    )[::-1, ::-1].tolist()
  
  elif v_background.ndim == 3 :
    v_return = \
    np.sum( \
    np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_background.shape[0], v_dloss_ddepdt.shape[-2], v_dloss_ddepdt.shape[-1], v_window_len[-2], v_window_len[-1]) \
    , strides=(v_ele_len * v_background.shape[1] * v_background.shape[2], v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    .reshape(v_background.shape[0], v_dloss_ddepdt.shape[-2] * v_dloss_ddepdt.shape[-1], v_window_len[-2], v_window_len[-1]) \
    * v_dloss_ddepdt.reshape(v_dloss_ddepdt.shape[0], v_dloss_ddepdt.shape[-2] * v_dloss_ddepdt.shape[-1], 1, 1) \
    , axis=1)
    
    if v_window_len.size == 2 :
      return np.sum(v_return, axis=0)[::-1, ::-1].tolist()
    else : # v_window_len.size == 3
      return v_return[::, ::-1, ::-1].tolist()

  
  elif v_background.ndim == 4 :
    v_return = \
    np.sum( \
    np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_background.shape[0], v_background.shape[1], v_dloss_ddepdt.shape[-2], v_dloss_ddepdt.shape[-1], v_window_len[-2], v_window_len[-1]) \
    , strides=(v_ele_len * v_background.shape[1] * v_background.shape[2] * v_background.shape[3], v_ele_len * v_background.shape[2] * v_background.shape[3], v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    .reshape(v_background.shape[0], v_background.shape[1], v_dloss_ddepdt.shape[-2] * v_dloss_ddepdt.shape[-1], v_window_len[-2], v_window_len[-1]) \
    * v_dloss_ddepdt.reshape(v_dloss_ddepdt.shape[0], v_dloss_ddepdt.shape[1], v_dloss_ddepdt.shape[-2] * v_dloss_ddepdt.shape[-1], 1, 1) \
    , axis=2)
    
    if v_window_len.size == 2 :
      return np.sum(np.sum(v_return, axis=0), axis=0)[::-1, ::-1].tolist()
    elif v_window_len.size == 3 :
      return np.sum(v_return, axis=0)[::, ::-1, ::-1].tolist()
    else :   # v_window_len.size == 4
      return v_return[::, ::, ::-1, ::-1].tolist()
      
$$
language plpython3u stable
parallel safe
;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py
--   (
--     array[[1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--          ] :: float[]
--    , array[[1.1, 1.1, 1.1], [1.1, 1.1, 1.1]]
--    , array[3, 3]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py
--   (
--     array[[1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--          ] :: float[]
--    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
--    , array[3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );

-- select sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py
--   (
--     array
--       [
--         [
--           [1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--         ]
--       , [
--           [-1,2,-3,4,5,6]
--         , [10,-20,30,40,50,-60]
--         , [100,200,-300,400,500,600]
--         , [-1,2,-3,-4,-5,-6]
--         , [-10,-20,30,-40,50,-60]
--         ]
--       ]
--    , array[[[1.1, 1.1, -1.1], [1.1, -2.1, 1.1], [-1.1, 1.1, 1.1]],[[-1.1, 1.1, 1.1], [1.1, -2.1, 1.1], [1.1, 1.1, -1.1]]]
--    , array[3, 3]     --  array[2, 3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py
--   (
--    array
--    [
--      [
--        [
--          [1,2,3,4,5,6]
--        , [10,20,30,40,50,60]
--        , [100,200,300,400,500,600]
--        , [-1,-2,-3,-4,-5,-6]
--        , [-10,-20,-30,-40,-50,-60]
--        ]
--      , [
--          [-1,2,-3,4,5,6]
--        , [10,-20,30,40,50,-60]
--        , [100,200,-300,400,500,600]
--        , [-1,2,-3,-4,-5,-6]
--        , [-10,-20,30,-40,50,-60]
--        ]
--      ]
--    , [
--        [
--          [1,2,3,-4,5,6]
--        , [10,20,30,40,50,60]
--        , [100,-200,300,400,500,600]
--        , [-1,2,-3,-4,5,-6]
--        , [10,20,-30,-40,-50,60]
--        ]
--      , [
--          [1,2,-3,-4,5,6]
--        , [10,-20,-30,40,50,60]
--        , [100,200,-300,-400,-500,600]
--        , [-1,2,-3,-4,5,-6]
--        , [-10,-20,30,-40,50,-60]
--        ]
--      ]
--    ]  
--    , array
--      [
--        [[[1.1, 1.1, -1.1], [-1.1, -2.1, -1.1], [-1.1, 1.1, 1.1]]
--        ,[[-1.1, 1.1, 1.1], [1.1, -2.1, 1.1], [1.1, 1.1, -1.1]]]
--      , [[[1.1, 1.1, -1.1], [1.1, -2.1, 1.1], [-1.1, 1.1, 1.1]]
--        ,[[-1.1, 1.1, 1.1], [-1.1, -2.1, -1.1], [1.1, 1.1, -1.1]]]
--      ]
--    , array[3, 3]    -- array[2, 2, 3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   ) :: decimal[] ~=` 3;