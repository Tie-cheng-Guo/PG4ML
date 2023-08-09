-- drop function if exists sm_sc.fv_prod_ex(anyelement, anyelement);
create or replace function sm_sc.fv_prod_ex
(
  i_left       anyelement    ,
  i_right      anyelement
)
returns anyelement
as
$$
-- declare
begin
  return i_left * i_right;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_prod_ex(1.1, 1.2)

-- -----------------------------
-- create or replace aggregate sm_sc.fa_prod (anyelement)
drop aggregate if exists sm_sc.fa_prod(anyelement);
create aggregate sm_sc.fa_prod (anyelement)
(
  sfunc = sm_sc.fv_prod_ex,
  stype = anyelement,
  initcond = 1
);

-- select sm_sc.fa_prod(a_val)
-- from 
-- (
--   select 1.1 as a_val
--   union all select 1.2
--   union all select 1.3
--   union all select 1.4
--   union all select 1.5
-- ) t

-- -----------------------------