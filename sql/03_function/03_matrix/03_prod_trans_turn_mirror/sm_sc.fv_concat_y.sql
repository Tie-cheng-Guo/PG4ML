-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_concat_y(anyarray, anyarray);
create or replace function sm_sc.fv_concat_y
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare 
  v_len_left    int[]  := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
  v_len_right   int[]  := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
  
begin
  -- set search_path to sm_sc;
  -- 审计二维长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_left) <> array_ndims(i_right)
      or 
        array_ndims(i_left) = 3 and array_ndims(i_right) = 3
        and
        (
          array_length(i_left, 2) <> array_length(i_right, 2)
          or array_length(i_left, 3) <> array_length(i_right, 3)
        )
      or 
        array_ndims(i_left) = 4 and array_ndims(i_right) = 4
        and
        (
          array_length(i_left, 2) <> array_length(i_right, 2)
          or array_length(i_left, 3) <> array_length(i_right, 3)
          or array_length(i_left, 4) <> array_length(i_right, 4)
        )
      or 
        array_ndims(i_left) = 5 and array_ndims(i_right) = 5
        and
        (
          array_length(i_left, 2) <> array_length(i_right, 2)
          or array_length(i_left, 3) <> array_length(i_right, 3)
          or array_length(i_left, 4) <> array_length(i_right, 4)
          or array_length(i_left, 5) <> array_length(i_right, 5)
        )
      or array_ndims(i_left) = 2 and array_ndims(i_right) = 2
        and array_length(i_left, 2) <> array_length(i_right, 2) 
        and array_length(i_left, 2) <> 1
        and array_length(i_right, 2) <> 1
    then
      raise exception 'unmatched length!';
    end if;
  end if;

  -- 对齐维长
  if v_len_left[2 : ] <> v_len_right[2 : ] and array_ndims(i_left) <> 1 and array_ndims(i_right) <> 1
  then 
    i_left := sm_sc.fv_new(i_left, array[1] || (1 @>` (v_len_right[2 : ] / v_len_left[2 : ])));
    i_right := sm_sc.fv_new(i_right, array[1] || (1 @>` (v_len_left[2 : ] / v_len_right[2 : ])));
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
    or array_ndims(i_left) = 1 and array_length(i_left, 1) = array_length(i_right, 2) and array_ndims(i_right) = 2
    or array_ndims(i_right) = 1 and array_length(i_right, 1) = array_length(i_left, 2) and array_ndims(i_left) = 2
  then
    return i_left || i_right;
  -- 横向广播，i_left 需要延拓 [][1] ||| [][]
  elsif array_ndims(i_left) = 2 and array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    return (select array_agg(array_fill(i_left[cur_sn][1], array[array_length(i_right, 2)]) order by cur_sn) from generate_series(1, array_length(i_left, 1)) cur_sn) || i_right;
  -- 横向广播，i_right 需要延拓 [][] ||| [][1]
  elsif array_ndims(i_right) = 2 and array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    return i_left || (select array_agg(array_fill(i_right[cur_sn][1], array[array_length(i_left, 2)]) order by cur_sn) from generate_series(1, array_length(i_right, 1)) cur_sn);
  elsif i_left is null
  then 
    return i_right;
  elsif i_right is null
  then 
    return i_left;
    
  elsif array_ndims(i_left) = 3 and array_ndims(i_right) = 3
    or array_ndims(i_left) = 4 and array_ndims(i_right) = 4
    or array_ndims(i_left) = 5 and array_ndims(i_right) = 5
    or array_ndims(i_left) = 1 and array_ndims(i_right) = 1
  then 
    return 
      i_left || i_right
    ;
    
  -- 审计二维长度
  else
    raise exception 'no method for such length!  L_Dim: %; R_Dim: %;', array_dims(i_left), array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_concat_y
--   (
--     array[array[12.3, 12.3], array[45.6, 45.6]],
--     array[array[-2.1, 1.6], array[-1.6, 2.1]]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[32.5], array[9.1]],
--     array[array[2.3, 1.3], array[-5.6, 5.6]]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[12.3, 2.3], array[45.6, 45.6]],
--     array[array[3.5], array[-4.0]]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[32.5, 9.1],
--     array[array[2.3, 1.3], array[-5.6, 5.6]]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[12.3, 12.3], array[45.6, 45.6]],
--     array[2.5, -1.1]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[], array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[],
--     array[array[], array[]]::float[]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_y
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[],
--     array[array[]]::float[]
--   );
-- select 
--   sm_sc.fv_concat_y
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   , array[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]]]
--   )
-- select 
--   sm_sc.fv_concat_y
--   (
--     array[[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]],[[[21,22,23,24],[31,32,33,34],[131,132,133,134]],[[25,26,27,28],[35,36,37,38],[135,136,137,138]]]]
--   , array[[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]]]
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_concat_y(anyarray, anyelement);
create or replace function sm_sc.fv_concat_y
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyarray
as
$$
-- declare 
begin
  if array_ndims(i_left) > 5
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  elsif array_ndims(i_left) = 5 
  then
    return i_left || array_fill(i_right, array[1, array_length(i_left, 2), array_length(i_left, 3), array_length(i_left, 4), array_length(i_left, 5)]);
  elsif array_ndims(i_left) = 4 
  then
    return i_left || array_fill(i_right, array[1, array_length(i_left, 2), array_length(i_left, 3), array_length(i_left, 4)]);
  elsif array_ndims(i_left) = 3 
  then
    return i_left || array_fill(i_right, array[1, array_length(i_left, 2), array_length(i_left, 3)]);
  elsif array_ndims(i_left) = 2
  then
    return i_left || array_fill(i_right, array[1, array_length(i_left, 2)]);
  elsif array_ndims(i_left) = 1 
  then
    return i_left || array_fill(i_right, array[1]);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_concat_y(array[array[12.3, 25.1], array[2.56, 3.25]], 2.8)
-- select 
--   sm_sc.fv_concat_y
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   , -3
--   )
-- select 
--   sm_sc.fv_concat_y
--   (
--     array[[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]],[[[21,22,23,24],[31,32,33,34],[131,132,133,134]],[[25,26,27,28],[35,36,37,38],[135,136,137,138]]]]
--   , -3
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_concat_y(anyelement, anyarray);
create or replace function sm_sc.fv_concat_y
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  if array_ndims(i_right) > 5
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  elsif array_ndims(i_right) = 5
  then 
    return array_fill(i_left, array[1, array_length(i_right, 2), array_length(i_right, 3), array_length(i_right, 4), array_length(i_right, 5)]) || i_right;
  elsif array_ndims(i_right) = 4
  then 
    return array_fill(i_left, array[1, array_length(i_right, 2), array_length(i_right, 3), array_length(i_right, 4)]) || i_right;
  elsif array_ndims(i_right) = 3
  then 
    return array_fill(i_left, array[1, array_length(i_right, 2), array_length(i_right, 3)]) || i_right;
  elsif array_ndims(i_right) = 2
  then 
    return array_fill(i_left, array[1, array_length(i_right, 2)]) || i_right;
  elsif array_ndims(i_right) = 1
  then 
    return array_fill(i_left, array[1]) || i_right;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_concat_y(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select 
--   sm_sc.fv_concat_y
--   (
--     345
--   , array[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]]]
--   )
-- select 
--   sm_sc.fv_concat_y
--   (
--     345
--   , array[[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]]]
--   )
