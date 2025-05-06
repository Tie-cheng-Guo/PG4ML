-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_conv_2d_im2col_py(float[], float[], float[], int[2], int[4], float, int);
create or replace function sm_sc.fv_conv_2d_im2col_py
(
  i_background         float[]                                      -- 背景矩阵，可以为三维四维，背景以最高两个维度当作滑动高宽
, i_window             float[]                                      -- 卷积核窗口矩阵，限二维窗口
, i_window_bias        float[]    default  null                     -- 卷积核的偏移量。限定与 i_window 的维数一致，且窗口高宽以外的维度长度与 i_background, i_window 一致，窗口高宽的维度长度都是1
, i_stride             int[2]     default  array[1, 1]              -- 纵向与横向步长
, i_padding            int[4]     default  array[0, 0, 0, 0]        -- 上下左右补齐行数/列数
, i_padding_value      float      default  0.0                      -- 补齐填充元素值
, i_padding_mode       int        default  0                        -- 0: value; 1: wrap
)
returns float[]
as
$$
  import numpy as np
  # from scipy import signal
  
  v_background      = np.float64(i_background)     
  v_window          = np.float64(i_window)         
  # v_window_bias     = np.float64(i_window_bias)  
  # v_stride          = np.int8(i_stride)          
  # v_padding         = np.int8(i_padding)         
  # v_padding_value   = np.float64(i_padding_value)
  
  # # mirror heigh & mirror width
  # if v_window.ndim == 2 :
  #   v_window = v_window[::-1, ::-1]
  # elif v_window.ndim == 3 :
  #   v_window = v_window[::, ::-1, ::-1]
  # elif v_window.ndim == 4 :
  #   v_window = v_window[::, ::, ::-1, ::-1]
  
  
  # brodcast window dims align
  if v_window.ndim == v_background.ndim - 1 :
    v_window = np.repeat(v_window[np.newaxis, : ], v_background.shape[0], axis = 0)
  elif v_window.ndim == v_background.ndim - 2 :
    v_window = np.repeat( \
    np.repeat(v_window[np.newaxis , np.newaxis, :], v_background.shape[1], axis = 1) \
    , v_background.shape[0], axis = 0)
  
  # padding
  if not np.array_equal(i_padding, np.array([0, 0, 0, 0])) :
    if i_padding_mode == 0 :
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
  v_return_heigh = (v_background.shape[v_background.ndim - 2] - v_window.shape[v_background.ndim - 2]) // i_stride[0] + 1
  v_return_width = (v_background.shape[v_background.ndim - 1] - v_window.shape[v_background.ndim - 1]) // i_stride[1] + 1
  
  # im2col, matmul
  if v_background.ndim == 2 :
    v_return = np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_return_heigh, v_return_width, v_window.shape[0], v_window.shape[1]) \
    , strides=(v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    .reshape(v_return_heigh * v_return_width, v_window.shape[0] * v_window.shape[1])
  
    v_return = np.matmul(np.float64(v_return), np.float64(v_window).reshape(v_window.shape[0] * v_window.shape[1], 1)) \
    .reshape(v_return_heigh, v_return_width)
  
  elif v_background.ndim == 3 :
    v_return = np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_background.shape[0], v_return_heigh, v_return_width, v_window.shape[1], v_window.shape[2]) \
    , strides=(v_ele_len * v_background.shape[1] * v_background.shape[2], v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    .reshape(v_background.shape[0], v_return_heigh * v_return_width, v_window.shape[1] * v_window.shape[2])
    
    v_return = np.matmul(np.float64(v_return), np.float64(v_window).reshape(v_window.shape[0], v_window.shape[1] * v_window.shape[2], 1)) \
    .reshape(v_return.shape[0], v_return_heigh, v_return_width)
  
  elif v_background.ndim == 4 :
    v_return = np.lib.stride_tricks.as_strided(v_background \
    , shape=(v_background.shape[0], v_background.shape[1], v_return_heigh, v_return_width, v_window.shape[2], v_window.shape[3]) \
    , strides=(v_ele_len * v_background.shape[1] * v_background.shape[2] * v_background.shape[3], v_ele_len * v_background.shape[2] * v_background.shape[3], v_ele_len * i_stride[0] * v_background.shape[-1], v_ele_len * i_stride[1], v_ele_len * v_background.shape[-1], v_ele_len) \
    ) \
    .reshape(v_background.shape[0], v_background.shape[1], v_return_heigh * v_return_width, v_window.shape[2] * v_window.shape[3])
    
    v_return = np.matmul(np.float64(v_return), np.float64(v_window).reshape(v_window.shape[0], v_window.shape[1], v_window.shape[2] * v_window.shape[3], 1)) \
    .reshape(v_return.shape[0], v_return.shape[1], v_return_heigh, v_return_width)
  
  if i_window_bias :
    return (v_return + i_window_bias).tolist()
  else :
    return v_return.tolist()
$$
language plpython3u stable
parallel safe
;

-- select sm_sc.fv_conv_2d_im2col_py
--   (
--     array[[1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--          ] :: float[]
--    , array[[0, 1, 0], [1, 1, 1], [0, 1, 0]]
--    , array[[0.5]]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_conv_2d_im2col_py
--   (
--     array[[1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--          ]
--    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_conv_2d_im2col_py
--   (
--     array[[1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--          ]
--    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
--    , array[[0.0]]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0.0
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_conv_2d_im2col_py
--   (
--     array
--     [
--      [[1,2,3,4,5,6]
--      ,[10,20,30,40,50,60]
--      ,[100,200,300,400,500,600]
--      ,[-1,-2,-3,-4,-5,-6]
--      ,[-10,-20,-30,-40,-50,-60]
--      ]
--     ,[[1,2,3,4,5,6]
--      ,[100,200,300,400,500,600]
--      ,[10,20,30,40,50,60]
--      ,[-10,-20,-30,-40,-50,-60]
--      ,[-1,-2,-3,-4,-5,-6]
--      ]
--     ]
--    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
--    , array[[0.5]]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0.0
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_conv_2d_im2col_py
--   (
--     array
--     [
--      [
--       [[1,2,3,4,5,6]
--       ,[10,20,30,40,50,60]
--       ,[100,200,300,400,500,600]
--       ,[-1,-2,-3,-4,-5,-6]
--       ,[-10,-20,-30,-40,-50,-60]
--       ]
--      ,[[1,2,3,4,5,6]
--       ,[100,200,300,400,500,600]
--       ,[10,20,30,40,50,60]
--       ,[-10,-20,-30,-40,-50,-60]
--       ,[-1,-2,-3,-4,-5,-6]
--       ]
--      ],
--      [
--       [[10,20,30,40,50,60]
--       ,[1,2,3,4,5,6]
--       ,[-1,-2,-3,-4,-5,-6]
--       ,[-10,-20,-30,-40,-50,-60]
--       ,[100,200,300,400,500,600]
--       ]
--      ,[[-1,-2,-3,-4,-5,-6]
--       ,[-10,-20,-30,-40,-50,-60]
--       ,[10,20,30,40,50,60]
--       ,[100,200,300,400,500,600]
--       ,[1,2,3,4,5,6]
--       ]
--      ]
--     ]
--    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
--    , array[[0.5]]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0.0
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_conv_2d_im2col_py
--   (
--     array
--     [
--      [
--       [[1,2,3,4,5,6]
--       ,[10,20,30,40,50,60]
--       ,[100,200,300,400,500,600]
--       ,[-1,-2,-3,-4,-5,-6]
--       ,[-10,-20,-30,-40,-50,-60]
--       ]
--      ,[[1,2,3,4,5,6]
--       ,[100,200,300,400,500,600]
--       ,[10,20,30,40,50,60]
--       ,[-10,-20,-30,-40,-50,-60]
--       ,[-1,-2,-3,-4,-5,-6]
--       ]
--      ],
--      [
--       [[10,20,30,40,50,60]
--       ,[1,2,3,4,5,6]
--       ,[-1,-2,-3,-4,-5,-6]
--       ,[-10,-20,-30,-40,-50,-60]
--       ,[100,200,300,400,500,600]
--       ]
--      ,[[-1,-2,-3,-4,-5,-6]
--       ,[-10,-20,-30,-40,-50,-60]
--       ,[10,20,30,40,50,60]
--       ,[100,200,300,400,500,600]
--       ,[1,2,3,4,5,6]
--       ]
--      ]
--     ]
--    , array
--     [
--      [
--       [[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
--      ,[[1.1, 1.1, 1.1], [1.1, 3.1, 1.1], [1.1, 1.1, 1.1]]
--      ],
--      [
--       [[1.1, 1.1, 1.1], [1.1, 2.5, 1.1], [1.1, 1.1, 1.1]]
--      ,[[1.1, 1.1, 1.1], [1.1, 0.1, 1.1], [1.1, 1.1, 1.1]]
--      ]
--     ]
--    , array[[[[0.5]],[[1.0]]],[[[-1.0]],[[0.9]]]]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0.0
--   ) :: decimal[] ~=` 3;