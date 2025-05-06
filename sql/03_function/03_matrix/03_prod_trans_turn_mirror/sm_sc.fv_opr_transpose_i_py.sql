-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_transpose_i_py(float[]);
create or replace function sm_sc.fv_opr_transpose_i_py
(
  i_right     float[]
)
returns float[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  elif v_right.ndim == 2 :
    return (v_right[::, ::-1].swapaxes(-1,-2))[::, ::-1].tolist()
  elif v_right.ndim == 3 :
    return (v_right[::, ::, ::-1].swapaxes(-1,-2))[::, ::, ::-1].tolist()
  elif v_right.ndim == 4 :
    return (v_right[::, ::, ::-1].swapaxes(-1,-2))[::, ::, ::-1].tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_transpose_i_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_transpose_i_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6], array[1.2, 2.3]]
--   );
-- select sm_sc.fv_opr_transpose_i_py
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   );
-- select sm_sc.fv_opr_transpose_i_py
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   );