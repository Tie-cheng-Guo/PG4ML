-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_tunnel_conv_py(float[], float[], int, float[]);
create or replace function sm_sc.fv_tunnel_conv_py
(
  i_background         float[]                    -- 背景矩阵
, i_tunnel             float[]                    -- 卷乘法核隧道矩阵，
                                                  --   限定 array_dims(i_tunnel) =  array_dims(i_background) + 1
                                                  --   限定 array_length(i_tunnel, i_tunnel_axis( + 1) 以外的维轴), array_length(i_background, i_tunnel_axis 以外的维轴) 对齐
                                                  --   限定 i_tunnel, i_background 在 i_tunnel_axis( + 1) 矩阵乘法高宽匹配
, i_tunnel_axis        int                        -- 规约: 隧道维轴正数序号从 1 开始。
, i_tunnel_bias        float[]    default  null   -- 隧道核的偏移量。限定 i_tunnel_bias.shape[-1] = i_tunnel.shape[-1], i_tunnel_bias.shape[-2] = 1
                                                  --   限定 array_dims(i_tunnel_bias) =  array_dims(i_background)
                                                  --   限定 array_length(i_tunnel_bias, i_tunnel_axis 以外的维轴), array_length(i_background, i_tunnel_axis 以外的维轴) 对齐
                                                  --   限定 array_length(i_tunnel_bias, i_tunnel_axis) == array_length(i_tunnel, i_tunnel_axis + 1)
)
returns float[]
as
$$
  import numpy as np
  v_background = np.float64(i_background)
  v_tunnel = np.float64(i_tunnel)
  v_tunnel_bias = np.float64(i_tunnel_bias)
  v_dims = np.arange(0, v_tunnel.ndim)
  
  # 统一维轴为 -1 开始的负数序号
  if i_tunnel_axis > 0 :
    v_tunnel_axis = i_tunnel_axis - 1 - v_background.ndim
  elif i_tunnel_axis == 0 :
    v_tunnel_axis = - v_dloss_ddepdt.ndim
  else :
    v_tunnel_axis = i_tunnel_axis
  
  # 将 v_background 的 v_tunnel_axis 维轴换置到 -1 位置，再在 -2 位置增加一个维轴。当 v_tunnel_axis == -1，不必置换操作
  if v_tunnel_axis != -1 :
    v_background = np.moveaxis(v_background, v_tunnel_axis, -1)
  v_background = np.expand_dims(v_background, axis = -2)
  
  # 将 v_tunnel 的 v_tunnel_axis 和 v_tunnel_axis + 1 维轴换置到 -2, -1 位置
  v_tunnel = \
    np.transpose \
    ( \
      v_tunnel \
    , axes = \
        tuple \
        ( \
          np.concatenate \
          ( \
            ( \
              v_dims[ : v_tunnel_axis + v_tunnel.ndim - 1] \
            , v_dims[v_tunnel_axis + v_tunnel.ndim + 1 : ] \
            , v_dims[v_tunnel_axis + v_tunnel.ndim - 1 : v_tunnel_axis + v_tunnel.ndim + 1] \
            ) \
          , axis = 0 \
          ) \
        ) \
    )
  
  # 执行隧道卷乘，再对齐维轴数(清除 -2 维轴)，还原维轴至原来位置
  v_matmul = np.matmul(v_background, v_tunnel)
  v_matmul = np.squeeze(v_matmul, axis = -2)
  v_matmul = np.moveaxis(v_matmul, -1, v_tunnel_axis)
  
  # 点加偏移量
  if v_tunnel_bias.shape != () :
    v_matmul = v_matmul + v_tunnel_bias
  
  return v_matmul.tolist()
$$
language plpython3u stable
parallel safe
;

-- select array_dims(
--   sm_sc.fv_tunnel_conv_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 3, 2, 1, 1])
--   , -3
--   , null
--   ))
--   
-- 
-- select array_dims(
--   sm_sc.fv_tunnel_conv_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 3, 2, 6, 1])
--   , 2
--   , null
--   ))
--   
-- select array_dims(
--   sm_sc.fv_tunnel_conv_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 1, 1, 4, 2])
--   , -1
--   , sm_sc.fv_new_rand(array[5, 1, 6, 2])
--   ))
--   
-- select array_dims(
--   sm_sc.fv_tunnel_conv_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[1, 3, 6, 2, 4])
--   , 3
--   , sm_sc.fv_new_rand(array[1, 3, 2, 4])
--   ))