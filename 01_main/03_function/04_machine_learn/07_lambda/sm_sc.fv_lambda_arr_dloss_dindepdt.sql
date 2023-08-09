-- 本函数以数组为入参，标量版本参考 sm_sc.fv_gradient_opr
-- 对于 conv_2d, pool_max, pool_avg, softmax, zscore 本函数求取 dloss/dindepdt, 而不是求取 ddepdt/dindepdt
-- drop function if exists sm_sc.fv_lambda_arr_dloss_dindepdt(bigint, varchar(64), float[][], int, float[][], float[][], float[][], float[][]);
create or replace function sm_sc.fv_lambda_arr_dloss_dindepdt
(
  i_node_no bigint,
  i_lambda                varchar(64)                       ,
  i_indepdt_var           float[][]                ,
  i_indepdt_var_loc       int                default 1      ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 prod_mx, sub, div, pow, log, softmax 等运算操作敏感；其他运算操作用不到 i_indepdt_var_loc 
  i_co_value              float[][] default null   ,    -- fn 配套的另一个入参值，该配套入参位置与 i_indepdt_var_loc 对立
  i_input_arr_asso        float[]   default null   ,    
  i_depdt_var             float[][] default null   ,    -- 前向的因变量，非必要入参
  i_dloss_ddepdt          float[][] default null   ,    -- 此入参传入 dloss/ddepdt, 用于 反向传播阶段 求取 dloss/dindepdt
  -- i_indepdt_var_len         int[2]             default null        -- 自变量的高宽规格，agg_concat_x, agg_concat_y, agg_sum, agg_avg, slice_x, slice_y, add, sub 会用到改参数，以避免传参 i_indepdt_var，从而降低堆区开销
  i_ddepdt_dindepdt       float[][] default null        -- 因变量对自变量导数
)
returns float[][]
as
$$
declare 
  _v_debug         float[][];
begin
  -- -- -- i_indepdt_var_len := coalesce(i_indepdt_var_len, array[array_length(i_indepdt_var, 1), array_length(i_indepdt_var, 2)]);
-- -- debug
-- raise notice '
-- sm_sc.fv_lambda_arr_dloss_dindepdt debug :
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

  if 'NaN' :: float = any(i_indepdt_var)
    or 'NaN' :: float = any(i_co_value)
    or 'NaN' :: float = any(i_depdt_var)
    or 'NaN' :: float = any(i_dloss_ddepdt)
  then 
    raise exception 'there is NaN value in i_indepdt_var, i_co_value, i_depdt_var or i_dloss_ddepdt!  i_node_no: %.  ', i_node_no;
  end if;
  
  _v_debug := 

  -- return
    case i_lambda
      when 'prod_mx'
        then 
          case i_indepdt_var_loc 
            when 1 
              then 
                i_dloss_ddepdt |**| (|^~| i_ddepdt_dindepdt)
            when 2 
              then 
                i_ddepdt_dindepdt |**| i_dloss_ddepdt
          end
      when 'conv_2d'
        then 
          case i_indepdt_var_loc 
            when 1 
              then 
                -- 规约 i_input_arr_asso[11 : 12] 存放 i_input_arr_params (卷积第一目参数，即图像 2d 数据) 高宽，仅用于优化传参
                sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1
                (
                  -- -- i_input_arr_asso[11] :: int         ,                                       -- 规约：存放 i_array_grp_x_len
                  i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
                  i_dloss_ddepdt                         ,
                  i_ddepdt_dindepdt                               ,                                       -- i_window
                  i_input_arr_asso[3] :: int          ,                                       -- 规约：存放 i_window_len_x
                  coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
                  coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
                )
            when 2 
              then 
                -- 规约 i_input_arr_asso[11 : 12] 存放 i_indepdt_var (卷积第二目参数，即窗口 w)高宽，仅用于优化传参
                sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_2
                (
                  i_ddepdt_dindepdt                               ,                                       -- i_array_grp_x
                  i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
                  i_dloss_ddepdt                         ,
                  i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
                  i_input_arr_asso[12] :: int :: boolean                                  ,   -- 规约：存放 i_window_bias_label
                  coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
                  coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
                  coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
                )
          end
      when 'pool_max'
        then 
          sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt
          (
            i_indepdt_var                              ,                                       -- i_array_grp_x
            i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
            i_dloss_ddepdt                         ,
            i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
            i_depdt_var                            ,                                       -- i_y_1d_grp
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
          )
      when 'pool_avg'
        then 
          sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt
          (
            i_input_arr_asso[11] :: int         ,                                       -- 规约：存放 i_array_grp_x_len
            i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
            i_dloss_ddepdt                         ,
            i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
          )
      when 'softmax_mx'
        then 
          sm_sc.fv_d_standlize_mx_softmax_dloss_dindepdt
          (
            i_depdt_var, 
            i_dloss_ddepdt,
            i_indepdt_var           --  如果 i_depdt_var 传值, i_indepdt_var 就传 null。只传前者性能更佳
          )
      when 'softmax_x'
        then 
          sm_sc.fv_d_standlize_x_softmax_dloss_dindepdt
          (
            i_depdt_var, 
            i_dloss_ddepdt,
            i_indepdt_var          --  如果 i_depdt_var 传值, i_indepdt_var 就传 null。只传前者性能更佳
          )
      when 'softmax_y'
        then 
          sm_sc.fv_d_standlize_y_softmax_dloss_dindepdt
          (
            i_depdt_var, 
            i_dloss_ddepdt,
            i_indepdt_var          --  如果 i_depdt_var 传值, i_indepdt_var 就传 null。只传前者性能更佳
          )
      when 'zscore_mx'
        then 
          sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt
          (
            i_depdt_var, 
            i_dloss_ddepdt,
            i_indepdt_var           --  i_indepdt_var 为必要传值，i_depdt_var 为不必要传值，但期望传值，可节省一些计算步骤
          )
      when 'zscore_x'
        then 
          sm_sc.fv_d_standlize_x_zscore_dloss_dindepdt
          (
            i_depdt_var, 
            i_dloss_ddepdt,
            i_indepdt_var           --  i_indepdt_var 为必要传值，i_depdt_var 为不必要传值，但期望传值，可节省一些计算步骤
          )
      when 'zscore_y'
        then 
          sm_sc.fv_d_standlize_y_zscore_dloss_dindepdt
          (
            i_depdt_var, 
            i_dloss_ddepdt,
            i_indepdt_var           --  i_indepdt_var 为必要传值，i_depdt_var 为不必要传值，但期望传值，可节省一些计算步骤
          )
      when 'agg_concat_x'
        then 
          i_dloss_ddepdt
          [ : ]
          [
            coalesce(sm_sc.fv_aggr_slice_sum(i_input_arr_asso[ : i_indepdt_var_loc - 1][2 : 2]) :: int, 0) + 1
            : coalesce(sm_sc.fv_aggr_slice_sum(i_input_arr_asso[ : i_indepdt_var_loc - 1][2 : 2]) :: int, 0) + i_input_arr_asso[i_indepdt_var_loc][2] :: int
          ]
      when 'agg_concat_y'
        then 
          i_dloss_ddepdt
          [
            coalesce(sm_sc.fv_aggr_slice_sum(i_input_arr_asso[ : i_indepdt_var_loc - 1][1 : 1]) :: int, 0) + 1
            : coalesce(sm_sc.fv_aggr_slice_sum(i_input_arr_asso[ : i_indepdt_var_loc - 1][1 : 1]) :: int, 0) + i_input_arr_asso[i_indepdt_var_loc][1] :: int
          ]
          [ : ]
      when 'rand_pick_x'
        then 
          (
            select 
              sm_sc.fa_mx_concat_x(i_dloss_ddepdt[ : ][a_idx : a_idx])
            from unnest(i_input_arr_asso[2 : ]) tb_a(a_idx)
          )
      when 'rand_pick_y'
        then 
          (
            select 
              sm_sc.fa_mx_concat_y(i_dloss_ddepdt[a_idx : a_idx][ : ])
            from unnest(i_input_arr_asso[2 : ]) tb_a(a_idx)
          )
      when 'new'
        then 
          sm_sc.fv_d_new(i_dloss_ddepdt, i_input_arr_asso[1 : 2] :: int[])
      else 
        i_dloss_ddepdt *` i_ddepdt_dindepdt
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
-- raise notice 'lambda_dloss_dindepdt % end:: i_lambda: %; indepdt_var_loc: %; time:%;', i_node_no, i_lambda, i_indepdt_var_loc, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
--   return _v_debug;

-- exception when others then
--   raise exception 
--   ' fn: sm_sc.fv_lambda_arr_dloss_dindepdt
--     i_lambda: %
--     len of i_indepdt_var: %
--     i_indepdt_var_loc: %
--     len of i_co_value: %
--     i_input_arr_asso: %
--     len of i_depdt_var: %
--     len of i_dloss_ddepdt: %
--     sqlerrm: %
--   '
--   , i_lambda             
--   , array[array_length(i_indepdt_var, 1), array_length(i_indepdt_var, 2)]          
--   , i_indepdt_var_loc      
--   , array[array_length(i_co_value, 1), array_length(i_co_value, 2)] 
--   , i_input_arr_asso
--   , array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)] 
--   , array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2)] 
--   , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;



-- select 
--   sm_sc.fv_lambda_arr_dloss_dindepdt
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



