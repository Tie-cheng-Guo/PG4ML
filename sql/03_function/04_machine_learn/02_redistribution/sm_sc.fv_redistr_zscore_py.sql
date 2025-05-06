-- drop function if exists sm_sc.fv_redistr_zscore_py(float[], int[]);
create or replace function sm_sc.fv_redistr_zscore_py
(
  i_array          float[],
  i_cnt_per_grp    int[]      default null
)
returns float[]
as
-- -- $$
-- -- begin 
-- --   return 
-- --     (
-- --       sm_sc.fv_aggr_slice_sum_py
-- --       (
-- --         (
-- --           i_array 
-- --           -` 
-- --           sm_sc.fv_repeat_axis_py
-- --           (
-- --             sm_sc.fv_aggr_slice_avg_py
-- --             (
-- --               i_array
-- --             , i_cnt_per_grp
-- --             )
-- --           , (select array_agg(a_no order by a_no) from generate_series(1, array_length(i_cnt_per_grp, 1)) tb_a(a_no))
-- --           , i_cnt_per_grp
-- --           )
-- --         )
-- --         ^` 2.0
-- --       , i_cnt_per_grp
-- --       )
-- --       /`
-- --       (sm_sc.fv_aggr_slice_prod_py(i_cnt_per_grp) - 1.0) :: float
-- --     )
-- --     ^` 0.5
-- --   ;
-- -- end
-- -- $$
-- -- language plpgsql stable
$$
  import numpy as np
  v_array = np.float32(i_array)
  
  if i_cnt_per_grp is None :
    return ((v_array - v_array.mean()) / v_array.std(ddof=1)).tolist()
  
  else :
    v_cnt_per_grp = np.array(i_cnt_per_grp)
    v_ele_len = v_array.dtype.itemsize
    if v_array.ndim == 1 :
      v_array_strided =  \
        np.lib.stride_tricks.as_strided(v_array \
            , shape = ((np.concatenate((np.array(v_array.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-1] * v_ele_len \
                , v_ele_len) \
          )
      return ((v_array_strided - v_array_strided.mean(axis = -1).reshape(v_array_strided.shape[0:1] + (1, ))) / \
        ((((v_array_strided - v_array_strided.mean(axis = -1).reshape(v_array_strided.shape[0:1] + (1, ))) ** 2.0)\
          .sum(axis = -1).reshape(v_array_strided.shape[0:1] + (1, )) \
          / (v_cnt_per_grp.prod() - 1)) ** 0.5)) \
        .reshape(v_array.shape) \
        .tolist()
      
    elif v_array.ndim == 2 :
      v_array_strided =  \
        np.lib.stride_tricks.as_strided(v_array \
            , shape = ((np.concatenate((np.array(v_array.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_array.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return ((v_array \
            - v_array_strided.mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:2]) \
              .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2)) / \
        ((((v_array_strided - v_array_strided.mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:2] + (1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).reshape(v_array_strided.shape[0:2]) \
          / (v_cnt_per_grp.prod() - 1)) ** 0.5) \
            .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2)) \
        .tolist()
        
    elif v_array.ndim == 3 :
      v_array_strided =  \
        np.lib.stride_tricks.as_strided(v_array \
            , shape = ((np.concatenate((np.array(v_array.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_array.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return ((v_array \
            - v_array_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:3]) \
              .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3)) / \
        ((((v_array_strided - v_array_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:3] + (1, 1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).sum(axis = -1).reshape(v_array_strided.shape[0:3]) \
          / (v_cnt_per_grp.prod() - 1)) ** 0.5) \
            .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3)) \
        .tolist()
        
    elif v_array.ndim == 4 :
      v_array_strided =  \
        np.lib.stride_tricks.as_strided(v_array \
            , shape = ((np.concatenate((np.array(v_array.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-4] * v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_array.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return ((v_array \
            - v_array_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:4]) \
              .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4)) / \
        ((((v_array_strided - v_array_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:4] + (1, 1, 1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).reshape(v_array_strided.shape[0:4]) \
          / (v_cnt_per_grp.prod() - 1)) ** 0.5) \
            .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4)) \
        .tolist()
        
    elif v_array.ndim == 5 :
      v_array_strided =  \
        np.lib.stride_tricks.as_strided(v_array \
            , shape = ((np.concatenate((np.array(v_array.shape) // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
            , strides = ( \
                  v_cnt_per_grp[-5] * v_array.shape[-4] * v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-4] * v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
                , v_cnt_per_grp[-1] * v_ele_len \
                , v_array.shape[-4] * v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
                , v_array.shape[-1] * v_ele_len \
                , v_ele_len) \
          )
      return ((v_array \
            - v_array_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:5]) \
              .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4).repeat(v_cnt_per_grp[-5], axis = -5)) / \
        ((((v_array_strided - v_array_strided.mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).mean(axis = -1).reshape(v_array_strided.shape[0:5] + (1, 1, 1, 1, 1, ))) ** 2.0) \
          .sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).sum(axis = -1).reshape(v_array_strided.shape[0:5]) \
          / (v_cnt_per_grp.prod() - 1)) ** 0.5) \
            .repeat(v_cnt_per_grp[-1], axis = -1).repeat(v_cnt_per_grp[-2], axis = -2).repeat(v_cnt_per_grp[-3], axis = -3).repeat(v_cnt_per_grp[-4], axis = -4).repeat(v_cnt_per_grp[-5], axis = -5)) \
        .tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_redistr_zscore_py
--   (
--     array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--     , array[3]
--   ) :: decimal[] ~=` 6
-- select 
--   sm_sc.fv_redistr_zscore_py
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6

-- select
--   sm_sc.fv_redistr_zscore_py
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15])
--   , array[2, 3, 3]
--   )

-- select
--   sm_sc.fv_redistr_zscore_py
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15, 8])
--   , array[2, 3, 3, 4]
--   )

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3,5*7]) as a_arr
-- )
-- select 
--   sm_sc.fv_redistr_zscore_py(a_arr, array[3,7]) :: decimal[] ~=` 3
-- = sm_sc.fv_redistr_zscore(a_arr, array[3,7]) :: decimal[] ~=` 3
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_arr
-- )
-- select 
--   sm_sc.fv_redistr_zscore_py(a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- = sm_sc.fv_redistr_zscore(a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_arr
-- )
-- select 
--   sm_sc.fv_redistr_zscore_py(a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- = sm_sc.fv_redistr_zscore(a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- from cte_arr