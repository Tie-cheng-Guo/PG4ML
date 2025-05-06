-- drop function if exists sm_sc.ufv_lambda_arr(bigint, varchar(64), float[], float[][], float[], float[][]);
create or replace function sm_sc.ufv_lambda_arr
(
  i_node_no               bigint,
  i_lambda                varchar(64)                      ,
  i_param_1               float[]                 ,
  i_param_2               float[]   default null  ,      -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立
  i_input_arr_asso        float[]   default null  ,   
  i_param_3               float[]   default null
)
returns float[][]
as
$$
declare 
  -- -- v_lambda varchar(64)    :=    coalesce((select 'v...' from sm_sc.tb_dic... where col...'k...' = i_lambda limit 1), i_lambda)
 _v_debug         float[][];
begin
  -- 动态 sql 会影响性能，所以还是用 case 判断
  
-- -- debug 
-- raise notice 'lambda % begin:: i_lambda: %; len_input: %; len_co_val: %; time: %;'
-- , i_node_no, i_lambda, array[array_length(i_param_1, 1), array_length(i_param_1, 2)], array[array_length(i_param_2, 1), array_length(i_param_2, 2)], to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');

  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if i_param_1 is null
      -- or sm_sc.fv_aggr_slice_is_exists_null(i_param_1) is true
    then 
      raise exception 'there is null value in i_param_1!  i_node_no: %.  ', i_node_no;
    elsif 'NaN' :: float = any(i_param_1)
      or 'NaN' :: float = any(i_param_2)
      or i_param_1 is null
      -- or sm_sc.fv_aggr_slice_is_exists_null(i_param_1) is true
    then 
      raise exception 'there is NaN value in i_param_1 or i_param_2!  i_node_no: %.  ', i_node_no;
    end if;
  end if;
  
  if i_lambda = '81_query_from_col'
  then 
    return 
      sm_sc.ufv_query_by_width_row_idx_from_col
      (
        i_param_1        
      , i_param_2 :: int[]
      )
    ;
  elsif i_lambda = '81_query_from_row'
  then 
    return 
      sm_sc.ufv_query_by_heigh_col_idx_from_row
      (
        i_param_1        
      , i_param_2 :: int[]
      )
    ;
  elsif i_lambda = '81_prod_mx_slice_no_backward'
  then 
    return 
      sm_sc.ufv_prod_mx_slice
      (
        i_param_1        
      , i_param_2
      )
    ;
  elsif i_lambda = '81_prod_mx_chunk'
  then 
    return 
      sm_sc.ufv_prod_mx_based_org_chunk
      (
        i_param_1        
      , i_param_2        
      , i_input_arr_asso[1]
      , i_param_3
      )
    ;
    
  else 
    raise exception 'no defination for this lambda %', i_lambda;
  end if;
  
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if _v_debug is null
      -- or sm_sc.fv_aggr_slice_is_exists_null(_v_debug) is true
    then 
      raise exception 'there is null value in returning!  i_node_no: %.  ', i_node_no;
    elsif 'NaN' :: float = any(_v_debug)
    then 
      raise exception 'there is NaN value in returning!  i_node_no: %.  ', i_node_no;
    end if;
  end if;
  
  return _v_debug;

-- -- debug 
-- raise notice 'lambda % end:: i_lambda: %; time: %;', i_node_no, i_lambda, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
--   return _v_debug;

  exception when others then
    raise exception 
    ' fn: sm_sc.ufv_lambda_arr
      i_node_no: %
      i_lambda: %
      len of i_param_1: %
      len of i_param_2: %
      i_input_arr_asso: %
      sqlerrm: %
    '
    , i_node_no
    , i_lambda
    , array_dims(i_param_1)
    , array_dims(i_param_2)
    , i_input_arr_asso
    , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.ufv_lambda_arr
--   (
--     100001
--     , '81_prod_mx_slice_no_backward'
--     , array[[1.23, 3.34],[-7.2, -0.25]]
--     , array[[1.23, 3.34],[-7.2, -0.25],[-7.2, -0.25]]
--   );
