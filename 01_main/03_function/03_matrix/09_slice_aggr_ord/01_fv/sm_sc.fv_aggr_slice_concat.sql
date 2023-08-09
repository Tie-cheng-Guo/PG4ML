-- set search_path to sm_sc;

-- drop function if exists sm_sc.fv_concat_ex(anyelement, anyelement);
create or replace function sm_sc.fv_concat_ex
(
  i_left       anyelement    ,
  i_right      anyelement
)
returns anyelement
as
$$
-- declare
begin
  return i_left || i_right;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_concat_ex(B'1010', B'0101')

-- -----------------------------
-- create or replace aggregate sm_sc.fa_concat (anyelement)
drop aggregate if exists sm_sc.fa_concat(anyelement);
create aggregate sm_sc.fa_concat (anyelement)
(
  sfunc = sm_sc.fv_concat_ex,
  stype = anyelement,
  initcond = ''
);

-- select sm_sc.fa_concat(a_val)
-- from 
-- (
--   select B'1010' as a_val
--   union all select B'1110'
--   union all select B'1011'
--   union all select B'0010'
--   union all select B'1000'
-- ) t

-- select sm_sc.fa_concat(a_val order by a_val)
-- from 
-- (
--   select B'1010' as a_val
--   union all select B'1110'
--   union all select B'1011'
--   union all select B'0010'
--   union all select B'1000'
-- ) t

-- select sm_sc.fa_concat(a_val)
-- from 
-- (
--   select 'abc' as a_val
--   union all select 'faera'
--   union all select '4564'
--   union all select 'kuk7'
--   union all select '66yy'
-- ) t

-- select sm_sc.fa_concat(a_val order by a_val)
-- from 
-- (
--   select 'abc' as a_val
--   union all select 'faera'
--   union all select '4564'
--   union all select 'kuk7'
--   union all select '66yy'
-- ) t

-- -----------------------------
-- -- bit ele_concat
-- drop function if exists sm_sc.fv_aggr_slice_concat(anyarray, int[], int[]);
create or replace function sm_sc.fv_aggr_slice_concat
(
  i_array          anyarray
)
returns anyelement
as
$$
-- declare 
begin
  if array_ndims(i_array) is null
  then
    return i_array[0];
  else
    return
    (
      select 
        sm_sc.fa_concat(a_ele)
      from unnest(i_array) a_ele -- tb_a(a_ele)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_concat
--   (
--     array[array[B'010', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011'], array[B'101', B'011', B'010', B'011']]
--   );

-- select sm_sc.fv_aggr_slice_concat
--   (
--     array[B'010', B'011', B'010', B'011', B'101', B'011', B'010', B'011']
--   );
