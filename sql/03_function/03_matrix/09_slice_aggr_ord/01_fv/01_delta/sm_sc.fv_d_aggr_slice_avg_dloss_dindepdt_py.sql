-- drop function if exists sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py(int[], float[]);
create or replace function sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py
(
  i_indepdt_len    int[]
, i_dloss_ddepdt   float[]
)
returns float[]
as
$$
  import numpy as np
  v_dloss_ddepdt = np.float32(i_dloss_ddepdt)
  v_cnt_per_grp = np.array(i_indepdt_len) / np.array(v_dloss_ddepdt.shape)
  v_dloss_ddepdt_scaled = v_dloss_ddepdt / (v_cnt_per_grp.prod())
  
  if v_dloss_ddepdt.ndim == 1 : 
    return v_dloss_ddepdt_scaled.repeat(v_cnt_per_grp[0], axis = 0).tolist()
  elif v_dloss_ddepdt.ndim == 2 :
    return v_dloss_ddepdt_scaled.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).tolist()
  elif v_dloss_ddepdt.ndim == 3 :
    return v_dloss_ddepdt_scaled.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2).tolist()
  elif v_dloss_ddepdt.ndim == 4 :
    return v_dloss_ddepdt_scaled.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2).repeat(v_cnt_per_grp[3], axis = 3).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py
--   (
--     array[6]
--   , array[2.3, 5.1]
--   ) :: decimal[] ~=` 3