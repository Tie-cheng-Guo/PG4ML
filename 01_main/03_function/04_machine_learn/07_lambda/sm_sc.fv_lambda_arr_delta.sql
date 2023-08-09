-- 本函数以数组为入参，标量版本参考 sm_sc.fv_gradient_opr
-- 对于 conv_2d, pool_max, pool_avg, softmax, zscore 本函数无法求取 ddepdt/dindepdt，参看 sm_sc.fv_lambda_arr_dloss_dindepdt 求取 dloss/dindepdt
-- drop function if exists sm_sc.fv_lambda_arr_delta(bigint, varchar(64), float[][], int, float[][], float[][], float[][], int[2]);
create or replace function sm_sc.fv_lambda_arr_delta
(
  i_node_no  bigint,
  i_lambda                varchar(64)                       ,
  i_indepdt_var           float[][]                ,
  i_indepdt_var_loc       int                default 1      ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 prod_mx, sub, div, pow, log 等运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
  i_co_value              float[][] default null   ,    -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
  i_input_arr_asso   float[]   default null   ,    
  i_depdt_var             float[][] default null   ,    -- 前向的因变量，非必要入参
  -- i_dloss_ddepdt          float[][] default null   ,    -- 此入参传入 dloss/ddepdt, 用于 反向传播阶段 求取 dloss/dindepdt
  i_indepdt_var_len       int[2]             default null        -- 自变量的高宽规格，agg_concat_x, agg_concat_y, agg_sum, agg_avg, slice_x, slice_y, add, sub 会用到该参数，以避免传参 i_indepdt_var，从而降低堆区开销
)
returns float[][]
as
$$
declare 
  _v_debug         float[][];
begin
  i_indepdt_var_len := coalesce(i_indepdt_var_len, array[array_length(i_indepdt_var, 1), array_length(i_indepdt_var, 2)]);
-- -- debug
-- raise notice '
-- sm_sc.fv_lambda_arr_delta debug :
--   i_lambda                : %; 
--   i_indepdt_var           : %; 
--   i_indepdt_var_loc       : %; 
--   i_co_value              : %; 
--   i_input_arr_asso   : %; 
--   i_depdt_var           : %; 
-- ', $1, $2, $3, $4, $5, $6
-- ;

-- -- debug 
-- raise notice 'lambda_delta % begin:: i_lambda: %; len_input: %; len_co_val: %; indepdt_var_loc: %; time: %;'
-- , i_node_no, i_lambda, array[array_length(i_indepdt_var, 1), array_length(i_indepdt_var, 2)], array[array_length(i_co_value, 1), array_length(i_co_value, 2)], i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');

  if 'NaN' :: float = any(i_indepdt_var)
    or 'NaN' :: float = any(i_co_value)
    or 'NaN' :: float = any(i_depdt_var)
  then 
    raise exception 'there is NaN value in i_indepdt_var, i_co_value or i_depdt_var!  i_node_no: %.  ', i_node_no;
  end if;
  
  _v_debug := 

  -- return  
    case i_lambda
      -- when 'agg_concat_x'
      --   then array_fill(1.0 :: float, i_indepdt_var_len)
      -- when 'agg_concat_y'
      --   then array_fill(1.0 :: float, i_indepdt_var_len)
      when 'agg_sum'
        then array_fill(1.0 :: float, i_indepdt_var_len)
      when 'agg_avg'
        then array_fill(1.0 :: float/ i_input_arr_asso[1], i_indepdt_var_len)
      when 'agg_max'    -- 反向传递时候，要用i_depdt_var 对应该 path(i_indepdt_var_loc) 得 1.0，其余位置得 0.0
        then (i_depdt_var ==` i_indepdt_var)::int[]::float[]
      when 'agg_min'    -- 反向传递时候，要用i_depdt_var 对应该 path(i_indepdt_var_loc) 得 1.0，其余位置得 0.0
        then (i_depdt_var ==` i_indepdt_var)::int[]::float[]
      when 'agg_prod'    -- 反向传递时候，要用i_depdt_var 逐个 path_no 除回去该 path(i_indepdt_var_loc) 对应的 i_indepdt_var
        then i_depdt_var /` i_indepdt_var
      when 'prod_mx'
        then 
          case i_indepdt_var_loc 
            when 1 then i_co_value 
            when 2 then |^~| i_co_value
          end
      when 'sigmoid'
        then sm_sc.fv_d_activate_sigmoid(i_indepdt_var, i_depdt_var)           -- 如果i_depdt_var传值, i_indepdt_var就传 null
      -- 对于 softmax 本函数求取 dloss/dindepdt, 而不是求取 ddepdt/dindepdt
      when 'relu'
        then sm_sc.fv_d_activate_relu(i_indepdt_var)
      when 'elu'
        then sm_sc.fv_d_activate_elu(i_indepdt_var, i_input_arr_asso[1])
      when 'leaky_relu'
        then sm_sc.fv_d_activate_leaky_relu(i_indepdt_var, i_input_arr_asso[1])
      when 'selu'
        then sm_sc.fv_d_activate_selu(i_indepdt_var)
      when 'gelu'
        then sm_sc.fv_d_activate_gelu(i_indepdt_var)
      when 'softplus'
        then sm_sc.fv_d_activate_softplus(i_indepdt_var)
      when 'swish'
        then sm_sc.fv_d_activate_swish(i_indepdt_var)
      when 'slice_x'
        then
          sm_sc.fv_new
          (
            0.0
            , array[i_indepdt_var_len[1], i_input_arr_asso[1] :: int - 1] 
          )
          |||| 
          sm_sc.fv_new
          (
            0.0
            , array[i_indepdt_var_len[1], coalesce(i_input_arr_asso[2], i_input_arr_asso[1]) :: int - i_input_arr_asso[1] :: int + 1] 
          )
          |||| 
          sm_sc.fv_new
          (
            0.0
            , array[i_indepdt_var_len[1], i_indepdt_var_len[2] - coalesce(i_input_arr_asso[2], i_input_arr_asso[1]) :: int] 
          )
      when 'slice_y'
        then
          sm_sc.fv_new
          (
            0.0
            , array[i_input_arr_asso[1] :: int - 1, i_indepdt_var_len[2]] 
          )
          |-|| 
          sm_sc.fv_new
          (
            0.0
            , array[coalesce(i_input_arr_asso[2], i_input_arr_asso[1]) :: int - i_input_arr_asso[1] :: int + 1, i_indepdt_var_len[2]] 
          )
          |-|| 
          sm_sc.fv_new
          (
            0.0
            , array[i_indepdt_var_len[2] - coalesce(i_input_arr_asso[2], i_input_arr_asso[1]) :: int, i_indepdt_var_len[2]] 
          )
      -- -- when 'rand_pick_x'
      -- --   then ...
      -- -- when 'rand_pick_y'
      -- --   then ...
      -- 八则运算
      when 'add'
        then array_fill(1.0 :: float, i_indepdt_var_len)
      when 'sub'
        then array_fill(case i_indepdt_var_loc when 1 then 1 when 2 then -1 end, i_indepdt_var_len)
      when 'mul'
        then i_co_value
      when 'div'
        then 
          case i_indepdt_var_loc 
            when 1 
              then 1.0 :: float/` i_co_value     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
            when 2 
              then -` (i_co_value /` (i_indepdt_var ^` 2.0 :: float))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
          end
      -- -- when 'mod'   -- -- -- 不可微
      -- --   then i_indepdt_var %` i_co_value
      when 'pow'
        then 
          case i_indepdt_var_loc 
            when 1 
              then 
                case 
                  when i_depdt_var is not null 
                    then i_co_value *` i_depdt_var /` i_indepdt_var      -- -- sm_sc.fv_nullif(... , 0.0 :: float)
                  else i_co_value *` (i_indepdt_var ^` (i_co_value -` 1.0 :: float)) 
                end      -- 优先使用 i_depdt_var
            when 2 
              then 
                case 
                  when i_depdt_var is not null 
                    then i_depdt_var *` (^!` i_co_value) 
                  else (i_co_value ^` i_indepdt_var) *` (^!` i_co_value) 
                end     -- 优先使用 i_depdt_var
          end
      when 'exp'
        then case when i_depdt_var is not null then i_depdt_var else ^` i_indepdt_var end      -- -- -- , i_depdt_var
      when 'log'
        then
          case i_indepdt_var_loc 
            when 1 
              then 
                case 
                  when i_depdt_var is not null 
                    then (i_depdt_var ^` 2.0 :: float) /` (i_indepdt_var *` (^!`i_co_value))      -- -- sm_sc.fv_nullif(... , 0.0 :: float)
                  else (-` ((i_indepdt_var ^!` i_co_value) ^` 2.0 :: float)) /` (i_indepdt_var *` (^!` i_co_value))      -- -- sm_sc.fv_nullif(... , 0.0 :: float)
                end     -- 优先使用 i_depdt_var
            when 2 
              then /` (i_indepdt_var *` (^!` i_co_value))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
          end
      when 'ln'
        then /` i_indepdt_var
      when 'sin'
        then sm_sc.fv_cos(i_indepdt_var)::float[]
      when 'cos'
        then -` sm_sc.fv_sin(i_indepdt_var)::float[]
      when 'tan'
        then /` (sm_sc.fv_cos(i_indepdt_var)::float[][] ^` 2.0 :: float)     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'cot'
        then -` (/` (sm_sc.fv_sin(i_indepdt_var)::float[][] ^` 2.0 :: float))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'sec'
        then 
          case 
            when i_depdt_var is not null
              then i_depdt_var *` sm_sc.fv_tan(i_indepdt_var)::float[][]
            else
              sm_sc.fv_tan(i_indepdt_var)::float[][] /` sm_sc.fv_cos(i_indepdt_var)::float[][]     -- 优先使用 i_depdt_var     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
          end
      when 'csc'
        then 
          case 
            when i_depdt_var is not null
              then (-` i_depdt_var) *` sm_sc.fv_cot(i_indepdt_var)::float[][]
            else -` (sm_sc.fv_cot(i_indepdt_var)::float[][] /` sm_sc.fv_sin(i_indepdt_var)::float[][])      -- 优先使用 i_depdt_var     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
          end
      when 'asin'
        then /` ((1.0 :: float-` (i_indepdt_var ^` 2.0 :: float)) ^` 0.5 :: float)     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'acos'
        then -` (/` ((1.0 :: float-` (i_indepdt_var ^` 2.0 :: float)) ^` 0.5 :: float))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'atan'
        then /` (1.0 :: float+` (i_indepdt_var ^` 2.0 :: float))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'acot'
        then -` (/` (1.0 :: float+` (i_indepdt_var ^` 2.0 :: float)))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'asec'
        then /` (i_indepdt_var *` (((i_indepdt_var ^` 2.0 :: float) -` 1.0 :: float) ^` 0.5 :: float))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'acsc'
        then -` (/` (i_indepdt_var *` (((i_indepdt_var ^` 2.0 :: float) -` 1.0 :: float) ^` 0.5 :: float)))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'sinh'
        then sm_sc.fv_cosh(i_indepdt_var)::float[]
      when 'cosh'
        then sm_sc.fv_sinh(i_indepdt_var)::float[]
      when 'tanh'
        then 
          case 
            when i_depdt_var is not null
              then 1.0 :: float-` (i_depdt_var ^` 2.0 :: float) 
            else
              -- /` (sm_sc.fv_cosh(i_indepdt_var)::float[][] ^` 2.0 :: float)      -- 优先使用 i_depdt_var     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
              1.0 :: float-` (sm_sc.fv_tanh(i_indepdt_var)::float[][] ^` 2.0 :: float) 
          end
      -- -- -- when 'coth'
      -- -- --   then sm_sc.fv_coth
      -- -- -- when 'sech'
      -- -- --   then sm_sc.fv_sech
      -- -- -- when 'csch'
      -- -- --   then sm_sc.fv_csch
      when 'asinh'
        then /` (((i_indepdt_var ^` 2.0 :: float) +` 1.0 :: float) ^` 0.5 :: float)     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'acosh'
        then /` (((i_indepdt_var ^` 2.0 :: float) -` 1.0 :: float) ^` 0.5 :: float)     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      when 'atanh'
        then /` (1.0 :: float-` (i_indepdt_var ^` 2.0 :: float))     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      -- -- -- when 'acoth'
      -- -- --   then sm_sc.fv_acoth
      -- -- -- when 'asech'
      -- -- --   then sm_sc.fv_asech
      -- -- -- when 'acsch'
      -- -- --   then sm_sc.fv_acsch         
    end
  ;
  
  if _v_debug is null
    -- or sm_sc.fv_aggr_slice_is_exists_null(_v_debug) is true
  then 
    raise exception 'there is null value in returning!  i_node_no: %.  ', i_node_no;
  elsif 'NaN' :: float = any(_v_debug)
  then 
    raise exception 'there is NaN value in returning!  i_node_no: %.  ', i_node_no;
  end if;
  
  return _v_debug;

-- -- debug 
-- raise notice 'lambda_delta % end:: i_lambda: %; indepdt_var_loc: %; time: %;', i_node_no, i_lambda, i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
--   return _v_debug;

-- exception when others then
--   raise exception 
--   ' fn: sm_sc.fv_lambda_arr_delta
--     i_lambda: %
--     len of i_indepdt_var: %
--     i_indepdt_var_loc: %
--     len of i_co_value: %
--     i_input_arr_asso: %
--     len of i_depdt_var: %
--     i_indepdt_var_len: %
--     sqlerrm: %
--   '
--   , i_lambda             
--   , array[array_length(i_indepdt_var, 1), array_length(i_indepdt_var, 2)]          
--   , i_indepdt_var_loc      
--   , array[array_length(i_co_value, 1), array_length(i_co_value, 2)] 
--   , i_input_arr_asso
--   , array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)] 
--   , i_indepdt_var_len      
--   , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;






