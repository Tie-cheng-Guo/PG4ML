-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_mirror_py(float[], int);
create or replace function sm_sc.fv_opr_mirror_py
(
  i_arr            float[],
  i_dim            int
)
returns float[]
as
$$
  from numpy import array
  if i_dim == 1:
    return array(i_arr)[::-1].tolist()
  if i_dim == 2:
    return array(i_arr)[::, ::-1].tolist()
  if i_dim == 3:
    return array(i_arr)[::, ::, ::-1].tolist()
  if i_dim == 4:
    return array(i_arr)[::, ::, ::, ::-1].tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mirror_py(decimal[], int);
create or replace function sm_sc.fv_opr_mirror_py
(
  i_arr            decimal[],
  i_dim            int
)
returns decimal[]
as
$$
  from numpy import array
  if i_dim == 1:
    return array(i_arr)[::-1].tolist()
  if i_dim == 2:
    return array(i_arr)[::, ::-1].tolist()
  if i_dim == 3:
    return array(i_arr)[::, ::, ::-1].tolist()
  if i_dim == 4:
    return array(i_arr)[::, ::, ::, ::-1].tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_opr_mirror_py
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , 3
--   );