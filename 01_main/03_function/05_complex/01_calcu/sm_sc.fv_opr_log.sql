-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_log(sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_log
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return sm_sc.fv_opr_ln(i_right) / sm_sc.fv_opr_ln(i_left);
end
$$
language plpgsql stable
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_log
--   (
--     (12.3, -12.3),
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_log
--   (
--     100.0 :: float,
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_log
--   (
--     (-45.6, -45.6),
--     100.0
--   );

