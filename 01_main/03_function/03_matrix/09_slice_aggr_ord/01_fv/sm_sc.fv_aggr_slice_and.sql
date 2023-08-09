-- -- bit ele_and
-- drop function if exists sm_sc.fv_aggr_slice_and(bit[]);
create or replace function sm_sc.fv_aggr_slice_and
(
  i_array          bit[]
)
returns bit
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) is null
  then
    return i_array[0];
  else
    return
    (
      select 
        bit_and(a_ele)
      from unnest(i_array) tb_a(a_ele)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[B'010', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011']]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[B'010', B'011', B'010', B'011', B'101', B'011', B'010', B'011']
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[] :: bit[]
--   );

-- --------------------------------------------------------------------------------
-- -- boolean ele_and
-- drop function if exists sm_sc.fv_aggr_slice_and(boolean[]);
create or replace function sm_sc.fv_aggr_slice_and
(
  i_array          boolean[]
)
returns boolean
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) is null
  then
    return null;
  else
    return 
    ( 
      false <> all(i_array)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[true, false, false, true], [false, true, false, true], [true, false, false, false], [false, false, true, true], [true, true, false, true]]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[true, false, false, true, false, true, false, true]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[] :: boolean[]
--   );