-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_prod_py(float[]);
create or replace function sm_sc.fv_aggr_slice_prod_py
(
  i_array          float[]
)
returns float
as
$$
  import numpy as np
  return np.nanprod(np.float32(i_array)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_prod_py
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]::float[]
--   );

-- select sm_sc.fv_aggr_slice_prod_py
--   (
--     array[1,2,3,4,5,6]::float[]
--   );

-- select sm_sc.fv_aggr_slice_prod_py
--   (
--     array[[[1,2,3,4,25,6],[-1,-2,-3,4,5,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,5,6]]]::float[]
--   );

-- select sm_sc.fv_aggr_slice_prod_py
--   (
--     array[[[[1,2,3,4,25,6],[-1,-2,-3,4,35,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,25,6]]],[[[1,12,3,4,25,6],[-1,-42,-3,4,5,6]],[[1,2,13,-4,-5,-36],[1,12,3,14,5,6]]]]::float[]
--   );

-- select sm_sc.fv_aggr_slice_prod_py
--   (
--     array[]::float[]
--   );

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_aggr_slice_prod_py(float[], int[]);
create or replace function sm_sc.fv_aggr_slice_prod_py
(
  i_array          float[],
  i_cnt_per_grp    int[]
)
returns float[]
as
$$
  import numpy as np
  v_array = np.float32(i_array)
  v_cnt_per_grp = np.array(i_cnt_per_grp)
  v_ele_len = v_array.dtype.itemsize
  
  if v_array.ndim == 1 :
    return  \
      np.nanprod( \
      np.lib.stride_tricks.as_strided(v_array \
          , shape = ((np.concatenate((v_array.shape // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
          , strides = ( \
                v_cnt_per_grp[-1] * v_ele_len \
              , v_ele_len) \
        )  \
      , axis = -1) \
      .tolist()
  elif v_array.ndim == 2 :
    return \
      np.nanprod(np.nanprod( \
      np.lib.stride_tricks.as_strided(v_array \
          , shape = ((np.concatenate((v_array.shape // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
          , strides = ( \
                v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
              , v_cnt_per_grp[-1] * v_ele_len \
              , v_array.shape[-1] * v_ele_len \
              , v_ele_len) \
        )  \
      , axis = -1), axis = -1) \
      .tolist()
  elif v_array.ndim == 3 :
    return \
      np.nanprod(np.nanprod(np.nanprod( \
      np.lib.stride_tricks.as_strided(v_array \
          , shape = ((np.concatenate((v_array.shape // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
          , strides = ( \
                v_cnt_per_grp[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
              , v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
              , v_cnt_per_grp[-1] * v_ele_len \
              , v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
              , v_array.shape[-1] * v_ele_len \
              , v_ele_len) \
        )  \
      , axis = -1), axis = -1), axis = -1) \
      .tolist()
    
  elif v_array.ndim == 4 :
    return \
      np.nanprod(np.nanprod(np.nanprod(np.nanprod( \
      np.lib.stride_tricks.as_strided(v_array \
          , shape = ((np.concatenate((v_array.shape // v_cnt_per_grp, v_cnt_per_grp), axis = 0)).tolist()) \
          , strides = ( \
                v_cnt_per_grp[-4] * v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
              , v_cnt_per_grp[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
              , v_cnt_per_grp[-2] * v_array.shape[-1] * v_ele_len \
              , v_cnt_per_grp[-1] * v_ele_len \
              , v_array.shape[-3] * v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
              , v_array.shape[-2] * v_array.shape[-1] * v_ele_len \
              , v_array.shape[-1] * v_ele_len \
              , v_ele_len) \
        )  \
      , axis = -1), axis = -1), axis = -1), axis = -1) \
      .tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_aggr_slice_prod_py
--   (
--     array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--     , array[3]
--   ) :: decimal[] ~=` 6
-- select 
--   sm_sc.fv_aggr_slice_prod_py
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6

-- select
--   sm_sc.fv_aggr_slice_prod_py
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15])
--   , array[2, 3, 3]
--   )

-- select
--   sm_sc.fv_aggr_slice_prod_py
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
--   sm_sc.fv_aggr_slice_prod_py(a_arr, array[3,7])
-- = sm_sc.fv_aggr_slice_prod(a_arr, array[3,7])
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_prod_py(a_arr, array[3,7,1])
-- = sm_sc.fv_aggr_slice_prod(a_arr, array[3,7,1])
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_prod_py(a_arr, array[3,1,1,5])
-- = sm_sc.fv_aggr_slice_prod(a_arr, array[3,1,1,5])
-- from cte_arr