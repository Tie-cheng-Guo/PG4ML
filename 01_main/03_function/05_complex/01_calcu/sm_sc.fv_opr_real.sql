-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_real(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_real
(
  i_right    sm_sc.typ_l_complex
)
returns float
as
$$
-- declare 
begin
  return i_right.m_re;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_real
--   (
--     (45.6, -45.6)
--   );
-- select sm_sc.fv_opr_real
--   (
--     100.0
--   );
-- select sm_sc.fv_opr_real
--   (
--     (0, -16.0)
--   );
-- select sm_sc.fv_opr_real
--   (
--     0.0
--   );