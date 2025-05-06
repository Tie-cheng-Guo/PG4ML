-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_concat_x(anyarray, anyarray);
create or replace function sm_sc.fv_concat_x
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare 
  v_ret      i_left%type;
  v_len_left    int[]  := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
  v_len_right   int[]  := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
  
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_left) <> array_ndims(i_right)
      or 
        array_ndims(i_left) = 3 and array_ndims(i_right) = 3
        and
        (
          array_length(i_left, 1) <> array_length(i_right, 1)
          or array_length(i_left, 3) <> array_length(i_right, 3)
        )
      or 
        array_ndims(i_left) = 4 and array_ndims(i_right) = 4
        and
        (
          array_length(i_left, 1) <> array_length(i_right, 1)
          or array_length(i_left, 3) <> array_length(i_right, 3)
          or array_length(i_left, 4) <> array_length(i_right, 4)
        )
      or 
        array_ndims(i_left) = 5 and array_ndims(i_right) = 5
        and
        (
          array_length(i_left, 1) <> array_length(i_right, 1)
          or array_length(i_left, 3) <> array_length(i_right, 3)
          or array_length(i_left, 4) <> array_length(i_right, 4)
          or array_length(i_left, 5) <> array_length(i_right, 5)
        )
      or array_ndims(i_left) = 2 and array_ndims(i_right) = 2
        and array_length(i_left, 1) <> 1
        and array_length(i_right, 1) <> 1
        and array_length(i_left, 1) <> array_length(i_right, 1)
      or array_ndims(i_left) = 1 and array_ndims(i_right) = 1
    then
      raise exception 'unmatched length!';     
    end if;   
  end if;

  -- 对齐维长
  if (v_len_left[ : 1] || v_len_left[3 : ]) <> (v_len_right[ : 1] || v_len_right[3 : ]) and array_ndims(i_left) <> 1 and array_ndims(i_right) <> 1
  then 
    i_left := sm_sc.fv_new(i_left, (1 @>` (v_len_right[ : 1] / v_len_left[ : 1])) || array[1] || (1 @>` (v_len_right[3 : ] / v_len_left[3 : ])));
    i_right := sm_sc.fv_new(i_right, (1 @>` (v_len_left[ : 1] / v_len_right[ : 1])) || array[1] || (1 @>` (v_len_left[3 : ] / v_len_right[3 : ])));
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
      -- -- return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
      v_ret := array_fill(nullif(i_left[1][1], i_left[1][1]), array[array_length(i_left, 1), array_length(i_left, 2) + array_length(i_right, 2)]);
      v_ret[ : ][ : array_length(i_left, 2)] := i_left;
      v_ret[ : ][array_length(i_left, 2) + 1 : ] := i_right;
      return v_ret;
    elsif array_length(i_left, 1) = 1
    then
      -- -- return (select array_agg(array(select unnest(i_left[1:1][:])) || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_right, 1)) tb_a_cur(a_cur));
      v_ret := array_fill(nullif(i_left[1][1], i_left[1][1]), array[array_length(i_right, 1), array_length(i_left, 2) + array_length(i_right, 2)]);
      v_ret[ : ][ : array_length(i_left, 2)] := (select sm_sc.fa_mx_concat_y(i_left) from generate_series(1, array_length(i_right, 1)));
      v_ret[ : ][array_length(i_left, 2) + 1 : ] := i_right;
      return v_ret;
    elsif array_length(i_right, 1) = 1
    then
      -- -- return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || array(select unnest(i_right[1:1][:])) order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
      v_ret := array_fill(nullif(i_left[1][1], i_left[1][1]), array[array_length(i_left, 1), array_length(i_left, 2) + array_length(i_right, 2)]);
      v_ret[ : ][ : array_length(i_left, 2)] := i_left;
      v_ret[ : ][array_length(i_left, 2) + 1 : ] := (select sm_sc.fa_mx_concat_y(i_right) from generate_series(1, array_length(i_left, 1)));
      return v_ret;
    end if;
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 2
  then
    -- -- return (select array_agg(i_left || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_right, 1)) tb_a_cur(a_cur));
    v_ret := array_fill(nullif(i_right[1][1], i_left[1][1]), array[array_length(i_right, 1), array_length(i_left, 1) + array_length(i_right, 2)]);
    v_ret[ : ][ : array_length(i_left, 2)] := (select array_agg(i_left) from generate_series(1, array_length(i_right, 1)));
    v_ret[ : ][array_length(i_left, 2) + 1 : ] := i_right;
    return v_ret;
  elsif array_ndims(i_right) = 1 and array_ndims(i_left) = 2
  then
    -- -- return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || i_right order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
    v_ret := array_fill(nullif(i_left[1][1], i_left[1][1]), array[array_length(i_left, 1), array_length(i_left, 2) + array_length(i_right, 1)]);
    v_ret[ : ][ : array_length(i_left, 2)] := i_left;
    v_ret[ : ][array_length(i_left, 2) + 1 : ] := (select array_agg(i_right) from generate_series(1, array_length(i_left, 1)));
    return v_ret;
  elsif i_left is null
  then
    return i_right;
  elsif i_right is null
  then
    return i_left;
    
  elsif array_ndims(i_left) = 3 and array_ndims(i_right) = 3
  then 
    v_ret := array_fill(nullif(i_left[1][1][1],i_left[1][1][1]), array[array_length(i_left, 1), array_length(i_left, 2) + array_length(i_right, 2), array_length(i_left, 3)]);
    v_ret[ : ][ : array_length(i_left, 2)][ : ] := i_left;
    v_ret[ : ][array_length(i_left, 2) + 1 : ][ : ] := i_right;
    return v_ret;
    
  elsif array_ndims(i_left) = 4 and array_ndims(i_right) = 4
  then 
    v_ret := array_fill(nullif(i_left[1][1][1][1],i_left[1][1][1][1]), array[array_length(i_left, 1), array_length(i_left, 2) + array_length(i_right, 2), array_length(i_left, 3), array_length(i_left, 4)]);
    v_ret[ : ][ : array_length(i_left, 2)][ : ][ : ] := i_left;
    v_ret[ : ][array_length(i_left, 2) + 1 : ][ : ][ : ] := i_right;
    return v_ret;
    
  elsif array_ndims(i_left) = 5 and array_ndims(i_right) = 5
  then 
    v_ret := array_fill(nullif(i_left[1][1][1][1][1],i_left[1][1][1][1][1]), array[array_length(i_left, 1), array_length(i_left, 2) + array_length(i_right, 2), array_length(i_left, 3), array_length(i_left, 4), array_length(i_left, 5)]);
    v_ret[ : ][ : array_length(i_left, 2)][ : ][ : ][ : ] := i_left;
    v_ret[ : ][array_length(i_left, 2) + 1 : ][ : ][ : ][ : ] := i_right;
    return v_ret;
    
  else
    raise exception 'no method for such length!  L_Dim: %; R_Dim: %;', array_dims(i_left), array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3, 55.5, -6.66]]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[-12.3, 12.3, 55.5, -6.66]],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[-12.3, 12.3, 55.5, -6.66]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[-12.3, 12.3, 55.5, -6.66],
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[], array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[],
--     array[array[], array[]]::float[]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[]]::float[],
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[]
--   );
-- select sm_sc.fv_concat_x
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]::float[],
--     array[array[]]::float[]
--   );
-- select 
--   sm_sc.fv_concat_x
--   (
--     array[[[-1,-2,-3,-4],[-11,-12,-13,-14]],[[-5,-6,-7,-8],[-15,-16,-17,-18]]]
--   , array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   )
-- select 
--   sm_sc.fv_concat_x
--   (
--     array[[[[1,2,3,4],[11,12,13,14],[111,112,113,114]]],[[[21,22,23,24],[31,32,33,34],[131,132,133,134]]]]
--   , array[[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]],[[[-21,-22,-23,-24],[-31,-32,-33,-34],[-121,-122,-123,-124]],[[-25,-26,-27,-28],[-35,-36,-37,-38],[-125,-126,-127,-128]]]]
--   )
-- select 
--   sm_sc.fv_concat_x
--   (
--     array[sm_sc.fv_new_rand(array[2,3,4,5])]
--   , array[sm_sc.fv_new_rand(array[3,3,4,5])]
--   )
-- --------------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_concat_x(anyarray, anyelement);
create or replace function sm_sc.fv_concat_x
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyarray
as
$$
declare 
  v_ret   i_left%type  ;
begin
  if array_ndims(i_left) > 5 or array_ndims(i_left) < 2
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
    
  elsif array_ndims(i_left) = 2
  then 
    -- return (select array_agg(array(select unnest(i_left[a_cur:a_cur][:])) || i_right order by a_cur) from generate_series(1, array_length(i_left, 1)) tb_a_cur(a_cur));
    v_ret := array_fill(i_right, array[array_length(i_left, 1), array_length(i_left, 2) + 1]);
    v_ret[ : ][ : array_length(i_left, 2)] := i_left;
    return v_ret;
    
  elsif array_ndims(i_left) = 3
  then 
    v_ret := array_fill(i_right, array[array_length(i_left, 1), array_length(i_left, 2) + 1, array_length(i_left, 3)]);
    v_ret[ : ][ : array_length(i_left, 2)][ : ] := i_left;
    return v_ret;
    
  elsif array_ndims(i_left) = 4
  then 
    v_ret := array_fill(i_right, array[array_length(i_left, 1), array_length(i_left, 2) + 1, array_length(i_left, 3), array_length(i_left, 4)]);
    v_ret[ : ][ : array_length(i_left, 2)][ : ][ : ] := i_left;
    return v_ret;
    
  elsif array_ndims(i_left) = 5
  then 
    v_ret := array_fill(i_right, array[array_length(i_left, 1), array_length(i_left, 2) + 1, array_length(i_left, 3), array_length(i_left, 4), array_length(i_left, 5)]);
    v_ret[ : ][ : array_length(i_left, 2)][ : ][ : ][ : ] := i_left;
    return v_ret;
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_concat_x(array[array[12.3, 25.1], array[2.56, 3.25]], 2.8)
-- select 
--   sm_sc.fv_concat_x
--   (
--     array[[[-1,-2,-3,-4],[-11,-12,-13,-14]],[[-5,-6,-7,-8],[-15,-16,-17,-18]]] :: float[]
--   , 5.33 :: float
--   )
-- select 
--   sm_sc.fv_concat_x
--   (
--     array[[[[1,2,3,4],[11,12,13,14],[111,112,113,114]]],[[[21,22,23,24],[31,32,33,34],[131,132,133,134]]]] :: float[]
--   , 5.33 :: float
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_concat_x(anyelement, anyarray);
create or replace function sm_sc.fv_concat_x
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare 
  v_ret   i_right%type  ;
begin
  if array_ndims(i_right) > 5 or array_ndims(i_right) < 2
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  elsif array_ndims(i_right) = 2
  then
    -- return (select array_agg(i_left || array(select unnest(i_right[a_cur:a_cur][:])) order by a_cur) from generate_series(1, array_length(i_right, 1)) tb_a_cur(a_cur));
    v_ret := array_fill(i_left, array[array_length(i_right, 1), array_length(i_right, 2) + 1]);
    v_ret[ : ][2 : ] := i_right;
    return v_ret;
    
  elsif array_ndims(i_right) = 3
  then 
    v_ret := array_fill(i_left, array[array_length(i_right, 1), array_length(i_right, 2) + 1, array_length(i_right, 3)]);
    v_ret[ : ][2 : ][ : ] := i_right;
    return v_ret;
    
  elsif array_ndims(i_right) = 4
  then 
    v_ret := array_fill(i_left, array[array_length(i_right, 1), array_length(i_right, 2) + 1, array_length(i_right, 3), array_length(i_right, 4)]);
    v_ret[ : ][2 : ][ : ][ : ] := i_right;
    return v_ret;
    
  elsif array_ndims(i_right) = 5
  then 
    v_ret := array_fill(i_left, array[array_length(i_right, 1), array_length(i_right, 2) + 1, array_length(i_right, 3), array_length(i_right, 4), array_length(i_right, 5)]);
    v_ret[ : ][2 : ][ : ][ : ][ : ] := i_right;
    return v_ret;
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_concat_x(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select 
--   sm_sc.fv_concat_x
--   (
--     5.33 :: float
--   , array[[[-1,-2,-3,-4],[-11,-12,-13,-14]],[[-5,-6,-7,-8],[-15,-16,-17,-18]]] :: float[]
--   )
-- select 
--   sm_sc.fv_concat_x
--   (
--    5.33 :: float
--   , array[[[[1,2,3,4],[11,12,13,14],[111,112,113,114]]],[[[21,22,23,24],[31,32,33,34],[131,132,133,134]]]] :: float[]
--   )
