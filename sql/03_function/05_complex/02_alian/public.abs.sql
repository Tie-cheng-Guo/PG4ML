-- set search_path to sm_sc;
-- -- sm_sc.fv_opr_norm 的别名
-- drop function if exists public.abs(sm_sc.typ_l_complex);
create or replace function public.abs
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return row(abs(i_right.m_re), abs(i_right.m_im )) :: sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select public.abs
--   (
--     (-45.6, -45.6)::sm_sc.typ_l_complex
--   );
-- select public.abs
--   (
--     100.0::sm_sc.typ_l_complex
--   );

-- -- -- drop function if exists abs(sm_sc.typ_l_complex);
-- -- create or replace function abs
-- -- (
-- --   i_right    sm_sc.typ_l_complex
-- -- )
-- -- returns float
-- -- as
-- -- $$
-- -- -- declare 
-- -- begin
-- --   return sqrt(i_right.m_re ^ 2 + i_right.m_im ^ 2);
-- -- end
-- -- $$
-- -- language plpgsql stable
-- -- parallel safe
-- -- cost 100;