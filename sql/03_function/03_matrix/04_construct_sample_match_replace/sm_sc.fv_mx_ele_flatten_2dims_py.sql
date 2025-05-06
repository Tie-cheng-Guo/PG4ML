-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_mx_ele_flatten_2dims_py(float[], int[2], int);
create or replace function sm_sc.fv_mx_ele_flatten_2dims_py
(
  i_array_nd        float[]  
, i_dims_from_to    int[2]     -- 扁平化的维度的原来两个维度。扁平化后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
, i_dim_pin_ele     int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
)
returns float[]
as
$$
  import numpy as np
  v_dims_from_to = (np.int8(i_dims_from_to) -1).tolist()
  v_dim_pin_ele = i_dim_pin_ele - 1
  
  v_array_nd = np.array(i_array_nd)
  if v_array_nd.ndim == 2 :
    if v_dims_from_to == [0, 1] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 0).reshape(1, v_array_nd.shape[0] * v_array_nd.shape[1]).tolist()
      elif v_dim_pin_ele == 1 :
        return v_array_nd.reshape(1, v_array_nd.shape[0] * v_array_nd.shape[1]).tolist()
    elif v_dims_from_to == [1, 0] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 0).reshape(v_array_nd.shape[0] * v_array_nd.shape[1], 1).tolist()
      elif v_dim_pin_ele == 1 :
        return v_array_nd.reshape(v_array_nd.shape[0] * v_array_nd.shape[1], 1).tolist()
      
  elif v_array_nd.ndim == 3 :
    if v_dims_from_to == [0, 1] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(2, 1, 0).reshape(v_array_nd.shape[2], v_array_nd.shape[1] * v_array_nd.shape[0], 1).transpose(2, 1, 0).tolist()
      elif v_dim_pin_ele == 1 :
        return v_array_nd.transpose(2, 0, 1).reshape(v_array_nd.shape[2], 1, v_array_nd.shape[0] * v_array_nd.shape[1]).transpose(1, 2, 0).tolist()
      
    elif v_dims_from_to == [1, 0] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(2, 1, 0).reshape(v_array_nd.shape[2], 1, v_array_nd.shape[1] * v_array_nd.shape[0]).transpose(2, 1, 0).tolist()
      elif v_dim_pin_ele == 1 :
        return v_array_nd.transpose(2, 0, 1).reshape(v_array_nd.shape[2], v_array_nd.shape[0] * v_array_nd.shape[1], 1).transpose(1, 2, 0).tolist()
      
    elif v_dims_from_to == [0, 2] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 2, 0).reshape(v_array_nd.shape[1], v_array_nd.shape[2] * v_array_nd.shape[0], 1).transpose(2, 0, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.transpose(1, 0, 2).reshape(v_array_nd.shape[1], 1, v_array_nd.shape[0] * v_array_nd.shape[2]).transpose(1, 0, 2).tolist()
      
    elif v_dims_from_to == [2, 0] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 2, 0).reshape(v_array_nd.shape[1], 1, v_array_nd.shape[2] * v_array_nd.shape[0]).transpose(2, 0, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.transpose(1, 0, 2).reshape(v_array_nd.shape[1], v_array_nd.shape[0] * v_array_nd.shape[2], 1).transpose(1, 0, 2).tolist()
      
    elif v_dims_from_to == [1, 2] :
      if v_dim_pin_ele == 1 :
        return v_array_nd.transpose(0, 2, 1).reshape(v_array_nd.shape[0], v_array_nd.shape[2] * v_array_nd.shape[1], 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.reshape(v_array_nd.shape[0], 1, v_array_nd.shape[1] * v_array_nd.shape[2]).tolist()
      
    elif v_dims_from_to == [2, 1] :
      if v_dim_pin_ele == 1 :
        return v_array_nd.transpose(0, 2, 1).reshape(v_array_nd.shape[0], 1, v_array_nd.shape[2] * v_array_nd.shape[1]).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.reshape(v_array_nd.shape[0], v_array_nd.shape[1] * v_array_nd.shape[2], 1).tolist()
    
  elif v_array_nd.ndim == 4 :
    if v_dims_from_to == [0, 1] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(2, 3, 1, 0).reshape(v_array_nd.shape[2], v_array_nd.shape[3], v_array_nd.shape[1] * v_array_nd.shape[0], 1).transpose(3, 2, 0, 1).tolist()
      elif v_dim_pin_ele == 1 :
        return v_array_nd.transpose(2, 3, 0, 1).reshape(v_array_nd.shape[2], v_array_nd.shape[3], 1, v_array_nd.shape[0] * v_array_nd.shape[1]).transpose(2, 3, 0, 1).tolist()
      
    elif v_dims_from_to == [1, 0] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(2, 3, 1, 0).reshape(v_array_nd.shape[2], v_array_nd.shape[3], 1, v_array_nd.shape[1] * v_array_nd.shape[0]).transpose(3, 2, 0, 1).tolist()
      elif v_dim_pin_ele == 1 :
        return v_array_nd.transpose(2, 3, 0, 1).reshape(v_array_nd.shape[2], v_array_nd.shape[3], v_array_nd.shape[0] * v_array_nd.shape[1], 1).transpose(2, 3, 0, 1).tolist()
      
    elif v_dims_from_to == [0, 2] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 3, 2, 0).reshape(v_array_nd.shape[1], v_array_nd.shape[3], v_array_nd.shape[2] * v_array_nd.shape[0], 1).transpose(3, 0, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.transpose(1, 3, 0, 2).reshape(v_array_nd.shape[1], v_array_nd.shape[3], 1, v_array_nd.shape[0] * v_array_nd.shape[2]).transpose(2, 0, 3, 1).tolist()
      
    elif v_dims_from_to == [2, 0] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 3, 2, 0).reshape(v_array_nd.shape[1], v_array_nd.shape[3], 1, v_array_nd.shape[2] * v_array_nd.shape[0]).transpose(3, 0, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.transpose(1, 3, 0, 2).reshape(v_array_nd.shape[1], v_array_nd.shape[3], v_array_nd.shape[0] * v_array_nd.shape[2], 1).transpose(2, 0, 3, 1).tolist()
      
    elif v_dims_from_to == [0, 3] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 2, 3, 0).reshape(v_array_nd.shape[1], v_array_nd.shape[2], v_array_nd.shape[3] * v_array_nd.shape[0], 1).transpose(3, 0, 1, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_array_nd.transpose(1, 2, 0, 3).reshape(v_array_nd.shape[1], v_array_nd.shape[2], 1, v_array_nd.shape[0] * v_array_nd.shape[3]).transpose(2, 0, 1, 3).tolist()
      
    elif v_dims_from_to == [3, 0] :
      if v_dim_pin_ele == 0 :
        return v_array_nd.transpose(1, 2, 3, 0).reshape(v_array_nd.shape[1], v_array_nd.shape[2], 1, v_array_nd.shape[3] * v_array_nd.shape[0]).transpose(3, 0, 1, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_array_nd.transpose(1, 2, 0, 3).reshape(v_array_nd.shape[1], v_array_nd.shape[2], v_array_nd.shape[0] * v_array_nd.shape[3], 1).transpose(2, 0, 1, 3).tolist()
      
    elif v_dims_from_to == [1, 2] :
      if v_dim_pin_ele == 1 :
        return v_array_nd.transpose(0, 3, 2, 1).reshape(v_array_nd.shape[0], v_array_nd.shape[3], v_array_nd.shape[2] * v_array_nd.shape[1], 1).transpose(0, 3, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.transpose(0, 3, 1, 2).reshape(v_array_nd.shape[0], v_array_nd.shape[3], 1, v_array_nd.shape[1] * v_array_nd.shape[2]).transpose(0, 2, 3, 1).tolist()
      
    elif v_dims_from_to == [2, 1] :
      if v_dim_pin_ele == 1 :
        return v_array_nd.transpose(0, 3, 2, 1).reshape(v_array_nd.shape[0], v_array_nd.shape[3], 1, v_array_nd.shape[2] * v_array_nd.shape[1]).transpose(0, 3, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_array_nd.transpose(0, 3, 1, 2).reshape(v_array_nd.shape[0], v_array_nd.shape[3], v_array_nd.shape[2] * v_array_nd.shape[1], 1).transpose(0, 2, 3, 1).tolist()

    elif v_dims_from_to == [1, 3] :
      if v_dim_pin_ele == 1 :
        return v_array_nd.transpose(0, 2, 3, 1).reshape(v_array_nd.shape[0], v_array_nd.shape[2], v_array_nd.shape[3] * v_array_nd.shape[1], 1).transpose(0, 3, 1, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_array_nd.transpose(0, 2, 1, 3).reshape(v_array_nd.shape[0], v_array_nd.shape[2], 1, v_array_nd.shape[1] * v_array_nd.shape[3]).transpose(0, 2, 1, 3).tolist()
      
    elif v_dims_from_to == [3, 1] :
      if v_dim_pin_ele == 1 :
        return v_array_nd.transpose(0, 2, 3, 1).reshape(v_array_nd.shape[0], v_array_nd.shape[2], 1, v_array_nd.shape[3] * v_array_nd.shape[1]).transpose(0, 3, 1, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_array_nd.transpose(0, 2, 1, 3).reshape(v_array_nd.shape[0], v_array_nd.shape[2], v_array_nd.shape[1] * v_array_nd.shape[3], 1).transpose(0, 2, 1, 3).tolist()

    elif v_dims_from_to == [2, 3] :
      if v_dim_pin_ele == 2 :
        return v_array_nd.transpose(0, 1, 3, 2).reshape(v_array_nd.shape[0], v_array_nd.shape[1], 1, v_array_nd.shape[3] * v_array_nd.shape[2]).tolist()
      elif v_dim_pin_ele == 3 :
        return v_array_nd.reshape(v_array_nd.shape[0], v_array_nd.shape[1], 1, v_array_nd.shape[2] * v_array_nd.shape[3]).tolist()
      
    elif v_dims_from_to == [3, 2] :
      if v_dim_pin_ele == 2 :
        return v_array_nd.transpose(0, 1, 3, 2).reshape(v_array_nd.shape[0], v_array_nd.shape[1], 1, v_array_nd.shape[3] * v_array_nd.shape[2]).tolist()
      elif v_dim_pin_ele == 3 :
        return v_array_nd.reshape(v_array_nd.shape[0], v_array_nd.shape[1], v_array_nd.shape[2] * v_array_nd.shape[3], 1).tolist()

$$
language plpython3u stable
parallel safe
;

-- -- set search_path to sm_sc;
-- with cte_arr as
-- (
--   select 
--     array
--     [
--       [
--         [1, 2, 3, 4]
--       , [5, 6, 7, 8]
--       , [9, 10, 11, 12]
--       ]
--     , [
--         [21, 22, 23, 24]
--       , [25, 26, 27, 28]
--       , [29, 30, 31, 32]
--       ]
--     ]
--     as a_arr
-- )
-- select 
--   a_dims_from_to, a_dim_pin_ele,
--   sm_sc.fv_mx_ele_flatten_2dims_py(a_arr, a_dims_from_to, a_dim_pin_ele) as a_out
-- from cte_arr
--   , (
--                 select array[1, 2]  
--       union all select array[2, 3] 
--       union all select array[2, 1]  
--       union all select array[3, 2] 
--       union all select array[1, 3] 
--       union all select array[3, 1]
--     ) tb_a_dims_from_to(a_dims_from_to)
--   , generate_series(1, 3) tb_a_dim_pin_ele(a_dim_pin_ele)
-- where a_dim_pin_ele = any(a_dims_from_to)
-- order by least(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dims_from_to[1]
--   , greatest(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dim_pin_ele

-- select 
--   a_dim_from
-- , a_dim_to
-- , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx] as a_dim_pin_ele
-- , array_dims(
--   sm_sc.fv_mx_ele_flatten_2dims_py
--   (
--     a_arr
--   , array[a_dim_from, a_dim_to]
--   , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx]
--   )) as a_flattened_dims
-- , array_dims(a_arr) as a_arr_dims
-- from 
--   (
--               select sm_sc.fv_new_rand(array[4,3    ]) as a_arr
--     union all select sm_sc.fv_new_rand(array[4,3,5  ]) as a_arr
--     union all select sm_sc.fv_new_rand(array[4,3,5,7]) as a_arr
--   ) tb_a_arr(a_arr)
-- , generate_series(1, 4) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 4) tb_a_dim_to(a_dim_to)
-- , generate_series(1, 2) tb_a_dim_pin_ele_idx(a_dim_pin_ele_idx)
-- where a_dim_from <= array_ndims(a_arr)
--   and a_dim_to <= array_ndims(a_arr)
--   and a_dim_from <> a_dim_to
-- order by array_ndims(a_arr), a_dim_from, a_dim_to, a_dim_pin_ele_idx
