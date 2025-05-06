-- create or replace aggregate sm_sc.fa_mx_sum (anyarray)
drop aggregate if exists sm_sc.fa_mx_sum (anyarray);
create aggregate sm_sc.fa_mx_sum (anyarray)
(
  sfunc = sm_sc.fv_opr_add,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_sum(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_prod (anyarray)
drop aggregate if exists sm_sc.fa_mx_prod (anyarray);
create aggregate sm_sc.fa_mx_prod (anyarray)
(
  sfunc = sm_sc.fv_opr_mul,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_prod(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
-- ) t

-- -- -- -----------------------------------------------------------------------------------
-- -- -- drop type if exists sm_sc.__typ_arr_float_ex cascade;
-- -- create type sm_sc.__typ_arr_float_ex as
-- -- (
-- --   m_arr_mid      float[],
-- --   m_cnt          int
-- -- );

-- ---------------------
-- create or replace function sm_sc.__fv_arr_float_add_ex
-- drop function if exists sm_sc.__fv_arr_float_add_ex;
create or replace function sm_sc.__fv_arr_float_add_ex
(
  i_left      sm_sc.__typ_arr_float_ex,
  i_right     float[]
)
returns sm_sc.__typ_arr_float_ex
as
$$
-- declare
begin
  i_left.m_arr_mid := i_left.m_arr_mid +` i_right;
  i_left.m_cnt := coalesce(i_left.m_cnt, 0) + 1;
  return i_left;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.__fv_arr_float_add_ex(row(array[array[1.2, 1.3], array[2.3, 2.5]], 2), array[array[1.0 :: float, 1.0], array[2.0 :: float, 2.0]])

-- ---------------------
-- create or replace function sm_sc.__fv_mx_avg_final
-- drop function if exists sm_sc.__fv_mx_avg_final;
create or replace function sm_sc.__fv_mx_avg_final
(
  i_ret_mid      sm_sc.__typ_arr_float_ex
)
returns float[]
as
$$
-- declare
begin
  return i_ret_mid.m_arr_mid /` (i_ret_mid.m_cnt :: float);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.__fv_mx_avg_final(row(array[array[1.2, 1.3], array[2.3, 2.5]], 2))

-- ---------------------
-- create or replace aggregate sm_sc.fa_mx_avg (float[])
drop aggregate if exists sm_sc.fa_mx_avg (float[]);
create aggregate sm_sc.fa_mx_avg (float[])
(
  sfunc = sm_sc.__fv_arr_float_add_ex,
  stype = sm_sc.__typ_arr_float_ex,
  initcond = '("{{0}}",0)',
  finalfunc = sm_sc.__fv_mx_avg_final,
  parallel = safe
);

-- select sm_sc.fa_mx_avg(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
-- ) t

-- -- -- -----------------------------------------------------------------------------------
-- -- -- drop type if exists sm_sc.__typ_arr_cpx_ex cascade;
-- -- create type sm_sc.__typ_arr_cpx_ex as
-- -- (
-- --   m_arr_mid      sm_sc.typ_l_complex[],
-- --   m_cnt          int
-- -- );

-- ---------------------
-- create or replace function sm_sc.__fv_arr_cpx_add_ex
-- drop function if exists sm_sc.__fv_arr_cpx_add_ex;
create or replace function sm_sc.__fv_arr_cpx_add_ex
(
  i_left      sm_sc.__typ_arr_cpx_ex,
  i_right     sm_sc.typ_l_complex[]
)
returns sm_sc.__typ_arr_cpx_ex
as
$$
-- declare
begin
  i_left.m_arr_mid := i_left.m_arr_mid +` i_right;
  i_left.m_cnt := coalesce(i_left.m_cnt, 0) + 1;
  return i_left;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.__fv_arr_cpx_add_ex(row(array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]], 2), array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]])

-- ---------------------
-- drop function if exists sm_sc.__fv_mx_avg_final_cpx;
create or replace function sm_sc.__fv_mx_avg_final_cpx
(
  i_ret_mid      sm_sc.__typ_arr_cpx_ex
)
returns sm_sc.typ_l_complex[]
as
$$
-- declare
begin
  return i_ret_mid.m_arr_mid / (i_ret_mid.m_cnt)::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.__fv_mx_avg_final_cpx(row(array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]], 2))

-- ---------------------
-- create or replace aggregate sm_sc.fa_mx_avg (sm_sc.typ_l_complex[])
drop aggregate if exists sm_sc.fa_mx_avg (sm_sc.typ_l_complex[]);
create aggregate sm_sc.fa_mx_avg (sm_sc.typ_l_complex[])
(
  sfunc = sm_sc.__fv_arr_cpx_add_ex,
  stype = sm_sc.__typ_arr_cpx_ex,
  initcond = '("{{""(0.0, 0.0)""}}",0)',
  finalfunc = sm_sc.__fv_mx_avg_final_cpx,
  parallel = safe
);

-- select sm_sc.fa_mx_avg(a_val)
-- from 
-- (
--   select array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]] as a_val
--   union all select array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]]
--   union all select array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]]
--   union all select array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]]
--   union all select array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_inner_prod (anyarray)
drop aggregate if exists sm_sc.fa_mx_inner_prod (anyarray);
create aggregate sm_sc.fa_mx_inner_prod (anyarray)
(
  sfunc = sm_sc.fv_opr_mul,
  stype = anyarray,
  initcond = '{}',
  finalfunc = sm_sc.fv_aggr_slice_sum,
  parallel = safe
);

-- select sm_sc.fa_mx_inner_prod(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
--   union all select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_max (anyarray)
drop aggregate if exists sm_sc.fa_mx_max (anyarray);
create aggregate sm_sc.fa_mx_max (anyarray)
(
  sfunc = sm_sc.fv_opr_greatest,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_max(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[11.2, 21.5, 31.8], array[1.2, 1.5, 1.8]]
--   union all select array[array[31.2, 1.5, 21.8], array[61.2, -11.5, 111.8]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_min (anyarray)
drop aggregate if exists sm_sc.fa_mx_min (anyarray);
create aggregate sm_sc.fa_mx_min (anyarray)
(
  sfunc = sm_sc.fv_opr_least,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_min(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[11.2, 21.5, 31.8], array[1.2, 1.5, 1.8]]
--   union all select array[array[31.2, 1.5, 21.8], array[61.2, -11.5, 111.8]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace function sm_sc.__fv_array_concat_1d
-- drop function if exists sm_sc.__fv_array_concat_1d(anyarray, anyarray);
create or replace function sm_sc.__fv_array_concat_1d
(
  i_left        anyarray,
  l_right       anyarray
)
returns anyarray
as
$$
begin
  if coalesce(array_ndims(i_left), 1) = 1 and coalesce(array_ndims(l_right), 1) = 1
  then
    return i_left || l_right;
  else
    raise exception 'no support n-d array!';
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- create or replace aggregate sm_sc.fa_array_concat (anyarray)
drop aggregate if exists sm_sc.fa_array_concat (anyarray);
create aggregate sm_sc.fa_array_concat (anyarray)
(
  sfunc = sm_sc.__fv_array_concat_1d,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_array_concat(a_val)
-- from 
-- (
--   select array[1.2, 1.5, 1.8] as a_val
--   union all select array[11.2, 21.5, 31.8]
--   union all select array[31.2, 1.5, 21.8]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_concat_y (anyarray)
drop aggregate if exists sm_sc.fa_mx_concat_y (anyarray);
create aggregate sm_sc.fa_mx_concat_y (anyarray)
(
  sfunc = sm_sc.fv_concat_y,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_concat_y(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[11.2, 21.5, 31.8], array[1.2, 1.5, 1.8]]
--   union all select array[array[31.2, 1.5, 21.8], array[61.2, -11.5, 111.8]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_concat_x (anyarray)
drop aggregate if exists sm_sc.fa_mx_concat_x (anyarray);
create aggregate sm_sc.fa_mx_concat_x (anyarray)
(
  sfunc = sm_sc.fv_concat_x,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_concat_x(a_val)
-- from 
-- (
--   select array[array[1.2, 1.5, 1.8], array[11.2, 11.5, 11.8]] as a_val
--   union all select array[array[11.2, 21.5, 31.8], array[1.2, 1.5, 1.8]]
--   union all select array[array[31.2, 1.5, 21.8], array[61.2, -11.5, 111.8]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_concat_x3 (anyarray)
drop aggregate if exists sm_sc.fa_mx_concat_x3 (anyarray);
create aggregate sm_sc.fa_mx_concat_x3 (anyarray)
(
  sfunc = sm_sc.fv_concat_x3,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_concat_x3(a_val)
-- from 
-- (
--   select array[[[1.2, 1.5], [-1.5, 1.8]], [[11.2, -11.5], [11.8, -11.8]]] as a_val union all 
--   select array[[[11.2, -11.2], [21.5, 31.8]], [[-1.2, 1.5], [-1.8, 1.5]]] union all 
--   select array[[[31.2, 1.5], [-21.8, 21.8]], [[61.2, -11.5], [-61.2, 111.8]]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_concat_x4 (anyarray)
drop aggregate if exists sm_sc.fa_mx_concat_x4 (anyarray);
create aggregate sm_sc.fa_mx_concat_x4 (anyarray)
(
  sfunc = sm_sc.fv_concat_x4,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_concat_x4(a_val)
-- from 
-- (
--   select array[[[[1.2, 1.5, 1.8], [11.2, 11.5, 11.8]]]] as a_val union all 
--   select array[[[[11.2, 21.5, 31.8], [1.2, 1.5, 1.8]]]] union all 
--   select array[[[[31.2, 1.5, 21.8], [61.2, -11.5, 111.8]]]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_concat_per_ele (anyarray)
drop aggregate if exists sm_sc.fa_mx_concat_per_ele (anyarray);
create aggregate sm_sc.fa_mx_concat_per_ele (anyarray)
(
  sfunc = sm_sc.fv_opr_concat,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_concat_per_ele(a_val)
-- from 
-- (
--   select array[array[B'110', B'100', B'101'], array[B'101', B'1010', B'100']] as a_val
--   union all select array[array[B'1010', B'110', B'1010'], array[B'010', B'1010', B'110']]
--   union all select array[array[B'1010', B'10', B'1010'], array[B'10', B'101001010', B'00010']]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_or (varbit[])
drop aggregate if exists sm_sc.fa_mx_or (varbit[]);
create aggregate sm_sc.fa_mx_or (varbit[])
(
  sfunc = sm_sc.fv_opr_or,
  stype = varbit[],
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_or(a_val)
-- from 
-- (
--   select array[array[B'1101', B'100', B'101'], array[B'10', B'100101010', B'10010']] as a_val
--   union all select array[array[B'1010', B'110', B'100'], array[B'00', B'100101010', B'10010']]
--   union all select array[array[B'1010', B'101', B'010'], array[B'10', B'101001010', B'00010']]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_and (varbit[])
drop aggregate if exists sm_sc.fa_mx_and (varbit[]);
create aggregate sm_sc.fa_mx_and (varbit[])
(
  sfunc = sm_sc.fv_opr_and,
  stype = varbit[],
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_and(a_val)
-- from 
-- (
--   select array[array[B'110', B'100', B'101'], array[B'101', B'100', B'100']] as a_val
--   union all select array[array[B'101', B'110', B'101'], array[B'010', B'110', B'110']]
--   union all select array[array[B'110', B'110', B'101'], array[B'101', B'100', B'010']]
-- ) t
-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_or (boolean[])
drop aggregate if exists sm_sc.fa_mx_or (boolean[]);
create aggregate sm_sc.fa_mx_or (boolean[])
(
  sfunc = sm_sc.fv_opr_or,
  stype = boolean[],
  initcond = '{f}',
  parallel = safe
);

-- select sm_sc.fa_mx_or(a_val)
-- from 
-- (
--   select array[array[true, false, true], array[true, false, true]] as a_val
--   union all select array[array[true, false, true], array[true, false, true]]
--   union all select array[array[true, false, true], array[true, false, true]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_and (boolean[])
drop aggregate if exists sm_sc.fa_mx_and (boolean[]);
create aggregate sm_sc.fa_mx_and (boolean[])
(
  sfunc = sm_sc.fv_opr_and,
  stype = boolean[],
  initcond = '{t}',
  parallel = safe
);

-- select sm_sc.fa_mx_or(a_val)
-- from 
-- (
--   select array[array[true, false, true], array[true, false, false]] as a_val
--   union all select array[array[true, true, true], array[true, false, true]]
--   union all select array[array[false, false, true], array[false, false, true]]
-- ) t

-- -----------------------------------------------------------------------------------
-- create or replace aggregate sm_sc.fa_mx_coalesce (anyarray)
drop aggregate if exists sm_sc.fa_mx_coalesce (anyarray);
create aggregate sm_sc.fa_mx_coalesce (anyarray)
(
  sfunc = sm_sc.fv_coalesce,
  stype = anyarray,
  initcond = '{}',
  parallel = safe
);

-- select sm_sc.fa_mx_coalesce(a_val)
-- from 
-- (
--   select array[array[null, 12, null], array[14, null, 16]] as a_val
--   union all select array[array[null, 22, 23], array[null, null, 26]]
--   union all select array[array[31, 1.5, 1.8], array[11.2, 11.5, 11.8]]
-- ) t