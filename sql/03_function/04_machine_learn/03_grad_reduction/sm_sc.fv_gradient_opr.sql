-- 本函数以标量 scalar为入参/出参，数组版本参考：sm_sc.fv_lambda_arr_ddepdt_dindepdt
-- 
-- drop function if exists sm_sc.fv_gradient_opr(float, varchar(64), int, float, float);
create or replace function sm_sc.fv_gradient_opr
(
  i_indepdt_var              float                  ,
  i_fn                       varchar(64)                     ,    -- i_fn = '' and i_co_value is not null, 则恒为常数；对于 y = x, 则 i_fn 设为 ''
  i_indepdt_var_loc          int              default 1      ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 sub, div, pow, log 四种运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
  i_depdt_var                float   default null   ,    -- 非必要入参
  i_co_value                 float   default null        -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
  -- 约定：当 i_fn = '' and i_co_value is null, 表示函数: y = x;  
  --       当 i_fn = '' and i_co_value is not null, 表示函数: y = C (C 为 常数);  
)
returns float
as
$$
declare -- here
  v_sql_code  text;
  v_sql_ret   float;
  v_tmp       float;
begin

  if i_fn is null
  then 
    return null :: float;

  elsif i_fn = '' and i_co_value is not null
  then 
    return 0.0;
  -- -- -- elsif i_fn = 'sm_sc.fv_opr_const'
  -- -- -- then 
  -- -- --   return 0.0;

  -- if 判断覆盖到的 fn, 不需要查表，性能稍好
  elsif i_fn = 'sm_sc.fv_opr_add' 
    or i_fn = '' and i_co_value is null
  then 
    return 1.0;
  elsif i_fn = 'sm_sc.fv_opr_mul'
  then 
    return i_co_value;
  elsif i_fn = 'sm_sc.fv_opr_sub'
  then 
    return
      case i_indepdt_var_loc 
        when 1 
          then 1.0
        when 2 
          then -1.0
      end;
  elsif i_fn = 'sm_sc.fv_opr_div'
  then 
    return
      case i_indepdt_var_loc 
        when 1 
          then 1.0 :: float/ nullif(i_co_value, 0.0 :: float)
        when 2 
          then - i_co_value / nullif(power(i_indepdt_var, 2), 0.0 :: float)
      end;
  elsif i_fn = 'sm_sc.fv_opr_pow'
  then 
    return
      case i_indepdt_var_loc 
        when 1 
          then -- 优先使用 i_depdt_var 减小算法复杂度 -- -- i_co_value * power(i_indepdt_var, i_co_value - 1)
            case 
              when i_depdt_var is not null and i_indepdt_var <> 0.0
                then i_co_value * i_depdt_var / nullif(i_indepdt_var, 0.0 :: float)
              else i_co_value * power(i_indepdt_var, i_co_value - 1)
            end
        when 2 
          then -- 优先使用 i_depdt_var 减小算法复杂度 -- -- power(i_co_value, i_indepdt_var) * ln(i_co_value)
            case
              when i_depdt_var is not null
                then i_depdt_var * ln(i_co_value)
              else power(i_co_value, i_indepdt_var) * ln(i_co_value)
            end
      end;
  elsif i_fn = 'sm_sc.fv_opr_exp'
  then 
    return 
      case 
        when i_depdt_var is not null
          then i_depdt_var
        else exp(i_indepdt_var)
      end;
  elsif i_fn = 'sm_sc.fv_opr_log'
  then 
    return
      case i_indepdt_var_loc 
        when 1 
          then -- 优先使用 i_depdt_var 减小算法复杂度 -- -- -1.0 :: float/ (power(log(i_co_value, i_indepdt_var), 2) * i_indepdt_var * ln(i_co_value))
            case
              when i_depdt_var is not null
                then power(i_depdt_var, 2) / nullif(i_indepdt_var * ln(i_co_value), 0.0 :: float)
              else -power(log(i_indepdt_var :: decimal, i_co_value :: decimal), 2) / nullif(i_indepdt_var * ln(i_co_value :: decimal), 0.0 :: float)
            end
        when 2 
          then 1.0 :: float/ nullif(i_indepdt_var * ln(i_co_value), 0.0 :: float)
      end;
  elsif i_fn = 'sm_sc.fv_opr_ln'
  then 
    return 1.0 :: float/ i_indepdt_var;
  elsif i_fn = 'sm_sc.fv_sin'
  then 
    return cos(i_indepdt_var);
  elsif i_fn = 'sm_sc.fv_cos'
  then 
    return -sin(i_indepdt_var);
  elsif i_fn = 'sm_sc.fv_tan'
  then 
    return 1.0 :: float/ nullif(power(cos(i_indepdt_var)::float, 2), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_cot'
  then 
    return -1.0 :: float/ nullif(power(sin(i_indepdt_var)::float, 2), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_sec'
  then 
    return -- 优先使用 i_depdt_var 减小算法复杂度 -- -- tan(i_indepdt_var) / cos(i_indepdt_var);
      case
        when i_depdt_var is not null
          then i_depdt_var * tan(i_indepdt_var)
        else tan(i_indepdt_var) / nullif(cos(i_indepdt_var), 0.0 :: float)
      end;
  elsif i_fn = 'sm_sc.fv_csc'
  then 
    return -- 优先使用 i_depdt_var 减小算法复杂度 -- -- -cot(i_indepdt_var) / sin(i_indepdt_var);
      case
        when i_depdt_var is not null
          then -i_depdt_var * cot(i_indepdt_var)
        else -cot(i_indepdt_var) / nullif(sin(i_indepdt_var), 0.0 :: float)
      end;
  elsif i_fn = 'sm_sc.fv_asin'
  then 
    return 1.0 :: float/ nullif(power(1.0 :: float- power(i_indepdt_var, 2), 0.5 :: float), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_acos'
  then 
    return -1.0 :: float/ nullif(power(1.0 :: float- power(i_indepdt_var, 2), 0.5 :: float), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_atan'
  then 
    return 1.0 :: float/ nullif(1.0 :: float+ power(i_indepdt_var, 2), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_acot'
  then 
    return -1.0 :: float/ nullif(1.0 :: float+ power(i_indepdt_var, 2), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_asec'
  then 
    return 1.0 :: float/ nullif(i_indepdt_var * power(power(i_indepdt_var, 2) - 1.0 :: float, 0.5 :: float), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_acsc'
  then 
    return -1.0 :: float/ nullif(i_indepdt_var * power(power(i_indepdt_var, 2) - 1.0 :: float, 0.5 :: float), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_sinh'
  then 
    return cosh(i_indepdt_var);
  elsif i_fn = 'sm_sc.fv_cosh'
  then 
    return sinh(i_indepdt_var);
  elsif i_fn = 'sm_sc.fv_tanh'
  then 
    return -- 优先使用 i_depdt_var 减小算法复杂度 -- 1.0 :: float/ power(cosh(i_indepdt_var)::float, 2) 
      case 
        when i_depdt_var is not null 
          then 1.0 :: float- power(i_depdt_var, 2) 
        else 1.0 :: float/ nullif(power(cosh(i_indepdt_var)::float, 2), 0.0 :: float) 
      end;
  -- -- elsif i_fn = 'sm_sc.fv_coth'
  -- -- then 
  -- --   return
  -- -- elsif i_fn = 'sm_sc.fv_sech'
  -- -- then 
  -- --   return
  -- -- elsif i_fn = 'sm_sc.fv_csch'
  -- -- then 
  -- --   return
  elsif i_fn = 'sm_sc.fv_asinh'
  then 
    return 1.0 :: float/ nullif(power(power(i_indepdt_var, 2) + 1.0 :: float, 0.5 :: float), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_acosh'
  then 
    return 1.0 :: float/ nullif(power(power(i_indepdt_var, 2) - 1.0 :: float, 0.5 :: float), 0.0 :: float);
  elsif i_fn = 'sm_sc.fv_atanh'
  then 
    return 1.0 :: float/ nullif(1.0 :: float- power(i_indepdt_var, 2), 0.0 :: float);
  -- -- elsif i_fn = 'sm_sc.fv_acoth'
  -- -- then 
  -- --   return
  -- -- elsif i_fn = 'sm_sc.fv_asech'
  -- -- then 
  -- --   return
  -- -- elsif i_fn = 'sm_sc.fv_acsch'
  -- -- then 
  -- --   return
  elsif i_fn = 'sm_sc.fv_sigmoid'
  then 
    if i_depdt_var is not null  -- 优先使用 i_depdt_var 减小算法复杂度 -- 
    then 
      return i_depdt_var * (1.0 :: float- i_depdt_var);
    else
      v_tmp := nullif(exp(i_indepdt_var / 2), 0.0 :: float);
      return 1.0 :: float/ nullif(power(v_tmp + (1 / v_tmp), 2.0 :: float), 0.0 :: float);
    end if;
  -- 用户自定义函数/导数函数注册在 enum 表中，计算时查表，再动态 sql, 性能不如硬编码映射
  -- 自定义函数/导数函数只单目和双目运算（包括左目、右目），三目运算要预先分解定义为多个双目运算
  -- -- elsif exists (select from sm_sc.tb_dic_enum where enum_group = i_fn and enum_order = i_indepdt_var_loc)
  elsif exists 
  (
    select 
    from sm_sc.tb_dic_enum 
    where enum_name = 'node_fn_type'
      and enum_value = i_fn 
      -- and enum_order = i_indepdt_var_loc
    limit 1
  )
  then 
    select 
      'select ' || enum_value || '($1' || case when i_co_value is null then '' else ', $2' end || ')'
    into v_sql_code
    from sm_sc.tb_dic_enum 
    where enum_value = i_fn
    limit 1
    ;
-- raise notice 'debug: v_sql_code: %', v_sql_code;
    execute v_sql_code into v_sql_ret using case when i_indepdt_var_loc = 1 then i_indepdt_var else i_co_value end, case when i_indepdt_var_loc = 1 then i_co_value else i_indepdt_var end;

    return v_sql_ret;
  else 
    raise exception 'unknown function!';
  end if;

end
$$
language plpgsql volatile
cost 100;

-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   null :: varchar(64)           ,
-- --   1               ,
-- --   null            ,
-- --   null :: float
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   ''              ,
-- --   1               ,
-- --   null            ,
-- --   null :: float
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   ''              ,
-- --   1               ,
-- --   null            ,
-- --   12
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_opr_add'        -- ,
-- --   -- 0               ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_opr_mul'        ,
-- --   0               ,
-- --   null            ,
-- --   2.3
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_opr_sub'        ,
-- --   1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_opr_sub'        ,
-- --   2               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_opr_div'        ,
-- --   1               ,
-- --   null            ,
-- --   1.5
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_opr_div'        ,
-- --   2               ,
-- --   null            ,
-- --   1.5
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_pow'        ,
-- --   1               ,
-- --   power(2.0 :: float, 3.0) :: float ,
-- --   3.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_pow'        ,
-- --   1               ,
-- --   null            ,
-- --   3.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_pow'        ,
-- --   2               ,
-- --   power(3.0, 2.0 :: float) :: float,
-- --   3.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_pow'        ,
-- --   2               ,
-- --   null            ,
-- --   3.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_exp'        -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_exp'        ,
-- --   1               ,
-- --   exp(2.0 :: float)::float  -- ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_log'        ,
-- --   1               ,
-- --   log(2.0, 8.0)::float   ,
-- --   8.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_opr_log'        ,
-- --   1               ,
-- --   null            ,
-- --   8.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   8.0             ,
-- --   'sm_sc.fv_opr_log'        ,
-- --   2               ,
-- --   null            ,
-- --   2.0
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   5.0             ,
-- --   'sm_sc.fv_opr_ln'         -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   pi()::float / 2.0      ,
-- --   'sm_sc.fv_sin'        ,
-- --   1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   pi()::float / 2.0      ,
-- --   'sm_sc.fv_cos'        ,
-- --   1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -pi()::float / 3.0     ,
-- --   'sm_sc.fv_tan'        -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -pi()::float / 3.0     ,
-- --   'sm_sc.fv_cot'        -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -pi():: float / 6.0      ,
-- --   'sm_sc.fv_sec'        -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -pi():: float / 6.0      ,
-- --   'sm_sc.fv_sec'           ,
-- --   1                  ,
-- --   1.0 :: float/ cos(-pi() / 6.0) :: float  -- ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -pi() :: float / 3.0     ,
-- --   'sm_sc.fv_csc'        -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -pi() :: float / 3.0     ,
-- --   'sm_sc.fv_csc'        ,
-- --   1               ,
-- --   1.0 :: float/ sin(-pi() / 3.0) :: float  -- ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -0.5            ,
-- --   'sm_sc.fv_asin'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -0.5            ,
-- --   'sm_sc.fv_acos'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_atan'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -0.5            ,
-- --   'sm_sc.fv_acot'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.5             ,
-- --   'sm_sc.fv_asec'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   -1.5            ,
-- --   'sm_sc.fv_acsc'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_sinh'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_cosh'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_tanh'       -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   1.0 :: float            ,
-- --   'sm_sc.fv_tanh'       ,
-- --   1               ,
-- --   tanh(1.0 :: float)::float  -- ,
-- --   -- null
-- -- );
-- -- -- select sm_sc.fv_gradient_opr
-- -- -- (
-- -- --   1.0 :: float            ,
-- -- --   'sm_sc.fv_coth'       -- ,
-- -- --   -- 1               -- ,
-- -- --   -- null            ,
-- -- --   -- null
-- -- -- );
-- -- -- select sm_sc.fv_gradient_opr
-- -- -- (
-- -- --   1.0 :: float            ,
-- -- --   'sm_sc.fv_sech'       -- ,
-- -- --   -- 1               -- ,
-- -- --   -- null            ,
-- -- --   -- null
-- -- -- );
-- -- -- select sm_sc.fv_gradient_opr
-- -- -- (
-- -- --   1.0 :: float            ,
-- -- --   'sm_sc.fv_csch'       -- ,
-- -- --   -- 1               -- ,
-- -- --   -- null            ,
-- -- --   -- null
-- -- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   3.5             ,
-- --   'sm_sc.fv_asinh'      -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   3.5             ,
-- --   'sm_sc.fv_acosh'      -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   3.5             ,
-- --   'sm_sc.fv_atanh'      -- ,
-- --   -- 1               -- ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- -- select sm_sc.fv_gradient_opr
-- -- -- (
-- -- --   1.0 :: float            ,
-- -- --   'sm_sc.fv_acoth'      -- ,
-- -- --   -- 1               -- ,
-- -- --   -- null            ,
-- -- --   -- null
-- -- -- );
-- -- -- select sm_sc.fv_gradient_opr
-- -- -- (
-- -- --   1.0 :: float            ,
-- -- --   'sm_sc.fv_asech'      -- ,
-- -- --   -- 1               -- ,
-- -- --   -- null            ,
-- -- --   -- null
-- -- -- );
-- -- -- select sm_sc.fv_gradient_opr
-- -- -- (
-- -- --   1.0 :: float            ,
-- -- --   'sm_sc.fv_acsch'      ,
-- -- --   1               -- ,
-- -- --   -- null            ,
-- -- --   -- null
-- -- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_sigmoid'    -- ,
-- --   -- 1               ,
-- --   -- null            ,
-- --   -- null
-- -- );
-- -- select sm_sc.fv_gradient_opr
-- -- (
-- --   2.0             ,
-- --   'sm_sc.fv_sigmoid'    ,
-- --   1               ,
-- --   1.0 :: float/ (1.0 :: float+ exp(-2.0 :: float))::float -- ,
-- --   -- null
-- -- );

-- select sm_sc.fv_gradient_opr
-- (
--   2.0             ,
--   'sm_sc.fv_softplus'    -- ,
--   -- 1               ,
--   -- null ,
--   -- null
-- );
-- select sm_sc.fv_gradient_opr
-- (
--   2.0             ,
--   'sm_sc.fv_leaky_relu'    ,
--   1               ,
--   null ,
--   0.3
-- );

-- ---------------------------------------------------------------------------
-- 标量 scalar
-- 支持多目运算符
-- drop function if exists sm_sc.fv_gradient_opr(float, varchar(64), int, float, float[]);
create or replace function sm_sc.fv_gradient_opr
(
  i_indepdt_var              float                  ,
  i_fn                     varchar(64)                     ,    -- i_fn = '' and i_co_value is not null, 则恒为常数；对于 y = x, 则 i_fn 设为 ''
  i_indepdt_var_loc          int                             ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 sub, div, pow, log 四种运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
  i_depdt_var            float                  ,    -- 非必要入参
  i_co_values              float[]                     -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
  -- 约定：当 i_fn = '' and i_co_value is null, 表示函数: y = x;  
  --       当 i_fn = '' and i_co_value is not null, 表示函数: y = C (C 为 常数);  
)
returns float
as
$$
-- declare
begin
  if coalesce(array_length(i_co_values, 1), 0) < 2
  then 
    return sm_sc.fv_gradient_opr(i_indepdt_var, i_fn, i_indepdt_var_loc, i_depdt_var, i_co_values[1])
    ;
  else
    if i_fn = 'sm_sc.fv_opr_add'
    then
      return 1.0;                                           
    elsif i_fn = 'sm_sc.fv_opr_mul'             
    then                                          
      return 
        case 
          when array_length(i_co_values, 1) > 3 and i_indepdt_var <> 0.0 and i_depdt_var is not null
            then i_depdt_var / nullif(i_indepdt_var, 0.0 :: float)
          else sm_sc.fv_aggr_slice_prod(i_co_values)
        end
      ;
    else
      raise exception 'unknown function: % for such co_params!', i_fn;
    end if;
  end if;
end
$$
language plpgsql stable
cost 100;


-- select sm_sc.fv_gradient_opr
-- (
--   1.0 :: float            ,
--   'sm_sc.fv_opr_add'        ,
--   0               ,
--   null            ,
--   array[1.5, 2.5]
-- );

-- select sm_sc.fv_gradient_opr
-- (
--   1.0 :: float            ,
--   'sm_sc.fv_opr_mul'        ,
--   0               ,
--   null            ,
--   array[1.5, 2.5]
-- );

-- select sm_sc.fv_gradient_opr
-- (
--   2.0             ,
--   'sm_sc.fv_opr_div'    ,
--   1               ,
--   null ,
--   array[1.6]
-- );