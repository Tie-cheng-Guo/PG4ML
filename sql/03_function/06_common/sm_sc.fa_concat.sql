-- set search_path to sm_sc;

-- drop function if exists sm_sc.__fv_concat_ex(anyelement, anyelement);
create or replace function sm_sc.__fv_concat_ex
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
-- select sm_sc.__fv_concat_ex(B'1010', B'0101')

-- -----------------------------
-- create or replace aggregate sm_sc.fa_concat (anyelement)
drop aggregate if exists sm_sc.fa_concat(anyelement);
create aggregate sm_sc.fa_concat (anyelement)
(
  sfunc = sm_sc.__fv_concat_ex,
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

-- create or replace aggregate sm_sc.fa_concat (jsonb)
drop aggregate if exists sm_sc.fa_concat(jsonb);
create aggregate sm_sc.fa_concat (jsonb)
(
  sfunc = sm_sc.__fv_concat_ex,
  stype = jsonb,
  initcond = '[]'
);

-- select sm_sc.fa_concat(a_val order by a_val)
-- from 
-- (
--   select '[{"node_no" : 101, "node_type" : "weight", "node_fn_type" : "00_const", "node_desc" : "w_q"}]'::jsonb  as a_val
--   union all select '[{"node_no" : 105, "node_type" : null, "node_fn_type" : "01_prod_mx", "node_desc" : "|**| w_k"}]'::jsonb
--   union all select '[{"node_no" : 107, "node_type" : null, "node_fn_type" : "04_transpose", "node_desc" : "transpose(k)"}]'::jsonb
-- ) t