-- drop function if exists sm_sc.fv_opr_concat_width(anyarray, anyarray);
create or replace function sm_sc.fv_opr_concat_width
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  if greatest(array_ndims(i_left), array_ndims(i_right)) not between 2 and 4
  then
    raise exception 'no method for such length!  ndims_1: %; ndims_2: %;', array_ndims(i_left), array_ndims(i_right);
  elsif greatest(array_ndims(i_left), array_ndims(i_right)) = 4
  then 
    return sm_sc.fv_concat_x4(i_left, i_right);
  elsif greatest(array_ndims(i_left), array_ndims(i_right)) = 3
  then 
    return sm_sc.fv_concat_x3(i_left, i_right);
  elsif greatest(array_ndims(i_left), array_ndims(i_right)) = 2
  then 
    return sm_sc.fv_concat_x(i_left, i_right);
  -- elsif greatest(array_ndims(i_left), array_ndims(i_right)) = 1
  -- then 
  --   return array_fill(i_left, array[1]) || i_right;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     array[array[12.3, 25.1], array[2.56, 3.25]]
--   , array[array[12.3, 25.1], array[2.56, 3.25]]
--   )
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     array[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]]]
--   , array[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]]]
--   )
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     array[[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]]]
--   , array[[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]]]
--   )


-- -----------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat_width(anyarray, anyelement);
create or replace function sm_sc.fv_opr_concat_width
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyarray
as
$$
-- declare 
begin
  if array_ndims(i_left) not between 2 and 4
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  elsif array_ndims(i_left) = 4
  then 
    return sm_sc.fv_concat_x4(i_left, i_right);
  elsif array_ndims(i_left) = 3
  then 
    return sm_sc.fv_concat_x3(i_left, i_right);
  elsif array_ndims(i_left) = 2
  then 
    return sm_sc.fv_concat_x(i_left, i_right);
  -- elsif greatest(array_ndims(i_left), array_ndims(i_right)) = 1
  -- then 
  --   return array_fill(i_left, array[1]) || i_right;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     array[array[12.3, 25.1], array[2.56, 3.25]]
--   , 3.8
--   )
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     array[[[-1,-2.9,-3,-4],[-11,-12,-13.1,-14],[-111,-112,-113,-114]]]
--   , 3.8
--   )
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     array[[[[-1,-2,-3,-4.8],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]]]
--   , 3.8
--   )

-- -----------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat_width(anyelement, anyarray);
create or replace function sm_sc.fv_opr_concat_width
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  if array_ndims(i_right) not between 2 and 4
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  elsif array_ndims(i_right) = 4
  then 
    return sm_sc.fv_concat_x4(i_left, i_right);
  elsif array_ndims(i_right) = 3
  then 
    return sm_sc.fv_concat_x3(i_left, i_right);
  elsif array_ndims(i_right) = 2
  then 
    return sm_sc.fv_concat_x(i_left, i_right);
  -- elsif greatest(array_ndims(i_left), array_ndims(i_right)) = 1
  -- then 
  --   return array_fill(i_left, array[1]) || i_right;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     3.8
--   , array[array[12.3, 25.1], array[2.56, 3.25]]
--   )
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     3
--   , array[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]]]
--   )
-- select 
--   sm_sc.fv_opr_concat_width
--   (
--     3
--   , array[[[[-1,-2,-3,-4],[-11,-12,-13,-14],[-111,-112,-113,-114]],[[-5,-6,-7,-8],[-15,-16,-17,-18],[-115,-116,-117,-118]]]]
--   )
