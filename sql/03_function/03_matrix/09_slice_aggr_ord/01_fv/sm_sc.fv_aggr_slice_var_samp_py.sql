-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_var_samp_py(float[]);
create or replace function sm_sc.fv_aggr_slice_var_samp_py
(
  i_array          float[]
)
returns float
as
-- -- $$
-- -- begin 
-- --   return 
-- --     sm_sc.fv_aggr_slice_sum_py
-- --     (
-- --       (
-- --         i_array 
-- --         -` sm_sc.fv_aggr_slice_avg_py(i_array)
-- --       )
-- --       ^` 2.0
-- --     )
-- --     /
-- --     (cardinality(i_array) :: float - 1.0)
-- --   ;
-- -- end
-- -- $$
-- -- language plpgsql stable
$$
  import numpy as np
  return np.nanvar(np.float32(i_array), ddof=1).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]::float[]
--   );

-- select sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[1,2,3,4,5,6]::float[]
--   );

-- select sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[[[1,2,3,4,25,6],[-1,-2,-3,4,5,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,5,6]]]::float[]
--   );

-- select sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[[[[1,2,3,4,25,6],[-1,-2,-3,4,35,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,25,6]]],[[[1,12,3,4,25,6],[-1,-42,-3,4,5,6]],[[1,2,13,-4,-5,-36],[1,12,3,14,5,6]]]]::float[]
--   );

-- select sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[]::float[]
--   );

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_aggr_slice_var_samp_py(float[], int[]);
create or replace function sm_sc.fv_aggr_slice_var_samp_py
(
  i_array          float[],
  i_cnt_per_grp    int[]
)
returns float[]
as
-- -- $$
-- -- begin 
-- --   return 
-- --     sm_sc.fv_aggr_slice_sum_py
-- --     (
-- --       (
-- --         i_array 
-- --         -` 
-- --         sm_sc.fv_repeat_axis_py
-- --         (
-- --           sm_sc.fv_aggr_slice_avg_py
-- --           (
-- --             i_array
-- --           , i_cnt_per_grp
-- --           )
-- --         , (select array_agg(a_no order by a_no) from generate_series(1, array_length(i_cnt_per_grp, 1)) tb_a(a_no))
-- --         , i_cnt_per_grp
-- --         )
-- --       )
-- --       ^` 2.0
-- --     , i_cnt_per_grp
-- --     )
-- --     /`
-- --     (sm_sc.fv_aggr_slice_prod_py(i_cnt_per_grp) - 1.0) :: float
-- --   ;
-- -- end
-- -- $$
-- -- language plpgsql stable
$$
  import numpy as np
  v_array = np.float32(i_array)
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
    return \
      (np.nansum( \
        ((v_array_strided - \
          np.nanmean( \
            v_array_strided \
        , axis = -1) \
        .reshape(v_array_strided.shape[0:1] + (1, ))) ** 2.0)\
        , axis = -1) \
        .reshape(v_array_strided.shape[0:1] + (1, )) \
        / (v_cnt_per_grp.prod() - 1)) \
      .reshape(v_array.shape // v_cnt_per_grp) \
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
    return \
      (np.nansum(np.nansum( \
        ((v_array_strided - 
          np.nanmean(np.nanmean( \
            v_array_strided \
            , axis = -1), axis = -1) \
        .reshape(v_array_strided.shape[0:2] + (1, 1, ))) ** 2.0) \
        , axis = -1), axis = -1)\
        .reshape(v_array_strided.shape[0:2] + (1, 1, )) \
        / (v_cnt_per_grp.prod() - 1)) \
      .reshape(v_array.shape // v_cnt_per_grp) \
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
    return \
      (np.nansum(np.nansum(np.nansum( \
        ((v_array_strided - \
          np.nanmean(np.nanmean(np.nanmean( \
            v_array_strided \
            , axis = -1), axis = -1), axis = -1) \
          .reshape(v_array_strided.shape[0:3] + (1,  1,  1, ))) ** 2.0) \
      , axis = -1), axis = -1), axis = -1) \
        .reshape(v_array_strided.shape[0:3] + (1, 1, 1, )) \
        / (v_cnt_per_grp.prod() - 1)) \
      .reshape(v_array.shape // v_cnt_per_grp) \
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
    return \
        (np.nansum(np.nansum(np.nansum(np.nansum( \
          ((v_array_strided - \
            np.nanmean(np.nanmean(np.nanmean(np.nanmean( \
              v_array_strided \
            , axis = -1), axis = -1), axis = -1), axis = -1) \
          .reshape(v_array_strided.shape[0:4] + (1,  1,  1,  1, ))) ** 2.0) \
          , axis = -1), axis = -1), axis = -1), axis = -1) \
        .reshape(v_array_strided.shape[0:4] + (1, 1, 1, 1, )) \
        / (v_cnt_per_grp.prod() - 1)) \
      .reshape(v_array.shape // v_cnt_per_grp) \
      .tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--     , array[3]
--   ) :: decimal[] ~=` 6
-- select 
--   sm_sc.fv_aggr_slice_var_samp_py
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6

-- select
--   sm_sc.fv_aggr_slice_var_samp_py
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15])
--   , array[2, 3, 3]
--   )

-- select
--   sm_sc.fv_aggr_slice_var_samp_py
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
--   sm_sc.fv_aggr_slice_var_samp_py(a_arr, array[3,7]) :: decimal[] ~=` 3
-- = sm_sc.fv_aggr_slice_var_samp(a_arr, array[3,7]) :: decimal[] ~=` 3
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_var_samp_py(a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- = sm_sc.fv_aggr_slice_var_samp(a_arr, array[3,7,4]) :: decimal[] ~=` 3
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_var_samp_py(a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- = sm_sc.fv_aggr_slice_var_samp(a_arr, array[3,7,4,5]) :: decimal[] ~=` 3
-- from cte_arr