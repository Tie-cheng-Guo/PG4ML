
-- drop function if exists sm_sc.fv_coalesce_ex(anyelement, anyelement);
create or replace function sm_sc.fv_coalesce_ex
(
  i_left  anyelement,
  i_right anyelement
)
returns anyelement
as
$$
begin
  return coalesce(i_left, i_right);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_coalesce_ex(null::text, 'abc')
-- -----------------------------

-- create or replace aggregate sm_sc.fa_coalesce (anyelement)
drop aggregate if exists sm_sc.fa_coalesce(anyelement);
create aggregate sm_sc.fa_coalesce (anyelement)
(
  sfunc = sm_sc.fv_coalesce_ex,
  stype = anyelement
);
-- select sm_sc.fa_coalesce(a_val)
-- from (select null as a_val union all select 'abc' union all select 'cde') tb_a(a_val)
-- -----------------------------