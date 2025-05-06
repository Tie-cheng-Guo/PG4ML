-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_transpose_nd_py(float[], int[]);
create or replace function sm_sc.fv_opr_transpose_nd_py
(
  i_right     float[]
, i_dims      int[]
)
returns float[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  else :
    return v_right.transpose(array(i_dims) - 1).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_transpose_nd_py
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4],
--         [5, 6, 7, 8],
--         [9, 10, 11, 12]
--       ],
--       [
--         [21, 22, 23, 24],
--         [25, 26, 27, 28],
--         [29, 30, 31, 32]
--       ]
--     ]
--     , array[2, 1, 3]
--   );
-- select sm_sc.fv_opr_transpose_nd_py
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4],
--         [5, 6, 7, 8],
--         [9, 10, 11, 12]
--       ],
--       [
--         [21, 22, 23, 24],
--         [25, 26, 27, 28],
--         [29, 30, 31, 32]
--       ]
--     ]
--     , array[1, 3, 2]
--   );
-- select sm_sc.fv_opr_transpose_nd_py
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4],
--         [5, 6, 7, 8],
--         [9, 10, 11, 12]
--       ],
--       [
--         [21, 22, 23, 24],
--         [25, 26, 27, 28],
--         [29, 30, 31, 32]
--       ]
--     ]
--     , array[2, 3, 1]
--   );
-- select sm_sc.fv_opr_transpose_nd_py
--   (
--     sm_sc.fv_new_rand(array[2,3,4,5])
--   , array[1,2,3,4]
--   );
-- select sm_sc.fv_opr_transpose_nd_py
--   (
--     sm_sc.fv_new_rand(array[2,3,4,5])
--   , array[1,2,4,3]
--   );
-- select sm_sc.fv_opr_transpose_nd_py
--   (
--     sm_sc.fv_new_rand(array[2,3,4,5])
--   , array[4,3,2,1]
--   );