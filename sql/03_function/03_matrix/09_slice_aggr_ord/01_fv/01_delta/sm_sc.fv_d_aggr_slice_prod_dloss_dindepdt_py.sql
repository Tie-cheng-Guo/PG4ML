-- drop function if exists sm_sc.fv_d_aggr_slice_prod_dloss_dindepdt_py(float[], float[], float[]);
create or replace function sm_sc.fv_d_aggr_slice_prod_dloss_dindepdt_py
(
  i_indepdt        float[]
, i_depdt          float[]
, i_dloss_ddepdt   float[]
)
returns float[]
as
$$
  import numpy as np
  v_indepdt = np.float32(i_indepdt)
  v_depdt = np.float32(i_depdt)
  v_dloss_ddepdt = np.float32(i_dloss_ddepdt)
  v_cnt_per_grp = np.array(v_indepdt.shape) / np.array(v_depdt.shape)
  
  if v_dloss_ddepdt.ndim == 1 : 
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0)
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0)
  elif v_dloss_ddepdt.ndim == 2 :
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1)
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1)
  elif v_dloss_ddepdt.ndim == 3 :
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2)
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2)
  elif v_dloss_ddepdt.ndim == 4 :
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2).repeat(v_cnt_per_grp[3], axis = 3)
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2).repeat(v_cnt_per_grp[3], axis = 3)

  return (v_indepdt * v_dloss_ddepdt / v_depdt).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_aggr_slice_prod_dloss_dindepdt_py
--   (
--     sm_sc.fv_new_rand(array[2 * 3, 3 * 5, 2 * 5])
--   , sm_sc.fv_new_rand(array[3, 5, 2])
--   , sm_sc.fv_new_rand(array[3, 5, 2])
--   ) :: decimal[] ~=` 3