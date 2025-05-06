-- drop function if exists sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py(float[], float[], int);
create or replace function sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py
(
  i_dloss_ddepdt       float[]
, i_tunnel             float[]
, i_tunnel_axis        int
)
returns float[]
as
$$
  import numpy as np
  v_dloss_ddepdt = np.float64(i_dloss_ddepdt)
  v_tunnel = np.float64(i_tunnel)
  v_dims = np.arange(0, v_tunnel.ndim)
  
  if i_tunnel_axis > 0 :
    v_tunnel_axis = i_tunnel_axis - 1 - v_dloss_ddepdt.ndim
  elif i_tunnel_axis == 0 :
    v_tunnel_axis = - v_dloss_ddepdt.ndim
  else :
    v_tunnel_axis = i_tunnel_axis
  
  # 将 v_dloss_ddepdt 的 v_tunnel_axis 维轴换置到 -1 位置，再在 -2 位置增加一个维轴。当 v_tunnel_axis == -1，不必置换操作
  if v_tunnel_axis != -1 :
    v_dloss_ddepdt = np.moveaxis(v_dloss_ddepdt, v_tunnel_axis, -1)
  v_dloss_ddepdt = np.expand_dims(v_dloss_ddepdt, axis = -2)
   
  # 将 v_tunnel 的 v_tunnel_axis 和 v_tunnel_axis + 1 维轴换置到 -2, -1 位置
  v_tunnel_transpose = \
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
             , v_dims[v_tunnel_axis + v_tunnel.ndim : v_tunnel_axis + v_tunnel.ndim + 1] \
             , v_dims[v_tunnel_axis + v_tunnel.ndim - 1 : v_tunnel_axis + v_tunnel.ndim] \
             ) \
           , axis = 0 \
           ) \
         ) \
     )
  v_matmul = np.matmul(v_dloss_ddepdt, v_tunnel_transpose)
  
  # 去掉 -2 维轴，再将 -1 维轴转置还原到原来位置
  v_matmul = np.moveaxis(np.squeeze(v_matmul, axis = -2), -1, v_tunnel_axis)
  
  return v_matmul.tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 2, 3, 1, 1])
--   , -3
--   ))
--   
-- 
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 2, 3, 6, 1])
--   , 2
--   ))
--   
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 1, 1, 2, 4])
--   , -1
--   ))

-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[1, 3, 2, 6, 4])
--   , 3
--   ))