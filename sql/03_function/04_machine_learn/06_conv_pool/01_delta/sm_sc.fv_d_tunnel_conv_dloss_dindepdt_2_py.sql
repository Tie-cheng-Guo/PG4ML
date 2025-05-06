-- drop function if exists sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py(float[], float[], int[], int);
create or replace function sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
(
  i_dloss_ddepdt       float[]
, i_background         float[]
, i_tunnel_length      int[]
, i_tunnel_axis        int
)
returns float[]
as
$$
  import numpy as np
  v_dloss_ddepdt = np.float64(i_dloss_ddepdt)
  v_background = np.float64(i_background)
  v_tunnel_length = np.array(i_tunnel_length)
  v_dims = np.arange(0, v_tunnel_length.shape[0])
  
  if i_tunnel_axis > 0 :
    v_tunnel_axis = i_tunnel_axis - 1 - v_dloss_ddepdt.ndim
  elif i_tunnel_axis == 0 :
    v_tunnel_axis = - v_dloss_ddepdt.ndim
  else :
    v_tunnel_axis = i_tunnel_axis
    
  # 将 v_dloss_ddepdt, v_background 的 v_tunnel_axis 维轴换置到 -1 位置，再在 -2 位置增加一个维轴。当 v_tunnel_axis == -1，不必置换操作
  if v_tunnel_axis != -1 :
    v_dloss_ddepdt = np.moveaxis(v_dloss_ddepdt, v_tunnel_axis, -1)
    v_background = np.moveaxis(v_background, v_tunnel_axis, -1)
  v_dloss_ddepdt = np.expand_dims(v_dloss_ddepdt, axis = -2)
  v_background = np.expand_dims(v_background, axis = -1)
  
  v_matmul = np.matmul(v_background, v_dloss_ddepdt)
  
  if v_tunnel_axis != -1 :
    v_matmul = \
       np.transpose \
       ( \
         v_matmul \
       , axes = \
           tuple \
           ( \
             np.concatenate \
             ( \
               ( \
                 v_dims[ : v_tunnel_axis + v_matmul.ndim - 1] \
               , v_dims[v_matmul.ndim - 2 : v_matmul.ndim] \
               , v_dims[v_tunnel_axis + v_matmul.ndim - 1 : v_matmul.ndim - 2] \
               ) \
             , axis = 0 \
             ) \
           ) \
       )
  
  for v_cur in v_dims :
    if v_tunnel_length[v_cur] == 1 and v_matmul.shape[v_cur] != 1:
      v_matmul = v_matmul.sum(axis = v_cur, keepdims = True)
  
  return v_matmul.tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
--   (
--     sm_sc.fv_new_rand(array[2, 5, 6, 4])
--   , sm_sc.fv_new_rand(array[3, 5, 6, 4])
--   , array[3, 2, 1, 1, 1]
--   , -4
--   ))
--   
-- 
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 3, 2, 4])
--   , array[5, 1, 2, 6, 1]
--   , 3
--   ))
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 3, 2, 4])
--   , array[5, 3, 2, 6, 4]
--   , 3
--   ))
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 3, 2, 4])
--   , array[1, 3, 2, 6, 4]
--   , 3
--   ))
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , sm_sc.fv_new_rand(array[5, 3, 6, 2])
--   , array[5, 3, 1, 2, 4]
--   , -1
--   ))