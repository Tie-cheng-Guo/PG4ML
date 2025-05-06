-- set search_path to sm_sc;
-- drop function if exists sm_sc.exp(sm_sc.typ_l_complex);
create or replace function sm_sc.exp
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return 
    exp(i_right.m_re) * (cos(i_right.m_im), sin(i_right.m_im))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.exp
--   (
--     (45.6, -45.6)
--   );
-- select sm_sc.exp
--   (
--     (0, pi()::float)
--   );
-- select sm_sc.exp
--   (
--     (0, -pi()::float/2)
--   );
-- select sm_sc.exp
--   (
--     pi()::float
--   );
-- select sm_sc.exp
--   (
--     (0, -pi()::float)
--   );
-- -- select sm_sc.exp
-- --   (
-- --     0.0
-- --   );