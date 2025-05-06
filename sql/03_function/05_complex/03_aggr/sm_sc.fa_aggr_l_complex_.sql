-- create or replace aggregate sum (sm_sc.typ_l_complex)
drop aggregate if exists sum (sm_sc.typ_l_complex);
create aggregate sum (sm_sc.typ_l_complex)
(
  sfunc = sm_sc.fv_opr_add,
  stype = sm_sc.typ_l_complex,
  initcond = '(0.0,0.0)',
  parallel = safe
);

-- select sum(a_val)
-- from 
-- (
--   select (32.5 :: float, 54.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (-32.5 :: float, -24.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (-42.5 :: float, 14.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (12.5 :: float, -54.2 :: float)::sm_sc.typ_l_complex as a_val
-- ) tb_a

-- create or replace aggregate sum (sm_sc.typ_l_complex)
drop aggregate if exists sm_sc.fa_l_complex_sum(sm_sc.typ_l_complex);
create aggregate sm_sc.fa_l_complex_sum (sm_sc.typ_l_complex)
(
  sfunc = sm_sc.fv_opr_add,
  stype = sm_sc.typ_l_complex,
  initcond = '(0.0,0.0)',
  parallel = safe
);

-- select sm_sc.fa_l_complex_sum(a_val)
-- from 
-- (
--   select (32.5 :: float, 54.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (-32.5 :: float, -24.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (-42.5 :: float, 14.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (12.5 :: float, -54.2 :: float)::sm_sc.typ_l_complex as a_val
-- ) tb_a

-- -- -- -----------------------------------------------------------------------------------
-- -- -- drop type if exists sm_sc.__typ_l_complex_ex cascade;
-- -- create type sm_sc.__typ_l_complex_ex as
-- -- (
-- --   m_arr_mid      sm_sc.typ_l_complex,
-- --   m_cnt          int
-- -- );

-- ---------------------
-- create or replace function sm_sc.fv_l_complex_add_ex
-- drop function if exists sm_sc.fv_l_complex_add_ex;
create or replace function sm_sc.fv_l_complex_add_ex
(
  i_left      sm_sc.__typ_l_complex_ex,
  i_right     sm_sc.typ_l_complex
)
returns sm_sc.__typ_l_complex_ex
as
$$
-- declare
begin
  i_left.m_arr_mid := i_left.m_arr_mid + i_right;
  i_left.m_cnt := coalesce(i_left.m_cnt, 0) + 1;
  return i_left;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_l_complex_add_ex(row((12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex, 2), (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex)

-- ---------------------
-- create or replace function sm_sc.__fv_mx_avg_final
-- drop function if exists sm_sc.__fv_mx_avg_final(sm_sc.__typ_l_complex_ex);
create or replace function sm_sc.__fv_mx_avg_final
(
  i_ret_mid      sm_sc.__typ_l_complex_ex
)
returns sm_sc.typ_l_complex
as
$$
-- declare
begin
  return i_ret_mid.m_arr_mid / (i_ret_mid.m_cnt :: float);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.__fv_mx_avg_final(row((12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex, 2))

-- ---------------------
-- create or replace aggregate sm_sc.fa_mx_avg (sm_sc.typ_l_complex)
drop aggregate if exists sm_sc.fa_mx_avg (sm_sc.typ_l_complex);
create aggregate sm_sc.fa_mx_avg (sm_sc.typ_l_complex)
(
  sfunc = sm_sc.fv_l_complex_add_ex,
  stype = sm_sc.__typ_l_complex_ex,
  initcond = '("(0.0, 0.0)",0)',
  finalfunc = sm_sc.__fv_mx_avg_final,
  parallel = safe
);

-- select sm_sc.fa_mx_avg(a_val)
-- from 
-- (
--   select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
-- ) t

-- ---------------------
-- create or replace aggregate avg (sm_sc.typ_l_complex)
drop aggregate if exists avg (sm_sc.typ_l_complex);
create aggregate avg (sm_sc.typ_l_complex)
(
  sfunc = sm_sc.fv_l_complex_add_ex,
  stype = sm_sc.__typ_l_complex_ex,
  initcond = '("(0.0, 0.0)",0)',
  finalfunc = sm_sc.__fv_mx_avg_final,
  parallel = safe
);

-- select avg(a_val)
-- from 
-- (
--   select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex as a_val
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
--   union all select (12.5 :: float, 24.2 :: float)::sm_sc.typ_l_complex
-- ) t