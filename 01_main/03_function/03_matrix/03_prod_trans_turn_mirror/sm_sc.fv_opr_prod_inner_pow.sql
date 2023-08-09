-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_inner_pow(anyarray, anyelement);
create or replace function sm_sc.fv_opr_prod_inner_pow
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyelement
as
$$
declare -- here
begin
  return |@+| (i_left ^` i_right);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_prod_inner_pow
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     2.0
--   );
-- select sm_sc.fv_opr_prod_inner_pow
--   (
--     array[12.3, -12.3, 45.6, -45.6],
--     4.0
--   );
-- select sm_sc.fv_opr_prod_inner_pow
--   (
--     array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]],
--     2.0
--   );
-- select sm_sc.fv_opr_prod_inner_pow
--   (
--     array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex, (2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex],
--     3.0
--   );