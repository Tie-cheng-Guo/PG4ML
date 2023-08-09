-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_trunc(sm_sc.typ_l_complex, int);
create or replace function sm_sc.fv_opr_trunc
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    int
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return 
    (trunc(i_left.m_re, i_right), trunc(i_left.m_im, i_right))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_trunc
--   (
--     (12.35464645, -12.30325015),
--     2
--   );

-- -------------------------------------------------------------------------------------
-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_trunc(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_trunc
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return (trunc(i_right.m_re), trunc(i_right.m_im))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_trunc
--   (
--     (-45.6, -45.6)
--   );