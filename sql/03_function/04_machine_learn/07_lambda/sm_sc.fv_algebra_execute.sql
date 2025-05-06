-- -- 动态执行代数式/函数式的字符串，返回计算数值结果，用于推导，不适用于高性能计算
-- drop function if exists sm_sc.fv_algebra_execute(text);
create or replace function sm_sc.fv_algebra_execute
(
  i_algebra_sql     text
)
returns float
as
$$
declare -- here
  v_ret    float;
begin
  execute ('select (' || i_algebra_sql || '):: float') into v_ret;
  return v_ret;
end
$$
language plpgsql stable
cost 100;

-- select sm_sc.fv_algebra_execute('2.5 + 3.6')
-- select sm_sc.fv_algebra_execute('(2.5 + 3.6)')

-- ---------------------------------------------------------------------------------------------
-- 函数式方式的数学计算
-- drop function if exists sm_sc.fv_algebra_execute(varchar(64), float[]);
create or replace function sm_sc.fv_algebra_execute
(
  i_fn           varchar(64)   ,
  i_fn_params    float[]
)
returns float
as
$$
begin
  -- -- return
  -- --   case i_fn
  -- --     when 'sm_sc.fv_opr_add'    then sm_sc.fv_aggr_slice_sum_py(i_fn_params)         :: float
  -- --     when 'sm_sc.fv_opr_sub'    then i_fn_params[1] - i_fn_params[2]                :: float
  -- --     when 'sm_sc.fv_opr_mul'    then sm_sc.fv_aggr_slice_prod(i_fn_params)        :: float
  -- --     when 'sm_sc.fv_opr_div'    then i_fn_params[1] / nullif(i_fn_params[2], 0.0 :: float)   :: float
  -- --     when 'sm_sc.fv_opr_pow'    then power(i_fn_params[1], i_fn_params[2])          :: float
  -- --     when 'sm_sc.fv_opr_exp'    then exp(i_fn_params[1])                            :: float
  -- --     when 'sm_sc.fv_opr_log'    then log(i_fn_params[1] :: decimal, i_fn_params[2] :: decimal)    :: float
  -- --     when 'sm_sc.fv_opr_ln'     then ln(i_fn_params[1])                             :: float
  -- --     when 'sm_sc.fv_sin'        then sin(i_fn_params[1])                            :: float
  -- --     when 'sm_sc.fv_cos'        then cos(i_fn_params[1])                            :: float
  -- --     when 'sm_sc.fv_tan'        then tan(i_fn_params[1])                            :: float
  -- --     when 'sm_sc.fv_cot'        then cot(i_fn_params[1])                            :: float
  -- --     when 'sm_sc.fv_sec'        then 1.0 :: float/ nullif(cos(i_fn_params[1]), 0.0 :: float)         :: float
  -- --     when 'sm_sc.fv_csc'        then 1.0 :: float/ nullif(sin(i_fn_params[1]), 0.0 :: float)         :: float
  -- --     when 'sm_sc.fv_asin'       then asin(i_fn_params[1])                           :: float
  -- --     when 'sm_sc.fv_acos'       then acos(i_fn_params[1])                           :: float
  -- --     when 'sm_sc.fv_atan'       then atan(i_fn_params[1])                           :: float
  -- --     when 'sm_sc.fv_acot'       then atan(1.0 :: float/ nullif(i_fn_params[1], 0.0 :: float))        :: float
  -- --     when 'sm_sc.fv_asec'       then acos(1.0 :: float/ nullif(i_fn_params[1], 0.0 :: float))        :: float
  -- --     when 'sm_sc.fv_acsc'       then asin(1.0 :: float/ nullif(i_fn_params[1], 0.0 :: float))        :: float
  -- --     when 'sm_sc.fv_sinh'       then sinh(i_fn_params[1])                           :: float
  -- --     when 'sm_sc.fv_cosh'       then cosh(i_fn_params[1])                           :: float
  -- --     when 'sm_sc.fv_tanh'       then tanh(i_fn_params[1])                           :: float
  -- --     when 'sm_sc.fv_asinh'      then asinh(i_fn_params[1])                          :: float
  -- --     when 'sm_sc.fv_acosh'      then acosh(i_fn_params[1])                          :: float
  -- --     when 'sm_sc.fv_atanh'      then atanh(i_fn_params[1])                          :: float
  -- --     else i_fn_params[1]
  -- --   end
  -- -- ;
  if i_fn = 'sm_sc.fv_opr_add'
  then 
    return sm_sc.fv_aggr_slice_sum_py(i_fn_params);
  elsif i_fn = 'sm_sc.fv_opr_sub'
  then 
    return i_fn_params[1] - i_fn_params[2];
  elsif i_fn = 'sm_sc.fv_opr_mul'
  then 
    return sm_sc.fv_aggr_slice_prod(i_fn_params);
  elsif i_fn = 'sm_sc.fv_opr_div'
  then 
    return i_fn_params[1] / nullif(i_fn_params[2], 0.0);
  elsif i_fn = 'sm_sc.fv_opr_pow'
  then 
    return power(i_fn_params[1], i_fn_params[2]);
  elsif i_fn = 'sm_sc.fv_opr_exp'
  then 
    return exp(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_opr_log'
  then 
    return log(i_fn_params[1] :: decimal, i_fn_params[2] :: decimal);
  elsif i_fn = 'sm_sc.fv_opr_ln'
  then 
    return ln(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_sin'
  then 
    return sin(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_cos'
  then 
    return cos(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_tan'
  then 
    return tan(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_cot'
  then 
    return cot(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_sec'
  then 
    return 1.0 / nullif(cos(i_fn_params[1]), 0.0);
  elsif i_fn = 'sm_sc.fv_csc'
  then 
    return 1.0 / nullif(sin(i_fn_params[1]), 0.0);
  elsif i_fn = 'sm_sc.fv_asin'
  then 
    return asin(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_acos'
  then 
    return acos(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_atan'
  then 
    return atan(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_acot'
  then 
    return atan(1.0 / nullif(i_fn_params[1], 0.0));
  elsif i_fn = 'sm_sc.fv_asec'
  then 
    return acos(1.0 / nullif(i_fn_params[1], 0.0));
  elsif i_fn = 'sm_sc.fv_acsc'
  then 
    return asin(1.0 / nullif(i_fn_params[1], 0.0));
  elsif i_fn = 'sm_sc.fv_sinh'
  then 
    return sinh(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_cosh'
  then 
    return cosh(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_tanh'
  then 
    return tanh(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_asinh'
  then 
    return asinh(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_acosh'
  then 
    return acosh(i_fn_params[1]);
  elsif i_fn = 'sm_sc.fv_atanh'
  then 
    return atanh(i_fn_params[1]);
  else 
    return i_fn_params[1];
  end if;
end
$$
language plpgsql stable
cost 100;


-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_add'   , array[1.5, 2.0 :: float, 3.4])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_sub'   , array[1.5, 2.0])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_mul'   , array[1.5, 2.0 :: float, 3.4])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_div'   , array[1.5, 2.0])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_pow'   , array[1.5, 2.0])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_exp'   , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_log'   , array[1.5, 2.0])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_opr_ln'    , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_sin'       , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_cos'       , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_tan'       , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_cot'       , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_sec'       , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_csc'       , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_asin'      , array[0.5 :: float])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_acos'      , array[0.5 :: float])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_atan'      , array[0.5 :: float])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_acot'      , array[0.5 :: float])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_asec'      , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_acsc'      , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_sinh'      , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_cosh'      , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_tanh'      , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_asinh'     , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_acosh'     , array[1.5])
-- select sm_sc.fv_algebra_execute('sm_sc.fv_atanh'     , array[0.5 :: float])