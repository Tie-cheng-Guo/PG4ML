-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_transpose_py(int[]);
create or replace function sm_sc.fv_opr_transpose_py
(
  i_right     int[]
)
returns int[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  else :
    return v_right.swapaxes(-1,-2).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_transpose_py(int[], int[]);
create or replace function sm_sc.fv_opr_transpose_py
(
  i_right     int[]
, i_dims      int[2]
)
returns int[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  else :
    return v_right.swapaxes(i_dims[0] - 1, i_dims[1] - 1).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_transpose_py(float[]);
create or replace function sm_sc.fv_opr_transpose_py
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
  else :
    return v_right.swapaxes(-1,-2).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_transpose_py(float[], int[]);
create or replace function sm_sc.fv_opr_transpose_py
(
  i_right     float[]
, i_dims      int[2]
)
returns float[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  else :
    return v_right.swapaxes(i_dims[0] - 1, i_dims[1] - 1).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_transpose_py(decimal[]);
create or replace function sm_sc.fv_opr_transpose_py
(
  i_right     decimal[]
)
returns decimal[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  else :
    return v_right.swapaxes(-1,-2).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_transpose_py(decimal[], int[]);
create or replace function sm_sc.fv_opr_transpose_py
(
  i_right     decimal[]
, i_dims      int[2]
)
returns decimal[]
as
$$
  from numpy import array
  v_right = array(i_right)
  if v_right.size == 0 :
    return v_right
  else :
    return v_right.swapaxes(i_dims[0] - 1, i_dims[1] - 1).tolist()
    
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_transpose_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_transpose_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6], array[1.2, 2.3]]
--   );
-- select sm_sc.fv_opr_transpose_py
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   );
-- select sm_sc.fv_opr_transpose_py
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   , array[1,2]
--   );
-- select sm_sc.fv_opr_transpose_py
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[1,2]
--   );