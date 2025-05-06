-- drop function if exists sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt_py(float[], int[2], int, int[]);
create or replace function sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt_py
(
  i_dloss_ddepdt_nd        float[]  
, i_dims_from_to           int[2]     -- 扁平化的维度的原来两个维度。扁平化后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
, i_dim_pin_ele            int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
, i_indepdt_len            int[]
)
returns float[]
as
$$
  import numpy as np
  v_dims_from_to = np.int8(i_dims_from_to) -1
  v_dims_from_to.sort()
  v_dim_pin_ele = i_dim_pin_ele - 1
  v_indepdt_len = np.int8(i_indepdt_len).tolist()
  v_dloss_ddepdt_nd = np.array(i_dloss_ddepdt_nd)
  
  if v_dloss_ddepdt_nd.ndim == 2 :
    if v_dim_pin_ele == 0 :
      return v_dloss_ddepdt_nd.reshape(v_indepdt_len[1], v_indepdt_len[0]).transpose(1, 0).tolist()
    elif v_dim_pin_ele == 1 :
      return v_dloss_ddepdt_nd.reshape(v_indepdt_len[0], v_indepdt_len[1]).tolist()
      
  elif v_dloss_ddepdt_nd.ndim == 3 :
    if np.array_equal(v_dims_from_to, np.array([0, 1])) :
      if v_dim_pin_ele == 0 :
        return v_dloss_ddepdt_nd.transpose(2, 1, 0).reshape(v_indepdt_len[2], v_indepdt_len[1], v_indepdt_len[0]).transpose(2, 1, 0).tolist()
      elif v_dim_pin_ele == 1 :
        return v_dloss_ddepdt_nd.transpose(2, 0, 1).reshape(v_indepdt_len[2], v_indepdt_len[0], v_indepdt_len[1]).transpose(1, 2, 0).tolist()
      
    elif np.array_equal(v_dims_from_to, np.array([0, 2])) :
      if v_dim_pin_ele == 0 :
        return v_dloss_ddepdt_nd.transpose(1, 2, 0).reshape(v_indepdt_len[1], v_indepdt_len[2], v_indepdt_len[0]).transpose(2, 0, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_dloss_ddepdt_nd.transpose(1, 0, 2).reshape(v_indepdt_len[1], v_indepdt_len[0], v_indepdt_len[2]).transpose(1, 0, 2).tolist()
      
    elif np.array_equal(v_dims_from_to, np.array([1, 2])) :
      if v_dim_pin_ele == 1 :
        return v_dloss_ddepdt_nd.reshape(v_indepdt_len[0], v_indepdt_len[2], v_indepdt_len[1]).transpose(0, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_dloss_ddepdt_nd.reshape(v_indepdt_len[0], v_indepdt_len[1], v_indepdt_len[2]).tolist()
    
  elif v_dloss_ddepdt_nd.ndim == 4 :
    if np.array_equal(v_dims_from_to, np.array([0, 1])) :
      if v_dim_pin_ele == 0 :
        return v_dloss_ddepdt_nd.transpose(2, 3, 1, 0).reshape(v_indepdt_len[2], v_indepdt_len[3], v_indepdt_len[1], v_indepdt_len[0]).transpose(3, 2, 0, 1).tolist()
      elif v_dim_pin_ele == 1 :
        return v_dloss_ddepdt_nd.transpose(2, 3, 0, 1).reshape(v_indepdt_len[2], v_indepdt_len[3], v_indepdt_len[0], v_indepdt_len[1]).transpose(2, 3, 0, 1).tolist()
      
    elif np.array_equal(v_dims_from_to, np.array([0, 2])) :
      if v_dim_pin_ele == 0 :
        return v_dloss_ddepdt_nd.transpose(1, 3, 2, 0).reshape(v_indepdt_len[1], v_indepdt_len[3], v_indepdt_len[2], v_indepdt_len[0]).transpose(3, 0, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_dloss_ddepdt_nd.transpose(1, 3, 0, 2).reshape(v_indepdt_len[1], v_indepdt_len[3], v_indepdt_len[0], v_indepdt_len[2]).transpose(2, 0, 3, 1).tolist()
      
    elif np.array_equal(v_dims_from_to, np.array([0, 3])) :
      if v_dim_pin_ele == 0 :
        return v_dloss_ddepdt_nd.transpose(1, 2, 3, 0).reshape(v_indepdt_len[1], v_indepdt_len[2], v_indepdt_len[3], v_indepdt_len[0]).transpose(3, 0, 1, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_dloss_ddepdt_nd.transpose(1, 2, 0, 3).reshape(v_indepdt_len[1], v_indepdt_len[2], v_indepdt_len[0], v_indepdt_len[3]).transpose(2, 0, 1, 3).tolist()
      
    elif np.array_equal(v_dims_from_to, np.array([1, 2])) :
      if v_dim_pin_ele == 1 :
        return v_dloss_ddepdt_nd.transpose(0, 3, 2, 1).reshape(v_indepdt_len[0], v_indepdt_len[3], v_indepdt_len[2], v_indepdt_len[1]).transpose(0, 3, 2, 1).tolist()
      elif v_dim_pin_ele == 2 :
        return v_dloss_ddepdt_nd.transpose(0, 3, 1, 2).reshape(v_indepdt_len[0], v_indepdt_len[3], v_indepdt_len[1], v_indepdt_len[2]).transpose(0, 2, 3, 1).tolist()

    elif np.array_equal(v_dims_from_to, np.array([1, 3])) :
      if v_dim_pin_ele == 1 :
        return v_dloss_ddepdt_nd.transpose(0, 2, 3, 1).reshape(v_indepdt_len[0], v_indepdt_len[2], v_indepdt_len[3], v_indepdt_len[1]).transpose(0, 3, 1, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_dloss_ddepdt_nd.transpose(0, 2, 1, 3).reshape(v_indepdt_len[0], v_indepdt_len[2], v_indepdt_len[1], v_indepdt_len[3]).transpose(0, 2, 1, 3).tolist()

    elif np.array_equal(v_dims_from_to, np.array([2, 3])) :
      if v_dim_pin_ele == 2 :
        return v_dloss_ddepdt_nd.reshape(v_indepdt_len[0], v_indepdt_len[1], v_indepdt_len[3], v_indepdt_len[2]).transpose(0, 1, 3, 2).tolist()
      elif v_dim_pin_ele == 3 :
        return v_dloss_ddepdt_nd.reshape(v_indepdt_len[0], v_indepdt_len[1], v_indepdt_len[2], v_indepdt_len[3]).tolist()
        
$$
language plpython3u stable
parallel safe
;

-- with 
-- cte_mx_ele_flatten_2dims as 
-- (
--   select 
--     a_arr
--   , a_dim_from
--   , a_dim_to
--   , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx] as a_dim_pin_ele
--   , sm_sc.fv_mx_ele_flatten_2dims
--     (
--       a_arr
--     , array[a_dim_from, a_dim_to]
--     , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx]
--     ) as a_flattened_dims
--   from 
--     (
--                 select sm_sc.fv_new_rand(array[4,3    ]) as a_arr
--       union all select sm_sc.fv_new_rand(array[4,3,5  ]) as a_arr
--       union all select sm_sc.fv_new_rand(array[4,3,5,7]) as a_arr
--     ) tb_a_arr(a_arr)
--   , generate_series(1, 4) tb_a_dim_from(a_dim_from)
--   , generate_series(1, 4) tb_a_dim_to(a_dim_to)
--   , generate_series(1, 2) tb_a_dim_pin_ele_idx(a_dim_pin_ele_idx)
--   where a_dim_from <= array_ndims(a_arr)
--     and a_dim_to <= array_ndims(a_arr)
--     and a_dim_from <> a_dim_to
--   order by array_ndims(a_arr), a_dim_from, a_dim_to, a_dim_pin_ele_idx
-- )
-- select 
--   sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt_py
--   (
--     a_flattened_dims
--   , array[a_dim_from, a_dim_to]
--   , a_dim_pin_ele
--   , (select array_agg(array_length(a_arr, a_no) order by a_no) from generate_series(1, array_ndims(a_arr)) tb_a_no(a_no))
--   ) = a_arr
-- from cte_mx_ele_flatten_2dims