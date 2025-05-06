-- drop function if exists sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3_py(float[], int[]);
create or replace function sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3_py
(
  i_dloss_ddepdt              float[]
, i_tunnel_offset_length      int[]
)
returns float[]
as
$$
  import numpy as np
  v_dloss_ddepdt = np.float64(i_dloss_ddepdt)
  v_tunnel_offset_length = np.array(i_tunnel_offset_length)
  
  for v_cur in range(v_dloss_ddepdt.ndim) :
    if v_tunnel_offset_length[v_cur] == 1 and v_dloss_ddepdt.shape[v_cur] != 1:
      v_dloss_ddepdt = v_dloss_ddepdt.sum(axis = v_cur, keepdims=True)
  
  return v_dloss_ddepdt.tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , array[5, 3, 1, 4]
--   ))
--   
-- 
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , array[5, 3, 6, 1]
--   ))
--   
-- select array_dims(
--   sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3_py
--   (
--     sm_sc.fv_new_rand(array[5, 3, 6, 4])
--   , array[1, 3, 6, 4]
--   ))