-- 本函数以数组为入参，标量版本参考 sm_sc.fv_gradient_opr
-- 对于一些原函数,  本求导函数无法求取 ddepdt/dindepdt，参看 sm_sc.fv_lambda_arr_dloss_dindepdt 求取 dloss/dindepdt
-- 本函数求取因变量对自变量的导数，没有对自变量广播求逆。
-- drop function if exists sm_sc.ufv_lambda_arr_ddepdt_dindepdt(bigint, varchar(64), float[], int, float[], float[], float[]);
create or replace function sm_sc.ufv_lambda_arr_ddepdt_dindepdt
(
  i_node_no               bigint,
  i_lambda                varchar(64)              ,
  i_indepdt_var           float[]                  ,
  i_indepdt_var_loc       int       default 1      ,    -- 单目、双目为 x 参数实际位置，无目/常量y为0，并目/聚合为 n；该参数对 prod_mx, sub, div, pow, log 等运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
  i_co_value              float[]   default null   ,    -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
  i_input_arr_asso        float[]   default null   ,    
  i_depdt_var             float[]   default null   ,    -- 前向的因变量，非必要入参
  -- i_dloss_ddepdt          float[] default null   ,       -- 此入参传入 dloss/ddepdt, 用于 反向传播阶段 求取 dloss/dindepdt
  i_indepdt_var_len       int[2]    default null        -- 自变量的高宽规格，agg_concat_x, agg_concat_y, agg_sum, agg_avg, slice_x, slice_y, add, sub conv_add/conv_sub/conv_de_add/conv_de_sub 等算子可用到该参数优化入参，以避免传参 i_indepdt_var，从而降低堆区开销
)
returns float[][]
as
$$
declare 
  _v_debug           float[]    ;
  -- v_indepdt_var_len  int[]      := (select array_agg(array_length(i_indepdt_var, a_ndim) order by a_ndim) from generate_series(1, array_ndims(i_indepdt_var)) tb_a_ndim(a_ndim));
  -- v_depdt_var_len    int[]      := (select array_agg(array_length(i_depdt_var, a_ndim) order by a_ndim) from generate_series(1, array_ndims(i_depdt_var)) tb_a_ndim(a_ndim));
begin
-- -- debug
-- raise notice '
-- sm_sc.ufv_lambda_arr_ddepdt_dindepdt debug :
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
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if 'NaN' :: float = any(i_indepdt_var)
      or 'NaN' :: float = any(i_co_value)
      or 'NaN' :: float = any(i_depdt_var)
    then 
      raise exception 'there is NaN value in i_indepdt_var, i_co_value or i_depdt_var!  i_node_no: %.  ', i_node_no;
    end if;
  end if;
    
  -- -- -- if i_lambda = '81_...'
  -- -- -- then 
  -- -- --   return 
  -- -- --     sm_sc.ufv_...
  -- -- --     (
  -- -- --       ...
  -- -- --     , ...
  -- -- --     , ...
  -- -- --     , ...
  -- -- --     , ...
  -- -- --     , ...
  -- -- --     , ...
  -- -- --     , ...
  -- -- --     )
  -- -- --   ;
  -- -- -- else 
  -- -- --   raise exception 'no defination for this lambda %', i_lambda;
  -- -- -- end if;  

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
-- raise notice 'lambda_delta % end:: i_lambda: %; indepdt_var_loc: %; time: %;', i_node_no, i_lambda, i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
--   return _v_debug;

exception when others then
  raise exception 
  ' fn: sm_sc.ufv_lambda_arr_ddepdt_dindepdt
    i_node_no: %;
    i_lambda: %;
    len of i_indepdt_var: %;
    i_indepdt_var_loc: %;
    len of i_co_value: %;
    i_input_arr_asso: %;
    len of i_depdt_var: %;
    v_indepdt_var_len: %;
    sqlerrm: %;
  '
  , i_node_no
  , i_lambda             
  , array_dims(i_indepdt_var)          
  , i_indepdt_var_loc      
  , array_dims(i_co_value)
  , i_input_arr_asso
  , array_dims(i_depdt_var)
  , v_indepdt_var_len      
  , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;






