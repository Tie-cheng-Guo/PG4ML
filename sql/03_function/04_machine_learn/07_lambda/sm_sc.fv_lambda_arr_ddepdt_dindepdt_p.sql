-- 本函数以数组为入参，标量版本参考 sm_sc.fv_gradient_opr
-- 对于一些原函数,  本求导函数无法求取 ddepdt/dindepdt，参看 sm_sc.fv_lambda_arr_dloss_dindepdt 求取 dloss/dindepdt
-- 本函数求取因变量对自变量的导数，没有对自变量广播求逆。
-- drop function if exists sm_sc.fv_lambda_arr_ddepdt_dindepdt_p(char(6), bigint, bigint, bigint, varchar(64), varchar(64), int, varchar(64), float[], varchar(64), int[2]);
create or replace function sm_sc.fv_lambda_arr_ddepdt_dindepdt_p
(
  i_model_code_6          char(6)
, i_work_no               bigint
, i_fore_node_no          bigint
, i_back_node_no          bigint
, i_lambda                varchar(64)                 
, i_indepdt_var_p         varchar(64)                 
, i_indepdt_var_loc       int           default 1         -- 单目、双目为 x 参数实际位置，无目/常量y为0，并目/聚合为 n；该参数对 prod_mx, sub, div, pow, log 等运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
, i_co_value_p            varchar(64)   default null      -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
, i_input_arr_asso        float[]       default null      
, i_depdt_var_p           varchar(64)   default null      -- 前向的因变量，非必要入参
, i_indepdt_var_len       int[2]        default null      -- 自变量的高宽规格，agg_concat_x, agg_concat_y, agg_sum, agg_avg, slice_x, slice_y, add, sub conv_add/conv_sub/conv_de_add/conv_de_sub 等算子可用到该参数优化入参，以避免传参 v_indepdt_var，从而降低堆区开销
)
returns varchar(64)
as
$$
declare 
  v_indepdt_var      float[]    := sm_sc.__fv_get_kv(i_indepdt_var_p);
  v_co_value         float[]    := sm_sc.__fv_get_kv(i_co_value_p);
  v_depdt_var        float[]    := sm_sc.__fv_get_kv(i_depdt_var_p);
  v_indepdt_var_len  int[]      := (select array_agg(array_length(v_indepdt_var, a_ndim) order by a_ndim) from generate_series(1, array_ndims(v_indepdt_var)) tb_a_ndim(a_ndim));
  v_depdt_var_len    int[]      := (select array_agg(array_length(v_depdt_var, a_ndim) order by a_ndim) from generate_series(1, array_ndims(v_depdt_var)) tb_a_ndim(a_ndim));
  v_ret              float[]    ;
 
 -- debug 
 v_begin_clock    timestamp     := clock_timestamp();
begin
-- -- debug
-- raise notice '
-- sm_sc.fv_lambda_arr_ddepdt_dindepdt_p debug :
--   i_lambda                : %; 
--   v_indepdt_var           : %; 
--   i_indepdt_var_loc       : %; 
--   v_co_value              : %; 
--   i_input_arr_asso   : %; 
--   v_depdt_var           : %; 
-- ', $1, $2, $3, $4, $5, $6
-- ;

-- -- debug 
-- raise notice 'lambda_delta % begin:: i_lambda: %; len_input: %; len_co_val: %; indepdt_var_loc: %; time: %;'
-- , i_fore_node_no, i_lambda, array[array_length(v_indepdt_var, 1), array_length(v_indepdt_var, 2)], array[array_length(v_co_value, 1), array_length(v_co_value, 2)], i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if 'NaN' :: float = any(v_indepdt_var)
      or 'NaN' :: float = any(v_co_value)
      or 'NaN' :: float = any(v_depdt_var)
    then 
      raise exception 'there is NaN value in v_indepdt_var, v_co_value or v_depdt_var!  i_fore_node_no: %.  ', i_fore_node_no;
    end if;
  end if;
    
  if i_lambda like '06_%'
  then 
    if i_lambda = '06_aggr_mx_sum'
    then 
      v_ret :=   -- return 
        sm_sc.fv_d_mx_sum(v_depdt_var_len)
      ;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, v_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '06_aggr_mx_prod'
    then
      v_ret :=   -- return  
        sm_sc.fv_d_mx_prod(v_indepdt_var, v_depdt_var)
      ;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, v_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '06_aggr_mx_avg'
    then
      v_ret :=   -- return  
        sm_sc.fv_d_mx_avg(i_input_arr_asso[1] :: int, v_depdt_var_len)
      ;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, v_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '06_aggr_mx_max'
    then
      v_ret := 
        sm_sc.fv_d_mx_max(v_indepdt_var, v_depdt_var)
      ;
    elsif i_lambda = '06_aggr_mx_min'
    then
      v_ret := 
        sm_sc.fv_d_mx_min(v_indepdt_var, v_depdt_var)
      ;

    end if;
    
  elsif i_lambda like '03_%'
  then 
    if i_lambda = '03_sigmoid'
    then 
      v_ret := 
        sm_sc.fv_d_activate_sigmoid(v_indepdt_var, v_depdt_var)
      ;
    elsif i_lambda = '03_absqrt'
    then
      v_ret := 
        sm_sc.fv_d_activate_absqrt_py(v_indepdt_var, i_input_arr_asso[1 : 2])
      ;
    elsif i_lambda = '03_relu'
    then
      v_ret := 
        sm_sc.fv_d_activate_relu(v_indepdt_var)
      ;
    elsif i_lambda = '03_leaky_relu'
    then
      v_ret := 
        sm_sc.fv_d_activate_leaky_relu(v_indepdt_var, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_elu'
    then
      v_ret := 
        sm_sc.fv_d_activate_elu(v_indepdt_var, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_selu'
    then
      v_ret := 
        sm_sc.fv_d_activate_selu(v_indepdt_var, v_depdt_var)
      ;
    elsif i_lambda = '03_gelu'
    then
      v_ret := 
        sm_sc.fv_d_activate_gelu(v_indepdt_var)
      ;
    elsif i_lambda = '03_swish'
    then
      v_ret := 
        sm_sc.fv_d_activate_swish(v_indepdt_var)
      ;
    elsif i_lambda = '03_softplus'
    then
      v_ret := 
        sm_sc.fv_d_activate_softplus(v_indepdt_var)
      ;
    elsif i_lambda = '03_boxcox'
    then
      v_ret := 
        sm_sc.fv_d_activate_boxcox(v_indepdt_var, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_zscore'
    then
      v_ret := 
        sm_sc.fv_d_redistr_zscore_py(v_depdt_var, v_indepdt_var, i_input_arr_asso[1 : 6] :: int[])
      ;
    end if;
    
  elsif i_lambda like '02_%'
  then 
    if i_lambda = '02_sin'
    then
      v_ret := 
        sm_sc.fv_d_sin(v_indepdt_var)
      ;
    elsif i_lambda = '02_cos'
    then
      v_ret := 
        sm_sc.fv_d_cos(v_indepdt_var)
      ;
    elsif i_lambda = '02_tan'
    then
      v_ret := 
        sm_sc.fv_d_tan(v_indepdt_var)
      ;
    elsif i_lambda = '02_cot'
    then
      v_ret := 
        sm_sc.fv_d_cot(v_indepdt_var)
      ;
    elsif i_lambda = '02_sec'
    then
      v_ret := 
        sm_sc.fv_d_sec(v_indepdt_var, v_depdt_var)
      ;
    elsif i_lambda = '02_csc'
    then
      v_ret := 
        sm_sc.fv_d_csc(v_indepdt_var, v_depdt_var)
      ;
    elsif i_lambda = '02_asin'
    then
      v_ret := 
        sm_sc.fv_d_asin(v_indepdt_var)
      ;
    elsif i_lambda = '02_acos'
    then
      v_ret := 
        sm_sc.fv_d_acos(v_indepdt_var)
      ;
    elsif i_lambda = '02_atan'
    then
      v_ret := 
        sm_sc.fv_d_atan(v_indepdt_var)
      ;
    elsif i_lambda = '02_acot'
    then
      v_ret := 
        sm_sc.fv_d_acot(v_indepdt_var)
      ;
    elsif i_lambda = '02_sinh'
    then
      v_ret := 
        sm_sc.fv_d_sinh(v_indepdt_var)
      ;
    elsif i_lambda = '02_cosh'
    then
      v_ret := 
        sm_sc.fv_d_cosh(v_indepdt_var)
      ;
    elsif i_lambda = '02_tanh'
    then
      v_ret := 
        sm_sc.fv_d_tanh(v_indepdt_var, v_depdt_var)
      ;
    -- -- elsif i_lambda = '02_sech'
    -- -- then
    -- --   v_ret := 
    -- --     sm_sc.fv_d_sech(v_indepdt_var)
    -- --   ;
    -- -- elsif i_lambda = '02_csch'
    -- -- then
    -- --   v_ret := 
    -- --     sm_sc.fv_d_csch(v_indepdt_var)
    -- --   ;
    elsif i_lambda = '02_asinh'
    then
      v_ret := 
        sm_sc.fv_d_asinh(v_indepdt_var)
      ;
    elsif i_lambda = '02_acosh'
    then
      v_ret := 
        sm_sc.fv_d_acosh(v_indepdt_var)
      ;
    elsif i_lambda = '02_atanh'
    then
      v_ret := 
        sm_sc.fv_d_atanh(v_indepdt_var)
      ;
    end if;
    
  elsif i_lambda like '01_%'
  then 
    if i_lambda = '01_add'
    then 
      v_ret :=   -- return 
        sm_sc.fv_d_add(v_depdt_var_len)  -- 保留 ddepdt_dindepdt 广播，不传 i_indepdt_var_len
      ;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, i_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_mul'
    then
      v_ret :=   -- return 
        sm_sc.fv_d_mul(v_co_value)  -- 保留 ddepdt_dindepdt 广播，不传 i_indepdt_var_len
      ;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, v_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_sub'
    then
      if i_indepdt_var_loc = 1
      then 
        v_ret :=   -- return 
          sm_sc.fv_d_sub_1(v_depdt_var_len)  -- 保留 ddepdt_dindepdt 广播，不传 i_indepdt_var_len
        ;
      elsif i_indepdt_var_loc = 2
      then 
        v_ret :=   -- return 
          sm_sc.fv_d_sub_2(v_depdt_var_len)  -- 保留 ddepdt_dindepdt 广播，不传 i_indepdt_var_len
        ;
      end if;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, i_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_0sub'
    then 
      v_ret :=   -- return 
        sm_sc.fv_d_sub_2(v_depdt_var_len)  -- 保留 ddepdt_dindepdt 广播，不传 i_indepdt_var_len
      ;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, i_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_div'
    then
      if i_indepdt_var_loc = 1
      then 
        v_ret :=   -- return 
          sm_sc.fv_d_div_1(v_co_value)  -- 保留 ddepdt_dindepdt 广播，不传 i_indepdt_var_len
        ;
      elsif i_indepdt_var_loc = 2
      then 
        v_ret :=   -- return 
          -- -- 不采用 sm_sc.fv_d_div_2，由 dloss_dindepdt 环节统一处理广播逆运算
          sm_sc.fv_d_div_2_un_de_broadcast(v_indepdt_var, v_co_value)  -- 保留 ddepdt_dindepdt 广播
        ;
      end if;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, i_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_1div'
    then 
      v_ret :=   -- return 
        sm_sc.fv_d_div_2_un_de_broadcast(v_indepdt_var)
      ;
      
    elsif i_lambda = '01_pow'
    then
      if i_indepdt_var_loc = 1
      then 
        v_ret :=   -- return 
          -- -- 不采用 sm_sc.fv_d_div_2，由 dloss_dindepdt 环节统一处理广播逆运算
          sm_sc.fv_d_pow_1_un_de_broadcast(v_indepdt_var, v_co_value, v_depdt_var)  -- 保留 ddepdt_dindepdt 广播
        ;
      elsif i_indepdt_var_loc = 2
      then 
        v_ret :=   -- return 
          -- -- 不采用 sm_sc.fv_d_div_2，由 dloss_dindepdt 环节统一处理广播逆运算
          sm_sc.fv_d_pow_2_un_de_broadcast(v_indepdt_var, v_co_value, v_depdt_var)  -- 保留 ddepdt_dindepdt 广播
        ;
      end if;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, i_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_log'
    then
      if i_indepdt_var_loc = 1
      then 
        v_ret :=   -- return 
          -- -- 不采用 sm_sc.fv_d_div_2，由 dloss_dindepdt 环节统一处理广播逆运算
          sm_sc.fv_d_log_1_un_de_broadcast(v_indepdt_var, v_co_value, v_depdt_var)  -- 保留 ddepdt_dindepdt 广播
        ;
      elsif i_indepdt_var_loc = 2
      then 
        v_ret :=   -- return 
          -- -- 不采用 sm_sc.fv_d_div_2，由 dloss_dindepdt 环节统一处理广播逆运算
          sm_sc.fv_d_log_2_un_de_broadcast(v_indepdt_var, v_co_value)  -- 保留 ddepdt_dindepdt 广播
        ;
      end if;
      -- -- -- 广播情况的导数倍数处理
      -- -- if cardinality(v_indepdt_var) < cardinality(v_co_value)
      -- --   or cardinality(v_indepdt_var) < cardinality(v_depdt_var)
      -- -- then 
      -- --   v_ret := sm_sc.fv_aggr_chunk_sum(v_ret, i_indepdt_var_len);
      -- -- end if;
      
    elsif i_lambda = '01_exp'
    then
      v_ret := 
        sm_sc.fv_d_exp(v_indepdt_var, v_depdt_var)
      ;
    elsif i_lambda = '01_ln'
    then
      v_ret := 
        sm_sc.fv_d_ln(v_indepdt_var)
      ;
      
    elsif i_lambda = '01_abs'
    then 
      v_ret :=
        sm_sc.fv_d_abs(v_indepdt_var)
      ;

    end if;
    
  elsif i_lambda like '81_%'
  then 
    v_ret := 
      sm_sc.ufv_lambda_arr_ddepdt_dindepdt
      (
        i_fore_node_no        
      , i_lambda         
      , v_indepdt_var    
      , i_indepdt_var_loc
      , v_co_value       
      , i_input_arr_asso 
      , v_depdt_var      
      , i_indepdt_var_len
      )
    ;
    
  end if;  

  -- -- if current_setting('pg4ml._v_is_debug_check', true) = '1'
  -- -- then 
  -- --   if v_ret is null
  -- --     -- or sm_sc.fv_aggr_slice_is_exists_null(v_ret) is true
  -- --   then 
  -- --     raise exception 'there is null value in v_ret :=ing!  i_fore_node_no: %.  ', i_fore_node_no;
  -- --   elsif 'NaN' :: float = any(v_ret)
  -- --   then 
  -- --     raise exception 'there is NaN value in v_ret :=ing!  i_fore_node_no: %.  ', i_fore_node_no;
  -- --   end if;
  -- -- end if;
  -- -- 
  -- -- return v_ret;

-- -- debug 
-- raise notice 'dddi:i_back_node_no: %; i_fore_node_no: %; loc: %; i_lambda: %; time: %;', i_back_node_no, i_fore_node_no, i_indepdt_var_loc, i_lambda, v_begin_clock - clock_timestamp();

  return 
    sm_sc.__fv_set_kv
    (
      v_ret
    , i_model_code_6 || 
      '_' || i_work_no :: varchar   ||
      '_' || i_fore_node_no :: varchar ||
      '_' || i_back_node_no :: varchar ||
      '_dddi' || -- 'd_depdt_d_indepdt'
      '__' || i_indepdt_var_loc :: varchar
    )
  ;

exception when others then
  raise exception 
  ' fn: sm_sc.fv_lambda_arr_ddepdt_dindepdt_p
    i_fore_node_no: %;
    i_lambda: %;
    len of v_indepdt_var: %;
    i_indepdt_var_loc: %;
    len of v_co_value: %;
    i_input_arr_asso: %;
    len of v_depdt_var: %;
    i_indepdt_var_len: %;
    sqlerrm: %;
  '
  , i_fore_node_no
  , i_lambda             
  , array_dims(v_indepdt_var)          
  , i_indepdt_var_loc      
  , array_dims(v_co_value)
  , i_input_arr_asso
  , array_dims(v_depdt_var)
  , i_indepdt_var_len      
  , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;






