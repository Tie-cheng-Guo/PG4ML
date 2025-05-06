-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_sin(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_sin
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
declare 
  -- v_tmp   sm_sc.typ_l_complex  := exp((0.0, 1.0) :: sm_sc.typ_l_complex * i_right);
begin  -- i_right.m_re, i_right.m_im
  return row(sin(i_right.m_re) * ((exp(i_right.m_im) + exp(-i_right.m_im)) / 2.0 :: float), cos(i_right.m_re) * ((exp(i_right.m_im) - exp(-i_right.m_im)) / 2.0 :: float)) :: sm_sc.typ_l_complex;
  -- return (v_tmp - (1.0 / v_tmp)) / (0.0, 2.0);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_sin
--   (
--     (-5.6, 5.6)
--   );
-- select sm_sc.fv_sin
--   (
--     100.0
--   );