-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_conjugate(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_conjugate
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return row(i_right.m_re, -i_right.m_im) :: sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_conjugate
--   (
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_conjugate
--   (
--     100.0
--   );