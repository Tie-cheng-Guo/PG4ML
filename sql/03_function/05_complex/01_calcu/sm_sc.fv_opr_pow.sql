-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_pow(sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_pow
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  if i_left = 0.0 :: sm_sc.typ_l_complex
  then 
    return 0.0 :: sm_sc.typ_l_complex;
  else
    return sm_sc.fv_opr_exp(sm_sc.fv_opr_ln(i_left) * i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_pow
--   (
--     (2.3, -2.3),
--     (-5.6, -5.6)
--   );
-- select sm_sc.fv_opr_pow
--   (
--     10.0 :: float,
--     (-4.6, -4.6)
--   );
-- select sm_sc.fv_opr_pow
--   (
--     (-4.6, -4.6),
--     10.0
--   );
-- select (-1.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex ^ pi()::float::sm_sc.typ_l_complex
