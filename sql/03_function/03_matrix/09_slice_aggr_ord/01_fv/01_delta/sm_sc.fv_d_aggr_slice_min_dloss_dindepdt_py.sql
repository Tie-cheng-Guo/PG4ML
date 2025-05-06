-- drop function if exists sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py(float[], float[], float[]);
create or replace function sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py
(
  i_indepdt        float[]
, i_depdt          float[]
, i_dloss_ddepdt   float[]
)
returns float[]
as
$$
  import numpy as np
  
  v_depdt = np.float32(i_depdt)
  v_indepdt = np.float32(i_indepdt)
  v_dloss_ddepdt = np.float32(i_dloss_ddepdt)
  v_cnt_per_grp = np.array(v_indepdt.shape) / np.array(v_depdt.shape)
  
  if v_depdt.ndim == 1 :
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0)
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0)
  elif v_depdt.ndim == 2 :
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1)
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1)
  elif v_depdt.ndim == 3 :
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2)
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2)
  elif v_depdt.ndim == 4 :
    v_depdt = v_depdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2).repeat(v_cnt_per_grp[3], axis = 3)
    v_dloss_ddepdt = v_dloss_ddepdt.repeat(v_cnt_per_grp[0], axis = 0).repeat(v_cnt_per_grp[1], axis = 1).repeat(v_cnt_per_grp[2], axis = 2).repeat(v_cnt_per_grp[3], axis = 3)
  
  return (np.float32(np.equal(v_depdt, v_indepdt)) * v_dloss_ddepdt).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py
--   (array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--   , array[8.2, 3.33]
--   , array[0.5, 1.9]
--   ) :: decimal[] ~=` 3

-- select 
--   sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--   ,  (sm_sc.fv_aggr_slice_min_py(
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ], array[2, 3]))
--     , sm_sc.fv_new_rand(array[2, 2])
--   ) :: decimal[] ~=` 6

-- with 
-- cte_arr as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[2 * 3, 5 * 7]) as a_indepdt
--   , sm_sc.fv_new_rand(array[2, 5]) as a_dlossddepdt
--   , array[3, 7] as a_cnt_per_grp
-- )
-- select 
--   sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_slice_min_py
--     (
--       a_indepdt
--     , a_cnt_per_grp
--     )
--   , a_dlossddepdt
--   )
-- = sm_sc.fv_d_aggr_slice_min_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_slice_min_py
--     (
--       a_indepdt
--     , a_cnt_per_grp
--     )
--   , a_dlossddepdt
--   , a_cnt_per_grp
--   )
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[2 * 3, 5 * 7, 2 * 7]) as a_indepdt
--   , sm_sc.fv_new_rand(array[2, 5, 7]) as a_dlossddepdt
--   , array[3, 7, 2] as a_cnt_per_grp
-- )
-- select 
--   sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_slice_min_py
--     (
--       a_indepdt
--     , a_cnt_per_grp
--     )
--   , a_dlossddepdt
--   )
-- = sm_sc.fv_d_aggr_slice_min_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_slice_min_py
--     (
--       a_indepdt
--     , a_cnt_per_grp
--     )
--   , a_dlossddepdt
--   , a_cnt_per_grp
--   )
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[2 * 3, 5 * 7, 2 * 7, 3 * 5]) as a_indepdt
--   , sm_sc.fv_new_rand(array[2, 5, 7, 3]) as a_dlossddepdt
--   , array[3, 7, 2, 5] as a_cnt_per_grp
-- )
-- select 
--   sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_slice_min_py
--     (
--       a_indepdt
--     , a_cnt_per_grp
--     )
--   , a_dlossddepdt
--   )
-- = sm_sc.fv_d_aggr_slice_min_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_slice_min_py
--     (
--       a_indepdt
--     , a_cnt_per_grp
--     )
--   , a_dlossddepdt
--   , a_cnt_per_grp
--   )
-- from cte_arr