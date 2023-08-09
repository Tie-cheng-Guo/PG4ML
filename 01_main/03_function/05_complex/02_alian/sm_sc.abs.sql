-- set search_path to schm_cpx;
-- -- sm_sc.fv_opr_norm 的别名
-- drop function if exists abs(sm_sc.typ_l_complex);
create or replace function abs
(
  i_right    sm_sc.typ_l_complex
)
returns float
as
$$
-- declare 
begin
  return sqrt(i_right.m_re ^ 2 + i_right.m_im ^ 2);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select abs
--   (
--     (-45.6, -45.6)::sm_sc.typ_l_complex
--   );
-- select abs
--   (
--     100.0::sm_sc.typ_l_complex
--   );