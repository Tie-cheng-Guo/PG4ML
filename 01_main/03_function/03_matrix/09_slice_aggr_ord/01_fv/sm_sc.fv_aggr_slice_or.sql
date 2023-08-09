-- -- bit ele_or
-- drop function if exists sm_sc.fv_aggr_slice_or(bit[]);
create or replace function sm_sc.fv_aggr_slice_or
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
        bit_or(a_ele)
      from unnest(i_array) tb_a(a_ele)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;


-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_or
--   (
--     array[array[B'010', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011']]
--   );

-- select sm_sc.fv_aggr_slice_or
--   (
--     array[B'010', B'011', B'010', B'011', B'101', B'011', B'010', B'011']
--   );

-- select sm_sc.fv_aggr_slice_or
--   (
--     array[] :: bit[]
--   );

-- --------------------------------------------------------------------------------
-- -- boolean ele_or
-- drop function if exists sm_sc.fv_aggr_slice_or(boolean[]);
create or replace function sm_sc.fv_aggr_slice_or
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
      true = any(i_array)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_or
--   (
--     array[array[true, false, false, true], array[false, true, false, true], array[true, false, false, false], array[false, false, true, true], array[true, true, false, true]]
--   );

-- select sm_sc.fv_aggr_slice_or
--   (
--     array[true, false, false, true, false, true, false, true]
--   );

-- select sm_sc.fv_aggr_slice_or
--   (
--     array[] :: boolean[]
--   );