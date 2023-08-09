-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_div(sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_div
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return i_left * (~ i_right) * (1.0 :: float/ (i_right.m_re ^ 2 + i_right.m_im ^ 2));
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_div
--   (
--     (12.3, -12.3),
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_div
--   (
--     100.0 :: float,
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_div
--   (
--     (-45.6, -45.6),
--     100.0
--   );

-- ------------------------------------------------------------------------------
-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_div(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_div
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return sm_sc.fv_opr_div(1.0 :: float, i_right);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_div
--   (
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_div
--   (
--     100.0
--   );
-- -- select sm_sc.fv_opr_div
-- --   (
-- --     0.0
-- --   );