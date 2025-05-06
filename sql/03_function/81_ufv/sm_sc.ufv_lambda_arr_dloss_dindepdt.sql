-- 本函数以数组为入参，标量版本参考 sm_sc.fv_gradient_opr
-- 对于 conv_2d, pool_max, pool_avg, softmax, zscore 本函数求取 dloss/dindepdt, 而不是求取 ddepdt/dindepdt
-- drop function if exists sm_sc.ufv_lambda_arr_dloss_dindepdt(bigint, varchar(64), float[], int, float[], float[], float[], int, float[]);
create or replace function sm_sc.ufv_lambda_arr_dloss_dindepdt
(
  i_node_no               bigint,
  i_lambda                varchar(64)                       ,
  i_indepdt_var           float[]                  ,
  i_indepdt_var_loc       int     default 1        ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 prod_mx, sub, div, pow, log, softmax 等运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
  i_co_value              float[] default null     ,    -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
  i_input_arr_asso        float[] default null     ,    
  i_depdt_var             float[] default null     ,    -- 前向的因变量
  i_dloss_ddepdt          float[] default null     ,    -- 此入参传入 dloss/ddepdt, 用于 反向传播阶段 求取 dloss/dindepdt
  i_indepdt_var_len       int[]   default null     ,    -- 自变量的高宽规格，agg_concat_x, agg_concat_y, agg_sum, agg_avg, slice_x, slice_y, add, sub 会用到改参数，以避免传参 i_indepdt_var，从而降低堆区开销
  i_ddepdt_dindepdt       float[] default null          -- 因变量对自变量导数
)
returns float[][]
as
$$
declare 
  -- -- _v_debug           float[][];
  v_indepdt_var_len  int[]      := coalesce(i_indepdt_var_len, (select array_agg(array_length(i_indepdt_var, a_ndim) order by a_ndim) from generate_series(1, array_ndims(i_indepdt_var)) tb_a_ndim(a_ndim)));
begin
-- -- debug
-- raise notice '
-- sm_sc.ufv_lambda_arr_dloss_dindepdt debug :
--   i_lambda                : %; 
--   i_indepdt_var             : %; 
--   i_indepdt_var_loc         : %; 
--   i_co_value              : %; 
--   i_input_arr_asso   : %; 
--   i_depdt_var           : %; 
-- ', $1, $2, $3, $4, $5, $6
-- ;

  -- 动态 sql 会影响性能，所以还是用 case 判断
  
-- -- debug 
-- raise notice 'lambda_dloss_dindepdt % begin:: i_lambda: %; len_dloss_dindepdt: %; indepdt_var_loc: %; time: %;'
-- , i_node_no, i_lambda, array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2)], i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');

  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if 'NaN' :: float = any(i_indepdt_var)
      or 'NaN' :: float = any(i_co_value)
      or 'NaN' :: float = any(i_depdt_var)
      or 'NaN' :: float = any(i_dloss_ddepdt)
    then 
      raise exception 'there is NaN value in i_indepdt_var, i_co_value, i_depdt_var or i_dloss_ddepdt!  i_node_no: %.  ', i_node_no;
    end if;
  end if;
  
  if i_lambda = '81_query_from_col'
  then 
    return 
      sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
      (
        i_dloss_ddepdt        
      , i_indepdt_var_len         
      , i_co_value :: int[]
      )
    ;
  elsif i_lambda = '81_query_from_row'
  then 
    return 
      sm_sc.ufv_d_query_by_heigh_col_idx_from_row_dloss_dindepdt_1
      (
        i_dloss_ddepdt        
      , i_indepdt_var_len         
      , i_co_value :: int[]
      )
    ;
    
  else 
    raise exception 'no defination for this lambda %', i_lambda;
  end if;  

  -- -- if current_setting('pg4ml._v_is_debug_check', true) = '1'
  -- -- then 
  -- --   if _v_debug is null
  -- --     -- or sm_sc.fv_aggr_slice_is_exists_null(_v_debug) is true
  -- --   then 
  -- --     raise exception 'there is null value in returning!  i_node_no: %.  ', i_node_no;
  -- --   elsif 'NaN' :: float = any(_v_debug)
  -- --   then 
  -- --     raise exception 'there is NaN value in returning!  i_node_no: %.  ', i_node_no;
  -- --   end if;
  -- -- end if;
  -- -- 
  -- -- return _v_debug;
  
-- -- debug 
-- raise notice 'lambda_dloss_dindepdt % end:: i_lambda: %; indepdt_var_loc: %; time:%;', i_node_no, i_lambda, i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
--   return _v_debug;

  exception when others then
    raise exception 
    ' i_node_no: %
      fn: sm_sc.ufv_lambda_arr_dloss_dindepdt
      i_lambda: %
      len of i_indepdt_var: %
      i_indepdt_var_loc: %
      len of i_co_value: %
      i_input_arr_asso: %
      len of i_depdt_var: %
      len of i_dloss_ddepdt: %
      sqlerrm: %
    '
    , i_node_no
    , i_lambda             
    , array_dims(i_indepdt_var)
    , i_indepdt_var_loc      
    , array_dims(i_co_value)
    , i_input_arr_asso
    , array_dims(i_depdt_var)
    , array_dims(i_dloss_ddepdt)
    , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;



-- select 
--   sm_sc.ufv_lambda_arr_dloss_dindepdt
--   (
--     100001
--     , 'softmax_x'
--     , array[[1.23, 3.34, 0.96],[2.2, 0.25, 7.7]]
--     , 2
--     , null
--     , null
--     , sm_sc.fv_standlize_x_softmax(array[[1.23, 3.34, 0.96],[2.2, 0.25, 7.7]])
--     , (-` array[[0.0 :: float, 0.0 :: float, 1.0], [0.0 :: float, 0.0 :: float, 1.0]]) /` sm_sc.fv_standlize_x_softmax(array[[1.23, 3.34, 0.96],[2.2, 0.25, 7.7]])
--   );



