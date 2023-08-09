-- drop function if exists sm_sc.fv_lambda_arr(bigint, varchar(64), float[][], float[][], float[][]);
create or replace function sm_sc.fv_lambda_arr
(
  i_node_no               bigint,
  i_lambda                varchar(64)                      ,
  i_input_arr_params      float[][]               ,
  i_co_value              float[][] default null  ,      -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立
  i_input_arr_asso   float[]     default null       
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
-- , i_node_no, i_lambda, array[array_length(i_input_arr_params, 1), array_length(i_input_arr_params, 2)], array[array_length(i_co_value, 1), array_length(i_co_value, 2)], to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');

  if i_input_arr_params is null
    -- or sm_sc.fv_aggr_slice_is_exists_null(i_input_arr_params) is true
  then 
    raise exception 'there is null value in i_input_arr_params!  i_node_no: %.  ', i_node_no;
  elsif 'NaN' :: float = any(i_input_arr_params)
    or 'NaN' :: float = any(i_co_value)
    or i_input_arr_params is null
    -- or sm_sc.fv_aggr_slice_is_exists_null(i_input_arr_params) is true
  then 
    raise exception 'there is NaN value in i_input_arr_params or i_co_value!  i_node_no: %.  ', i_node_no;
  end if;

  _v_debug := 

  -- return
    case i_lambda
      when 'prod_mx'
        then (i_input_arr_params :: float[]) |**| (i_co_value :: float[])
      when 'conv_2d'
        then 
          sm_sc.fv_conv_2d_grp_x
          (
            i_input_arr_params   :: float[]                                     ,   
            i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
            i_co_value           :: float[]                                     ,   
            i_input_arr_asso[3] :: int                                              ,   -- 规约：存放 i_window_len_x 
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
            coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
          )
      when 'pool_max'
        then 
          sm_sc.fv_pool_max_2d_grp_x
          (
            i_input_arr_params                                                           ,   
            i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
            i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
            coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
          )
      when 'pool_avg'
        then 
          sm_sc.fv_pool_avg_2d_grp_x
          (
            i_input_arr_params                                                           ,   
            i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
            i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
            coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
          )
      -- 规约在 prc_nn_train 中， rand_pick_y, rand_pick_x 算子的最后一列/行，为 rand 到的切片序号
      when 'rand_pick_x'  -- 尚未配置求导
        then 
          (
            select 
              o_slices |-|| (array[o_ord_nos] :: float[])
            from sm_sc.ft_rand_slice_x_pick(i_input_arr_params, i_input_arr_asso[1]::int) tb_a
          )  -- 规约：i_input_arr_asso[1] 存放所设置的 取样数量
      -- 规约在 prc_nn_train 中， rand_pick_y, rand_pick_x 算子的最后一列/行，为 rand 到的切片序号
      when 'rand_pick_y'  -- 尚未配置求导
        then 
          (
            select 
              o_slices |||| (|^~| array[o_ord_nos] :: float[])
            from sm_sc.ft_rand_slice_y_pick(i_input_arr_params, i_input_arr_asso[1]::int) tb_a  -- 规约：i_input_arr_asso[1] 存放所设置的 取样数量
          )
      when 'sigmoid'
        then sm_sc.fv_activate_sigmoid(i_input_arr_params)
      when 'softmax_mx'
        then sm_sc.fv_standlize_mx_softmax(i_input_arr_params)
      when 'softmax_x'
        then sm_sc.fv_standlize_x_softmax(i_input_arr_params)
      when 'softmax_y'
        then sm_sc.fv_standlize_y_softmax(i_input_arr_params)
      when 'zscore_mx'
        then sm_sc.fv_standlize_mx_zscore(i_input_arr_params)
      when 'zscore_x'
        then sm_sc.fv_standlize_x_zscore(i_input_arr_params)
      when 'zscore_y'
        then sm_sc.fv_standlize_y_zscore(i_input_arr_params)
      when 'relu'
        then sm_sc.fv_activate_relu(i_input_arr_params)
      when 'elu'
        then sm_sc.fv_activate_elu(i_input_arr_params, i_input_arr_asso[1])
      when 'leaky_relu'
        then sm_sc.fv_activate_leaky_relu(i_input_arr_params, i_input_arr_asso[1])
      when 'selu'
        then sm_sc.fv_activate_selu(i_input_arr_params)
      when 'gelu'
        then sm_sc.fv_activate_gelu(i_input_arr_params)
      when 'softplus'
        then sm_sc.fv_activate_softplus(i_input_arr_params)
      when 'swish'
        then sm_sc.fv_activate_swish(i_input_arr_params)
      when 'slice_x'
        then i_input_arr_params[ : ][i_input_arr_asso[1]::int : coalesce(i_input_arr_asso[2], i_input_arr_asso[1])::int]
      when 'slice_y'
        then i_input_arr_params[i_input_arr_asso[1]::int : coalesce(i_input_arr_asso[2], i_input_arr_asso[1])::int][ : ]
      -- -- when 'agg_concat_x'
      -- --   then i_input_arr_params
      -- -- when 'agg_concat_y'
      -- --   then i_input_arr_params
      -- -- when 'agg_sum'
      -- --   then i_input_arr_params
      -- -- when 'agg_avg'
      -- --   then i_input_arr_params
      -- -- when 'agg_max'
      -- --   then i_input_arr_params
      -- -- when 'agg_min'
      -- --   then i_input_arr_params
      -- -- when 'agg_prod'
      -- --   then i_input_arr_params
      -- -- -- 八则运算
      when 'add'
        then i_input_arr_params +` i_co_value
      when 'sub'
        then i_input_arr_params -` i_co_value
      when 'mul'
        then i_input_arr_params *` i_co_value
      when 'div'
        then i_input_arr_params /` i_co_value
      when 'mod'   -- -- -- 不可微
        then i_input_arr_params %` i_co_value
      when 'pow'
        then i_input_arr_params ^` i_co_value
      when 'exp'
        then ^` i_input_arr_params
      when 'log'
        then i_input_arr_params ^!` i_co_value
      when 'ln'
        then ^!` i_input_arr_params 
      when 'sin'
        then sm_sc.fv_sin(i_input_arr_params) :: float[]
      when 'cos'
        then sm_sc.fv_cos(i_input_arr_params) :: float[]
      when 'tan'
        then sm_sc.fv_tan(i_input_arr_params) :: float[]
      when 'cot'
        then sm_sc.fv_cot(i_input_arr_params) :: float[]
      -- -- -- when 'sec'
      -- -- --   then sm_sc.fv_sec(i_input_arr_params) :: float[]
      -- -- -- when 'csc'
      -- -- --   then sm_sc.fv_csc(i_input_arr_params) :: float[]
      when 'asin'
        then sm_sc.fv_asin(i_input_arr_params) :: float[]
      when 'acos'
        then sm_sc.fv_acos(i_input_arr_params) :: float[]
      when 'atan'
        then sm_sc.fv_atan(i_input_arr_params) :: float[]
      -- -- -- when 'acot'
      -- -- --   then sm_sc.fv_acot(i_input_arr_params) :: float[]
      -- -- -- when 'asec'
      -- -- --   then sm_sc.fv_asec(i_input_arr_params) :: float[]
      -- -- -- when 'acsc'
      -- -- --   then sm_sc.fv_acsc(i_input_arr_params) :: float[]
      when 'sinh'
        then sm_sc.fv_sinh(i_input_arr_params) :: float[]
      when 'cosh'
        then sm_sc.fv_cosh(i_input_arr_params) :: float[]
      when 'tanh'
        then sm_sc.fv_tanh(i_input_arr_params) :: float[]
      -- -- -- when 'coth'
      -- -- --   then sm_sc.fv_coth(i_input_arr_params) :: float[]
      -- -- -- when 'sech'
      -- -- --   then sm_sc.fv_sech(i_input_arr_params) :: float[]
      -- -- -- when 'csch'
      -- -- --   then sm_sc.fv_csch(i_input_arr_params) :: float[]
      when 'asinh'
        then sm_sc.fv_asinh(i_input_arr_params) :: float[]
      when 'acosh'
        then sm_sc.fv_acosh(i_input_arr_params) :: float[]
      when 'atanh'
        then sm_sc.fv_atanh(i_input_arr_params) :: float[]
      -- -- -- when 'acoth'
      -- -- --   then sm_sc.fv_acoth(i_input_arr_params) :: float[]
      -- -- -- when 'asech'
      -- -- --   then sm_sc.fv_asech(i_input_arr_params) :: float[]
      -- -- -- when 'acsch'
      -- -- --   then sm_sc.fv_acsch(i_input_arr_params) :: float[]
      when 'new'
        then sm_sc.fv_new(i_input_arr_params, i_input_arr_asso[1 : 2] :: int[])
      else null
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
-- raise notice 'lambda % end:: i_lambda: %; time: %;', i_node_no, i_lambda, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');
--   return _v_debug;

-- exception when others then
--   raise exception 
--   ' fn: sm_sc.fv_lambda_arr
--     i_node_no: %
--     i_lambda: %
--     len of i_input_arr_params: %
--     len of i_co_value: %
--     i_input_arr_asso: %
--     sqlerrm: %
--   '
--   , i_node_no
--   , i_lambda
--   , array[array_length(i_input_arr_params, 1), array_length(i_input_arr_params, 2)]
--   , array[array_length(i_co_value, 1), array_length(i_co_value, 2)]
--   , i_input_arr_asso
--   , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_lambda_arr
--   (
--     100001
--     , 'elu'
--     , array[[1.23, 3.34],[-7.2, -0.25]]
--     , null
--     , array[0.1]
--   );





