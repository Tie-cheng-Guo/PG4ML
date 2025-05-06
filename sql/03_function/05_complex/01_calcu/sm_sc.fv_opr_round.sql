-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_round(sm_sc.typ_l_complex, int);
create or replace function sm_sc.fv_opr_round
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    int
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return (round(i_left.m_re, i_right), round(i_left.m_im, i_right))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_round
--   (
--     (12.35464645, -12.30325015),
--     2
--   );

-- -------------------------------------------------------------------------------------
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_round(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_round
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return (round(i_right.m_re), round(i_right.m_im))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_round
--   (
--     (-45.6, -45.6)
--   );