-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_concat_y(anyarray, anyarray);
create or replace function sm_sc.fv_opr_concat_y
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  -- 审计二维长度
  if array_length(i_left, 2) <> array_length(i_right, 2) 
    and array_length(i_left, 2) <> 1
    and array_length(i_right, 2) <> 1
  then
    raise exception 'unmatched length!';
  end if;


  if array_ndims(i_left) is null
  then 
    return i_right;
  elsif array_ndims(i_right) is null
  then
    return i_left;
  -- 同宽度 [][] ||| [][] 
  -- 或 纵向单行拼接 [] ||| [][] 
  --              或 [][] ||| []
  elsif array_length(i_left, 2) = array_length(i_right, 2)
    or array_ndims(i_left) = 1 and array_length(i_left, 1) = array_length(i_right, 2)
    or array_ndims(i_right) = 1 and array_length(i_right, 1) = array_length(i_left, 2)
  then
    return i_left || i_right;
  -- 横向广播，i_left 需要延拓 [][1] ||| [][]
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    return (select array_agg(array_fill(i_left[cur_sn][1], array[array_length(i_right, 2)]) order by cur_sn) from generate_series(1, array_length(i_left, 1)) cur_sn) || i_right;
  -- 横向广播，i_right 需要延拓 [][] ||| [][1]
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    return i_left || (select array_agg(array_fill(i_right[cur_sn][1], array[array_length(i_left, 2)]) order by cur_sn) from generate_series(1, array_length(i_right, 1)) cur_sn);
  elsif i_left is null
  then 
    return i_right;
  elsif i_right is null
  then 
    return i_left;
  -- 审计二维长度
  else
    return null; raise notice 'no method for such length!  L_Ndim: %; L_len_1: %; L_len_2: %; R_Ndim: %; R_len_1: %; R_len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2), array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_concat_y
--   (
--     array[array[12.3, 12.3], array[45.6, 45.6]],
--     array[array[-2.1, 1.6], array[-1.6, 2.1]]
--   );
-- select sm_sc.fv_opr_concat_y
--   (
--     array[array[32.5], array[9.1]],
--     array[array[2.3, 1.3], array[-5.6, 5.6]]
--   );
-- select sm_sc.fv_opr_concat_y
--   (
--     array[array[12.3, 2.3], array[45.6, 45.6]],
--     array[array[3.5], array[-4.0]]
--   );
-- select sm_sc.fv_opr_concat_y
--   (
--     array[32.5, 9.1],
--     array[array[2.3, 1.3], array[-5.6, 5.6]]
--   );
-- select sm_sc.fv_opr_concat_y
--   (
--     array[array[12.3, 12.3], array[45.6, 45.6]],
--     array[2.5, -1.1]
--   );
-- select sm_sc.fv_opr_x_concat
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_x_concat
--   (
--     array[]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_x_concat
--   (
--     array[array[], array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_x_concat
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[], array[]]::float[]
--   );
-- select sm_sc.fv_opr_x_concat
--   (
--     array[array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_x_concat
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[]]::float[]
--   );

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat_y(anyarray, anyelement);
create or replace function sm_sc.fv_opr_concat_y
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyarray
as
$$
-- declare 
begin
  if array_ndims(i_left) <> 2
  then
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2);
  end if;
  return i_left || array_fill(i_right, array[array_length(i_left, 2)]);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_concat_y(array[array[12.3, 25.1], array[2.56, 3.25]], 2.8)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat_y(anyelement, anyarray);
create or replace function sm_sc.fv_opr_concat_y
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  if array_ndims(i_right) <> 2
  then
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
  return array_fill(i_left, array[array_length(i_right, 2)]) || i_right;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_concat_y(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
