-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_conjugate_45(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_conjugate_45
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return (i_right.m_im, i_right.m_re);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_conjugate_45
--   (
--     (45.6, -45.6)
--   );
-- select sm_sc.fv_opr_conjugate_45
--   (
--     100.0
--   );
-- select sm_sc.fv_opr_conjugate_45
--   (
--     (0, -16.0)
--   );
-- select sm_sc.fv_opr_conjugate_45
--   (
--     0.0
--   );