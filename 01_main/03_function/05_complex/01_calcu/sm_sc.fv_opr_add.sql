-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_add(sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_add
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return row(i_left.m_re + i_right.m_re, i_left.m_im + i_right.m_im)::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_add
--   (
--     (12.3, -12.3),
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_add
--   (
--     100.0 :: float,
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_add
--   (
--     (-45.6, -45.6),
--     100.0
--   );