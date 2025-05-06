-- drop function if exists sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(float[], float[], float[], int[]);
create or replace function sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py
(
  i_depdt                  float[]                                      -- softmax 输出
, i_dloss_ddepdt           float[]                                      -- 此入参传入 dloss/dindepdt, 用于 softmax 直接求取 dloss/ddepdt
, i_indepdt                float[]      default null                    -- softmax 算子的输入，来自上一层算子的输出
, i_cnt_per_grp            int[]        default null
)
returns float[]
as
$$
  import numpy as np
  v_depdt = np.float32(i_depdt)
  v_dloss_ddepdt = np.float32(i_dloss_ddepdt)
  v_indepdt = np.float32(i_indepdt)
  v_mul = v_depdt * v_dloss_ddepdt
  
  if i_cnt_per_grp is None :
    return (v_depdt * (v_dloss_ddepdt - (v_mul.sum()))).tolist()
  
  else :
    v_cnt_per_grp = np.array(i_cnt_per_grp)
    v_ele_len = v_indepdt.dtype.itemsize
    if v_indepdt.ndim == 1 :
      v_mul_strided =  \
        np.lib.stride_tricks.as_strided(v_mul \
            , shape = ((np.concatenate((np.array(v_mul.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-1] * v_ele_len \
                , v_ele_len) \
          )
      return (v_depdt * (v_dloss_ddepdt -  \
        (v_mul_strided.sum(axis = -1).repeat(v_cnt_per_grp[-1], axis = -1)))) \
        .tolist()
      
    elif v_indepdt.ndim == 2 :
      v_mul_strided =  \
        np.lib.stride_tricks.as_strided(v_mul \
            , shape = ((np.concatenate((np.array(v_mul.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_mul.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return (v_depdt * (v_dloss_ddepdt -  \
        (v_mul_strided.sum(axis = -1).sum(axis = -1).repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2)))) \
        .tolist()
        
    elif v_indepdt.ndim == 3 :
      v_mul_strided =  \
        np.lib.stride_tricks.as_strided(v_mul \
            , shape = ((np.concatenate((np.array(v_mul.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_mul.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return (v_depdt * (v_dloss_ddepdt -  \
        (v_mul_strided.sum(axis = -1).sum(axis = -1).sum(axis = -1).repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3)))) \
        .tolist()
        
    elif v_indepdt.ndim == 4 :
      v_mul_strided =  \
        np.lib.stride_tricks.as_strided(v_mul \
            , shape = ((np.concatenate((np.array(v_mul.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-4] * v_mul.shape[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_mul.shape[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_mul.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return (v_depdt * (v_dloss_ddepdt -  \
        (v_mul_strided.sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4)))) \
        .tolist()
        
    elif v_indepdt.ndim == 5 :
      v_mul_strided =  \
        np.lib.stride_tricks.as_strided(v_mul \
            , shape = ((np.concatenate((np.array(v_mul.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-5] * v_mul.shape[-4] * v_mul.shape[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-4] * v_mul.shape[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_mul.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_mul.shape[-4] * v_mul.shape[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_mul.shape[-3] * v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_mul.shape[-2] * v_mul.shape[-1] * v_ele_len \
                , v_mul.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return (v_depdt * (v_dloss_ddepdt -  \
        (v_mul_strided.sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4).repeat(v_cnt_per_grp[-5], axis = -5)))) \
        .tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py
--   (
--     sm_sc.fv_redistr_softmax_py(array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9], array[3])
--   , sm_sc.fv_new_rand(array[6])
--   , array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--   , array[3]
--   ) :: decimal[] ~=` 6

-- select 
--   sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py
--   (
--     sm_sc.fv_redistr_softmax_py(
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ], array[2, 3])
--   , sm_sc.fv_new_rand(array[4, 6])
--   , array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[5*7]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_softmax_py(a_arr, array[7]) as a_depdt
--   , sm_sc.fv_new_rand(array[5*7]) as a_dldd
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(a_depdt, a_dldd, a_arr, array[7]) :: decimal[] ~=` 2
-- = sm_sc.fv_d_redistr_softmax_dloss_dindepdt(a_depdt, a_dldd, a_arr, array[7]) :: decimal[] ~=` 2
-- from cte_arr, cte_depdt


-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3,5*7]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_softmax_py(a_arr, array[3,7]) as a_depdt
--   , sm_sc.fv_new_rand(array[2*3,5*7]) as a_dldd
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(a_depdt, a_dldd, a_arr, array[3,7]) :: decimal[] ~=` 3
-- = sm_sc.fv_d_redistr_softmax_dloss_dindepdt(a_depdt, a_dldd, a_arr, array[3,7]) :: decimal[] ~=` 3
-- from cte_arr, cte_depdt

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_softmax_py(a_arr, array[3,7,4]) as a_depdt
--   , sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_dldd
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(a_depdt, a_dldd, a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- = sm_sc.fv_d_redistr_softmax_dloss_dindepdt(a_depdt, a_dldd, a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- from cte_arr, cte_depdt

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_softmax_py(a_arr, array[3,7,4,5]) as a_depdt
--   , sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_dldd
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(a_depdt, a_dldd, a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- = sm_sc.fv_d_redistr_softmax_dloss_dindepdt(a_depdt, a_dldd, a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- from cte_arr, cte_depdt