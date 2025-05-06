-- set search_path to sm_sc;
-- drop function if exists public.exp(sm_sc.typ_l_complex);
create or replace function public.exp
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
-- select public.exp
--   (
--     (45.6, -45.6)
--   );
-- select public.exp
--   (
--     (0, pi()::float)
--   );
-- select public.exp
--   (
--     (0, -pi()::float/2)
--   );
-- select public.exp
--   (
--     pi()::float
--   );
-- select public.exp
--   (
--     (0, -pi()::float)
--   );
-- -- select public.exp
-- --   (
-- --     0.0
-- --   );