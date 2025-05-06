-- drop function if exists sm_sc.fv_d_redistr_zscore_py(float[], int[]);
create or replace function sm_sc.fv_d_redistr_zscore_py
(
  i_depdt_var                  float[]                                     -- zscore 输出
-- , i_dloss_ddepdt               float[]                                      -- 此入参传入 dloss/dindepdt, 用于 zscore 直接求取 dloss/ddepdt
, i_indepdt_var                float[]                                     -- zscore 算子的输入，来自上一层算子的输出
, i_cnt_per_grp                int[]            default null
)
returns float[]
as
$$
  import numpy as np
  v_depdt_var = np.float32(i_depdt_var)
  v_indepdt_var = np.float32(i_indepdt_var)
  
  if i_cnt_per_grp is None :
    v_size = v_indepdt_var.size
    return (((((- v_depdt_var.sum()) * v_depdt_var) + ((v_size ** 2.0) - v_size - 1)) / (v_indepdt_var.std(ddof=1) * v_size)) + v_depdt_var).tolist()
  
  else :
    v_cnt_per_grp = np.array(i_cnt_per_grp)
    v_ele_len = v_indepdt_var.dtype.itemsize
    v_size = v_cnt_per_grp.prod()
    if v_indepdt_var.ndim == 1 :
      v_depdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_depdt_var \
            , shape = ((np.concatenate((np.array(v_depdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_indepdt_var \
            , shape = ((np.concatenate((np.array(v_indepdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-1] * v_ele_len \
                , v_ele_len) \
          )
      return (((((- \
                   v_depdt_var_strided.sum(axis = -1).reshape(v_depdt_var_strided.shape[0:1] + (1, )) \
                 ) * v_depdt_var_strided) + ((v_size ** 2.0) - v_size - 1)) / \
                 ( \
                   v_indepdt_var_strided.std(ddof=1, axis = -1).reshape(v_indepdt_var_strided.shape[0:1] + (1, )) \
                   * v_size \
                 )) + v_depdt_var_strided) \
                 .reshape(v_indepdt_var.shape) \
                 .tolist()
      
    elif v_indepdt_var.ndim == 2 :
      v_depdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_depdt_var \
            , shape = ((np.concatenate((np.array(v_depdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_depdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_indepdt_var \
            , shape = ((np.concatenate((np.array(v_indepdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_indepdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_std_samp = \
        ((((v_indepdt_var_strided - v_indepdt_var_strided.mean(axis = -1).mean(axis = -1).reshape(v_depdt_var_strided.shape[0:2] + (1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1) \
        / (v_size - 1)) \
        ** 0.5) \
        .reshape(v_depdt_var_strided.shape[0:2])
      return (((((- \
                   v_depdt_var_strided.sum(axis = -1).sum(axis = -1).reshape(v_depdt_var_strided.shape[0:2]) \
                     .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2) \
                 ) * v_depdt_var) + ((v_size ** 2.0) - v_size - 1)) / \
                 ( \
                   (v_indepdt_var_std_samp * v_size)\
                   .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2) \
                 )) + v_depdt_var).tolist()
        
    elif v_indepdt_var.ndim == 3 :
      v_depdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_depdt_var \
            , shape = ((np.concatenate((np.array(v_depdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_depdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_indepdt_var \
            , shape = ((np.concatenate((np.array(v_indepdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_indepdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_std_samp = \
        ((((v_indepdt_var_strided - v_indepdt_var_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_depdt_var_strided.shape[0:3] + (1, 1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).sum(axis = -1) \
        / (v_size - 1)) \
        ** 0.5) \
        .reshape(v_depdt_var_strided.shape[0:3])
      return (((((- \
                   v_depdt_var_strided.sum(axis = -1).sum(axis = -1).sum(axis = -1).reshape(v_depdt_var_strided.shape[0:3]) \
                     .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3) \
                 ) * v_depdt_var) + ((v_size ** 2.0) - v_size - 1)) / \
                 ( \
                   (v_indepdt_var_std_samp * v_size)\
                   .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3) \
                 )) + v_depdt_var).tolist()
        
    elif v_indepdt_var.ndim == 4 :
      v_depdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_depdt_var \
            , shape = ((np.concatenate((np.array(v_depdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-4] * v_depdt_var.shape[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_depdt_var.shape[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_depdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_indepdt_var \
            , shape = ((np.concatenate((np.array(v_indepdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-4] * v_indepdt_var.shape[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_indepdt_var.shape[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_indepdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_std_samp = \
        ((((v_indepdt_var_strided - v_indepdt_var_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_depdt_var_strided.shape[0:4] + (1, 1, 1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1) \
        / (v_size - 1)) \
        ** 0.5) \
        .reshape(v_depdt_var_strided.shape[0:4])
      return (((((- \
                   v_depdt_var_strided.sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).reshape(v_depdt_var_strided.shape[0:4]) \
                     .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4) \
                 ) * v_depdt_var) + ((v_size ** 2.0) - v_size - 1)) / \
                 ( \
                   (v_indepdt_var_std_samp * v_size)\
                   .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4) \
                 )) + v_depdt_var).tolist()
        
    elif v_indepdt_var.ndim == 5 :
      v_depdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_depdt_var \
            , shape = ((np.concatenate((np.array(v_depdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-5] * v_depdt_var.shape[-4] * v_depdt_var.shape[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-4] * v_depdt_var.shape[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_depdt_var.shape[-4] * v_depdt_var.shape[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_depdt_var.shape[-3] * v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_depdt_var.shape[-2] * v_depdt_var.shape[-1] * v_ele_len \
                , v_depdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_strided =  \
        np.lib.stride_tricks.as_strided(v_indepdt_var \
            , shape = ((np.concatenate((np.array(v_indepdt_var.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-5] * v_indepdt_var.shape[-4] * v_indepdt_var.shape[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-4] * v_indepdt_var.shape[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_indepdt_var.shape[-4] * v_indepdt_var.shape[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_indepdt_var.shape[-3] * v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_indepdt_var.shape[-2] * v_indepdt_var.shape[-1] * v_ele_len \
                , v_indepdt_var.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      v_indepdt_var_std_samp = \
        ((((v_indepdt_var_strided - v_indepdt_var_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_depdt_var_strided.shape[0:5] + (1, 1, 1, 1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1) \
        / (v_size - 1)) \
        ** 0.5) \
        .reshape(v_depdt_var_strided.shape[0:5])
      return (((((- \
                   v_depdt_var_strided.sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).reshape(v_depdt_var_strided.shape[0:5]) \
                     .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4).repeat(v_cnt_per_grp[-5], axis = -5) \
                 ) * v_depdt_var) + ((v_size ** 2.0) - v_size - 1)) / \
                 ( \
                   (v_indepdt_var_std_samp * v_size)\
                   .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4).repeat(v_cnt_per_grp[-5], axis = -5) \
                 )) + v_depdt_var).tolist()

$$
language plpython3u stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_d_redistr_zscore_py
--   (
--     sm_sc.fv_redistr_zscore_py(array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9], array[3])
--   , array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--   , array[3]
--   ) :: decimal[] ~=` 6

-- select 
--   sm_sc.fv_d_redistr_zscore_py
--   (
--     sm_sc.fv_redistr_zscore_py(
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ], array[2, 3])
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
--   select sm_sc.fv_new_rand(array[2*3,5*7]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_zscore_py(a_arr, array[3,7]) as a_depdt
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_zscore_py(a_depdt, a_arr, array[3,7]) :: decimal[] ~=` 3
-- = sm_sc.fv_d_redistr_zscore(a_depdt, a_arr, array[3,7]) :: decimal[] ~=` 3
-- from cte_arr, cte_depdt

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_zscore_py(a_arr, array[3,7,4]) as a_depdt
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_zscore_py(a_depdt, a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- = sm_sc.fv_d_redistr_zscore(a_depdt, a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- from cte_arr, cte_depdt

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_arr
-- ),
-- cte_depdt as 
-- (
--   select sm_sc.fv_redistr_zscore_py(a_arr, array[3,7,4,5]) as a_depdt
--   from cte_arr
-- )
-- select 
--   sm_sc.fv_d_redistr_zscore_py(a_depdt, a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- = sm_sc.fv_d_redistr_zscore(a_depdt, a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- from cte_arr, cte_depdt