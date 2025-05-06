-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_concat_py(float[], float[], int);
create or replace function sm_sc.fv_concat_py
(
  i_left      float[]
, i_right     float[]
, i_axis      int
)
returns float[]
as
$$
  import numpy as np
  # np.concatenate unsupport array_length(, ) == 0
  v_left = np.array(i_left)
  v_right = np.array(i_right)
  if v_left.size == 0 :
    return i_right
  elif v_right.size == 0 :
    return i_left
  else :
    return np.concatenate((v_left, v_right), axis = - max(v_left.ndim, v_right.ndim) + i_axis - 1).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_concat_py
--   (
--     array[[1, 2], [3, 4]]
--   , array[[1, 2], [3, 4]]
--   , 2
--   );
-- select sm_sc.fv_concat_py
--   (
--     array[1, 2, 3, 4]
--   , array[1, 2, 3, 4]
--   , 1
--   );
-- select sm_sc.fv_concat_py
--   (
--     array[[1, 2], [3, 4], [5, 6]]
--   , array[[1, 2], [3, 4], [5, 6]]
--   , 2
--   );
-- select sm_sc.fv_concat_py
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   , array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   , 0
--   );
-- select sm_sc.fv_concat_py
--   (
--     sm_sc.fv_new_rand(array[2,3,5,4,2])
--   , sm_sc.fv_new_rand(array[2,3,5,4,3])
--   , 1
--   );
-- -- select sm_sc.fv_concat_py
-- --   (
-- --     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
-- --   , array[[[[]]]] :: float[]
-- --   , 1
-- --   );