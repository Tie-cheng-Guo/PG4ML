-- 1. 定义类型
drop type if exists sm_sc.typ_l_complex;
create type sm_sc.typ_l_complex as
(
  m_re         float,
  m_im         float
);

-- 2. 定义类型转换 --
-- 2.1. float
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_float_to_typ_l_complex(float);
create or replace function sm_sc.fv_cast_float_to_typ_l_complex
(
  i_re      float
)
returns sm_sc.typ_l_complex
as
$$
begin
  return (i_re, 0.0)::sm_sc.typ_l_complex;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_float_to_typ_l_complex(32.6 :: float)
-- ------------------------------------------------------------------------
drop cast if exists (float as sm_sc.typ_l_complex);
create cast (float as sm_sc.typ_l_complex) with function sm_sc.fv_cast_float_to_typ_l_complex(float) as implicit;
-- select 32.5 :: float :: sm_sc.typ_l_complex
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_typ_l_complex_to_float(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_cast_typ_l_complex_to_float
(
  i_complex      sm_sc.typ_l_complex
)
returns float
as
$$
begin
  if i_complex.m_im = 0.0
  then
    return i_complex.m_re;
  else
    raise exception 'error!  can''t cast complex number to real number, while m_im of the complex number <> 0.0! ';
  end if;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_typ_l_complex_to_float((32.6 :: float, -56.2 :: float)::sm_sc.typ_l_complex)
-- select sm_sc.fv_cast_typ_l_complex_to_float((32.6 :: float, 0 :: float)::sm_sc.typ_l_complex)
-- ------------------------------------------------------------------------
drop cast if exists (sm_sc.typ_l_complex as float);
create cast (sm_sc.typ_l_complex as float) with function sm_sc.fv_cast_typ_l_complex_to_float(sm_sc.typ_l_complex) as assignment;
-- -- select (32.5 :: float, 54.2 :: float)::sm_sc.typ_l_complex::float
-- select (32.5 :: float, 0 :: float)::sm_sc.typ_l_complex::float
-- ------------------------------------------------------------------------
-- 2.2. decimal
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_decimal_to_typ_l_complex(decimal);
create or replace function sm_sc.fv_cast_decimal_to_typ_l_complex
(
  i_re      decimal
)
returns sm_sc.typ_l_complex
as
$$
begin
  return (i_re, 0.0)::sm_sc.typ_l_complex;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_decimal_to_typ_l_complex(32.6 :: decimal)
-- ------------------------------------------------------------------------
drop cast if exists (decimal as sm_sc.typ_l_complex);
create cast (decimal as sm_sc.typ_l_complex) with function sm_sc.fv_cast_decimal_to_typ_l_complex(decimal) as implicit;
-- select 32.5 :: decimal :: sm_sc.typ_l_complex
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_typ_l_complex_to_decimal(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_cast_typ_l_complex_to_decimal
(
  i_complex      sm_sc.typ_l_complex
)
returns decimal
as
$$
begin
  if i_complex.m_im = 0.0
  then
    return i_complex.m_re;
  else
    raise exception 'error!  can''t cast complex number to real number, while m_im of the complex number <> 0.0! ';
  end if;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_typ_l_complex_to_decimal((32.6 :: decimal, -56.2 :: decimal)::sm_sc.typ_l_complex)
-- select sm_sc.fv_cast_typ_l_complex_to_decimal((32.6 :: decimal, 0 :: decimal)::sm_sc.typ_l_complex)
-- ------------------------------------------------------------------------
drop cast if exists (sm_sc.typ_l_complex as decimal);
create cast (sm_sc.typ_l_complex as decimal) with function sm_sc.fv_cast_typ_l_complex_to_decimal(sm_sc.typ_l_complex) as assignment;
-- -- select (32.5 :: decimal, 54.2 :: decimal)::sm_sc.typ_l_complex::decimal
-- select (32.5 :: decimal, 0 :: decimal)::sm_sc.typ_l_complex::decimal
-- ------------------------------------------------------------------------
-- 2.3. bigint
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_bigint_to_typ_l_complex(bigint);
create or replace function sm_sc.fv_cast_bigint_to_typ_l_complex
(
  i_re      bigint
)
returns sm_sc.typ_l_complex
as
$$
begin
  return (i_re, 0.0)::sm_sc.typ_l_complex;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_bigint_to_typ_l_complex(32 :: bigint)
-- ------------------------------------------------------------------------
drop cast if exists (bigint as sm_sc.typ_l_complex);
create cast (bigint as sm_sc.typ_l_complex) with function sm_sc.fv_cast_bigint_to_typ_l_complex(bigint) as implicit;
-- select 32 :: bigint:: sm_sc.typ_l_complex
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_typ_l_complex_to_bigint(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_cast_typ_l_complex_to_bigint
(
  i_complex      sm_sc.typ_l_complex
)
returns bigint
as
$$
begin
  if i_complex.m_im = 0.0
  then
    return i_complex.m_re;
  else
    raise exception 'error!  can''t cast complex number to real number, while m_im of the complex number <> 0.0! ';
  end if;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_typ_l_complex_to_bigint((32 :: bigint, -56 :: bigint)::sm_sc.typ_l_complex)
-- select sm_sc.fv_cast_typ_l_complex_to_bigint((32 :: bigint, 0 :: bigint)::sm_sc.typ_l_complex)
-- ------------------------------------------------------------------------
drop cast if exists (sm_sc.typ_l_complex as bigint);
create cast (sm_sc.typ_l_complex as bigint) with function sm_sc.fv_cast_typ_l_complex_to_bigint(sm_sc.typ_l_complex) as assignment;
-- -- select (32 :: bigint, 54 :: bigint)::sm_sc.typ_l_complex::bigint
-- select (32 :: bigint, 0)::sm_sc.typ_l_complex::bigint
-- ------------------------------------------------------------------------
-- 2.4. int
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_int_to_typ_l_complex(int);
create or replace function sm_sc.fv_cast_int_to_typ_l_complex
(
  i_re      int
)
returns sm_sc.typ_l_complex
as
$$
begin
  return (i_re, 0.0)::sm_sc.typ_l_complex;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_int_to_typ_l_complex(32 :: int)
-- ------------------------------------------------------------------------
drop cast if exists (int as sm_sc.typ_l_complex);
create cast (int as sm_sc.typ_l_complex) with function sm_sc.fv_cast_int_to_typ_l_complex(int) as implicit;
-- select 32 :: int:: sm_sc.typ_l_complex
-- ------------------------------------------------------------------------
drop function if exists sm_sc.fv_cast_typ_l_complex_to_int(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_cast_typ_l_complex_to_int
(
  i_complex      sm_sc.typ_l_complex
)
returns int
as
$$
begin
  if i_complex.m_im = 0.0
  then
    return i_complex.m_re;
  else
    raise exception 'error!  can''t cast complex number to real number, while m_im of the complex number <> 0.0! ';
  end if;
end
$$
language plpgsql volatile
cost 100;
-- select sm_sc.fv_cast_typ_l_complex_to_int((32 :: int, -56 :: int)::sm_sc.typ_l_complex)
-- select sm_sc.fv_cast_typ_l_complex_to_int((32 :: int, 0 :: int)::sm_sc.typ_l_complex)
-- ------------------------------------------------------------------------
drop cast if exists (sm_sc.typ_l_complex as int);
create cast (sm_sc.typ_l_complex as int) with function sm_sc.fv_cast_typ_l_complex_to_int(sm_sc.typ_l_complex) as assignment;
-- -- select (32 :: int, 54 :: int)::sm_sc.typ_l_complex::int
-- select (32 :: int, 0)::sm_sc.typ_l_complex::int
-- ------------------------------------------------------------------------