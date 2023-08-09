-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_concat_x(anyarray, anyarray);
create or replace function sm_sc.fv_opr_concat_x
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
  if array_length(i_left, 1) <> array_length(i_right, 1)
      and array_length(i_left, 1) <> 1
      and array_length(i_right, 1) <> 1
      and array_ndims(i_left) > 1
      and array_ndims(i_right) > 1
    or array_ndims(i_left) = 1 and array_ndims(i_right) = 1
  then
    -- raise warning 'unmatched length!';
    return null;   -- -- -- 优化器跳入 bug，先妥协正常返回
    -- raise exception 'unmatched length!';     
  end if;

  if array_ndims(i_left) is null
  then 
    return i_right;
  elsif array_ndims(i_right) is null
  then
    return i_left;
  -- 同高度 [][] ||| [][] 
  elsif array_ndims(i_left) = 2 and array_ndims(i_right) = 2
  then
    if array_length(i_left, 1) = array_length(i_right, 1)
    then
      return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
    elsif array_length(i_left, 1) = 1
    then
      return (select array_agg(array(select unnest(i_left[1:1][:])) || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_right, 1)) tb_a_cur(a_cur));
    elsif array_length(i_right, 1) = 1
    then
      return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || array(select unnest(i_right[1:1][:])) order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
    end if;
  elsif array_ndims(i_left) = 1
  then
    return (select array_agg(i_left || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_right, 1)) tb_a_cur(a_cur));
  elsif array_ndims(i_right) = 1
  then
    return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || i_right order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
  elsif i_left is null
  then
    return i_right;
  elsif i_right is null
  then
    return i_left;
  else
    return null; raise notice 'no method for such length!  L_Ndim: %; L_len_1: %; L_len_2: %; R_Ndim: %; R_len_1: %; R_len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2), array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3, 55.5, -6.66]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[-12.3, 12.3, 55.5, -6.66]],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[-12.3, 12.3, 55.5, -6.66]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[-12.3, 12.3, 55.5, -6.66],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[], array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[], array[]]::float[]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[]]::float[]
--   );
-- --------------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat_x(anyarray, anyelement);
create or replace function sm_sc.fv_opr_concat_x
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
  return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || i_right order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_concat_x(array[array[12.3, 25.1], array[2.56, 3.25]], 2.8)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat_x(anyelement, anyarray);
create or replace function sm_sc.fv_opr_concat_x
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
  return (select array_agg(i_left || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_right, 1)) tb_a_cur(a_cur));
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_concat_x(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
