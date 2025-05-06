-- drop function if exists sm_sc.fv_lambda_arr_p(char(6), bigint, bigint, bigint, varchar(64), varchar(64), varchar(64), float[], varchar(64));
create or replace function sm_sc.fv_lambda_arr_p
(
  i_model_code_6          char(6)
, i_work_no               bigint
, i_node_no               bigint
, i_sess_id               bigint
, i_lambda                varchar(64)                 
, i_param_1_p             varchar(64)                 
, i_param_2_p             varchar(64)   default null        -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立
, i_input_arr_asso        float[]       default null     
, i_param_3_p             varchar(64)   default null
)
returns varchar(64)
as
$$
declare 
  -- -- v_lambda varchar(64)    :=    coalesce((select 'v...' from sm_sc.tb_dic... where col...'k...' = i_lambda limit 1), i_lambda)
  v_param_1               float[] := sm_sc.__fv_get_kv(i_param_1_p);
  v_param_2               float[] := sm_sc.__fv_get_kv(i_param_2_p);
  v_param_3               float[] := sm_sc.__fv_get_kv(i_param_3_p);
  v_ret                   float[];
 
 -- debug 
 v_begin_clock    timestamp     := clock_timestamp();
begin
  -- 动态 sql 会影响性能，所以还是用 case 判断
  
-- -- debug 
-- raise notice 'lambda % begin:: i_lambda: %; len_input: %; len_co_val: %; time: %;'
-- , i_node_no, i_lambda, array[array_length(v_param_1, 1), array_length(v_param_1, 2)], array[array_length(v_param_2, 1), array_length(v_param_2, 2)], to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS');

  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if v_param_1 is null
      -- or sm_sc.fv_aggr_slice_is_exists_null(v_param_1) is true
    then 
      raise exception 'there is null value in v_param_1!  i_node_no: %.  ', i_node_no;
    elsif 'NaN' :: float = any(v_param_1)
      or 'NaN' :: float = any(v_param_2)
      or v_param_1 is null
      -- or sm_sc.fv_aggr_slice_is_exists_null(v_param_1) is true
    then 
      raise exception 'there is NaN value in v_param_1 or v_param_2!  i_node_no: %.  ', i_node_no;
    end if;
  end if;
  
  if i_lambda like '07_%'
  then 
    if i_lambda = '07_aggr_slice_sum'
    then 
      v_ret := 
        sm_sc.fv_aggr_slice_sum_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_prod'
    then
      v_ret := 
        sm_sc.fv_aggr_slice_prod_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_avg'
    then
      v_ret := 
        sm_sc.fv_aggr_slice_avg_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_max'
    then
      v_ret := 
        sm_sc.fv_aggr_slice_max_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_min'
    then
      v_ret := 
        sm_sc.fv_aggr_slice_min_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_sum'
    then 
      v_ret := 
        sm_sc.fv_aggr_chunk_sum(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_prod'
    then
      v_ret := 
        sm_sc.fv_aggr_chunk_prod(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_avg'
    then
      v_ret := 
        sm_sc.fv_aggr_chunk_avg(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_max'
    then
      v_ret := 
        sm_sc.fv_aggr_chunk_max(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_min'
    then
      v_ret := 
        sm_sc.fv_aggr_chunk_min(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    end if;
    
  -- -- elsif i_lambda like '06_%'
  -- -- then 
  -- --   if i_lambda = '06_aggr_mx_sum'
  -- --   then 
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_prod'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_avg'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_max'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_min'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_y'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_x'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_x3'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_x4'
  -- --   then
  -- --     v_ret := 
  -- --       
  -- --     ;
  -- --   end if;
    
  elsif i_lambda like '05_%'
  then 
    if i_lambda = '05_pool_max_2d_grp_x'
    then 
      v_ret := 
        sm_sc.fv_pool_max_2d_grp_x
        (
          v_param_1                                                           ,   
          i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_avg_2d_grp_x'
    then
      v_ret := 
        sm_sc.fv_pool_avg_2d_grp_x
        (
          v_param_1                                                           ,   
          i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_max'
    then
      v_ret := 
        sm_sc.fv_pool_max_py
        (
          v_param_1                                                           ,   
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_avg'
    then
      v_ret := 
        sm_sc.fv_pool_avg_py
        (
          v_param_1                                                           ,   
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_none'
    then
      v_ret := 
        sm_sc.fv_pool_none_py
        (
          v_param_1                                                           ,   
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_2d_grp_x'
    then
      v_ret := 
        sm_sc.fv_conv_2d_grp_x
        (
          v_param_1   :: float[]                                     ,   
          i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
          v_param_2           :: float[]                                     ,   
          i_input_arr_asso[3] :: int                                              ,   -- 规约：存放 i_window_len_x 
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_2d'
    then
      v_ret := 
        sm_sc.fv_conv_2d_im2col_py
        (
          v_param_1           :: float[]                                        
        , v_param_2           :: float[]                                        
        , v_param_3                                                 
        , coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )        -- 规约：存放 i_stride       
        , coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])        -- 规约：存放 i_padding      
        , coalesce(i_input_arr_asso[10] :: float ,0.0              )                 -- 规约：存放 i_padding_value
        , coalesce(i_input_arr_asso[11] :: int ,0                  )                 -- 规约：存放 i_padding_mode
        )
      ;
    elsif i_lambda = '05_tunnel_conv'
    then
      v_ret := 
        sm_sc.fv_tunnel_conv_py
        (
          v_param_1                 
        , v_param_2                 
        , i_input_arr_asso[1] :: int        -- 规约：存放 i_tunnel_axis     
        , v_param_3                   
        )
      ;
    elsif i_lambda = '05_conv_add'
    then
      v_ret := 
        sm_sc.fv_conv_add
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_sub'
    then
      v_ret := 
        sm_sc.fv_conv_sub
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_mul'
    then
      v_ret := 
        sm_sc.fv_conv_mul
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_div'
    then
      v_ret := 
        sm_sc.fv_conv_div
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_pow'
    then
      v_ret := 
        sm_sc.fv_conv_pow
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_log'
    then
      v_ret := 
        sm_sc.fv_conv_log
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_prod_mx'
    then
      v_ret := 
        sm_sc.fv_conv_prod_mx
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          i_input_arr_asso[2] :: int                                        ,   -- 规约：存放 i_window_len_heigh
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_sub'
    then
      v_ret := 
        sm_sc.fv_conv_de_sub
        (
          v_param_1   :: float[]                                     ,   -- 窗口
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_div'
    then
      v_ret := 
        sm_sc.fv_conv_de_div
        (
          v_param_1   :: float[]                                     ,   -- 窗口
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_pow'
    then
      v_ret := 
        sm_sc.fv_conv_de_pow
        (
          v_param_1   :: float[]                                     ,   -- 窗口
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_log'
    then
      v_ret := 
        sm_sc.fv_conv_de_log
        (
          v_param_1   :: float[]                                     ,   -- 窗口
          v_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_prod_mx'
    then
      v_ret := 
        sm_sc.fv_conv_de_prod_mx
        (
          v_param_1   :: float[]                                     ,   
          v_param_2           :: float[]                                     ,   
          i_input_arr_asso[3] :: int                                        ,   -- 规约：存放 i_window_len_width
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    end if;
    
  elsif i_lambda like '04_%'
  then 
    if i_lambda = '04_new'
    then 
      v_ret := 
        sm_sc.fv_new(v_param_1, i_input_arr_asso[1 : 4] :: int[])
      ;
    elsif i_lambda = '04_reshape'
    then 
      i_input_arr_asso := 
        (
          sm_sc.fv_coalesce
          (
            i_input_arr_asso
          , (select array_agg(array_length(v_param_1, a_no) order by a_no) :: float[] from generate_series(1, array_ndims(v_param_1)) tb_a(a_no))
          )
        )
          [1 : array_length(i_input_arr_asso, 1)]
      ;
      v_ret := 
        sm_sc.fv_opr_reshape_py(v_param_1, i_input_arr_asso[1 : 4] :: int[])
      ;
    elsif i_lambda = '04_repeat_axis'
    then
      v_ret := 
        sm_sc.fv_repeat_axis_py(v_param_1, sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[1 : 1][ : ]) :: int[], sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[2 : 2][ : ]) :: int[])
      ;
    elsif i_lambda = '04_apad'
    then
      v_ret := 
        sm_sc.fv_apad(v_param_1, v_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_bpad'
    then
      v_ret := 
        sm_sc.fv_bpad(v_param_1, v_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_lpad'
    then
      v_ret := 
        sm_sc.fv_lpad(v_param_1, v_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_rpad'
    then
      v_ret := 
        sm_sc.fv_lpad(v_param_1, v_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_transpose'
    then
      if i_input_arr_asso is null 
      then 
        v_ret := 
          sm_sc.fv_opr_transpose_py(v_param_1)
        ;
      else 
        v_ret := 
          sm_sc.fv_opr_transpose_py(v_param_1, i_input_arr_asso[1 : 2] :: int[])
        ;
      end if;
    elsif i_lambda = '04_transpose_i'
    then
      v_ret := 
        sm_sc.fv_opr_transpose_i_py(v_param_1)
      ;
    elsif i_lambda = '04_chunk_transpose'
    then
      v_ret := 
        sm_sc.fv_chunk_transpose(v_param_1, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_transpose_nd'
    then
      v_ret := 
        sm_sc.fv_opr_transpose_nd_py(v_param_1, i_input_arr_asso :: int[])
      ;
    elsif i_lambda = '04_turn_90'
    then
      v_ret := 
        sm_sc.fv_opr_turn_90_py(v_param_1, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_turn_180'
    then
      v_ret := 
        sm_sc.fv_opr_turn_180_py(v_param_1, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_mirror'
    then
      v_ret := 
        sm_sc.fv_opr_mirror_py(v_param_1, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_mx_ele_3d_2_2d'
    then
      v_ret := 
        sm_sc.fv_mx_ele_3d_2_2d_py
        (
          v_param_1
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        )
      ;
    elsif i_lambda = '04_mx_ele_2d_2_3d'
    then
      v_ret := 
        sm_sc.fv_mx_ele_2d_2_3d_py
        (
          v_param_1
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        , i_input_arr_asso[3] :: int
        , i_input_arr_asso[4] :: int :: boolean
        )
      ;
    elsif i_lambda = '04_mx_ele_4d_2_3d'
    then
      v_ret := 
        sm_sc.fv_mx_ele_4d_2_3d_py
        (
          v_param_1
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        )
      ;
    elsif i_lambda = '04_mx_ele_3d_2_4d'
    then
      v_ret := 
        sm_sc.fv_mx_ele_3d_2_4d_py
        (
          v_param_1
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        , i_input_arr_asso[3] :: int
        , i_input_arr_asso[4] :: int :: boolean
        )
      ;
    elsif i_lambda = '04_mx_ele_flatten_2dims'
    then
      v_ret := 
        sm_sc.fv_mx_ele_flatten_2dims_py
        (
          v_param_1
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        )
      ;
    elsif i_lambda = '04_mx_slice_3d_2_2d'
    then
      v_ret := 
        sm_sc.fv_mx_slice_3d_2_2d_py(v_param_1, i_input_arr_asso[1] :: int, i_input_arr_asso[2] :: int)
      ;
    elsif i_lambda = '04_mx_slice_4d_2_2d'
    then
      v_ret := 
        sm_sc.fv_mx_slice_4d_2_2d_py(v_param_1, sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[1 : 1][1 : 2]) :: int[], sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[2 : 2][1 : 2]) :: int[])
      ;
    elsif i_lambda = '04_mx_slice_4d_2_3d'
    then
      v_ret := 
        sm_sc.fv_mx_slice_4d_2_3d_py(v_param_1, i_input_arr_asso[1] :: int, i_input_arr_asso[2] :: int)
      ;
    elsif i_lambda = '04_mx_ascend_dim'
    then
      v_ret := 
        sm_sc.fv_mx_ascend_dim(v_param_1, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_mx_descend_dim'
    then
      v_ret := 
        sm_sc.fv_mx_descend_dim_py(v_param_1, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_rand_pick_y'
    then
      v_ret := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_y_pick(v_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_rand_pick_x'
    then
      v_ret := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_x_pick(v_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_rand_pick_x3'
    then
      v_ret := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_x3_pick(v_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_rand_pick_x4'
    then
      v_ret := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_x4_pick(v_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_chunk'
    then
      v_ret := 
        sm_sc.fv_chunk
        (
          v_param_1
        , i_input_arr_asso :: int[]
        )
      ;
    elsif i_lambda = '04_slice_y'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_slice_y
          (
            v_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_slice_x
          (
            v_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x3'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_slice_x3
          (
            v_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x4'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_slice_x4
          (
            v_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_y'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_sample_y    -- fv_sample_y_py
          (
            v_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(v_param_2, case array_ndims(v_param_1) when 1 then array[0.0] when 2 then array[[0.0]] when 3 then array[[[0.0]]] when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_sample_x    -- fv_sample_x_py
          (
            v_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(v_param_2, case array_ndims(v_param_1) when 2 then array[[0.0]] when 3 then array[[[0.0]]] when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x3'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_sample_x3   -- fv_sample_x3_py
          (
            v_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(v_param_2, case array_ndims(v_param_1) when 3 then array[[[0.0]]] when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x4'
    then
      v_ret := 
      (
        select 
          sm_sc.fv_sample_x4      -- fv_sample_x4_py
          (
            v_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(v_param_2, case array_ndims(v_param_1) when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_lower_tri_mx'
    then
      v_ret := sm_sc.fv_lower_tri_mx(v_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_upper_tri_mx'
    then
      v_ret := sm_sc.fv_upper_tri_mx(v_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_lower_tri_mx_ex'
    then
      v_ret := sm_sc.fv_lower_tri_mx_ex(v_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_upper_tri_mx_ex'
    then
      v_ret := sm_sc.fv_upper_tri_mx_ex(v_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_lmask'
    then
      v_ret := sm_sc.fv_lmask(v_param_1, v_param_2 :: int[], i_input_arr_asso[1]);
    elsif i_lambda = '04_rmask'
    then
      v_ret := sm_sc.fv_rmask(v_param_1, v_param_2 :: int[], i_input_arr_asso[1]);
    elsif i_lambda = '04_amask'
    then
      v_ret := sm_sc.fv_amask(v_param_1, v_param_2 :: int[], i_input_arr_asso[1]);
    elsif i_lambda = '04_bmask'
    then
      v_ret := sm_sc.fv_bmask(v_param_1, v_param_2 :: int[], i_input_arr_asso[1]);
    end if;
    
  elsif i_lambda like '03_%'
  then 
    if i_lambda = '03_sigmoid'
    then 
      v_ret := 
        sm_sc.fv_activate_sigmoid(v_param_1)
      ;
    elsif i_lambda = '03_absqrt'
    then 
      v_ret := 
        sm_sc.fv_activate_absqrt_py(v_param_1, i_input_arr_asso[1 : 2])
      ;
    elsif i_lambda = '03_relu'
    then
      v_ret := 
        sm_sc.fv_activate_relu(v_param_1)
      ;
    elsif i_lambda = '03_leaky_relu'
    then
      v_ret := 
        sm_sc.fv_activate_leaky_relu(v_param_1, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_elu'
    then
      v_ret := 
        sm_sc.fv_activate_elu(v_param_1, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_selu'
    then
      v_ret := 
        sm_sc.fv_activate_selu(v_param_1)
      ;
    elsif i_lambda = '03_gelu'
    then
      v_ret := 
        sm_sc.fv_activate_gelu(v_param_1)
      ;
    elsif i_lambda = '03_swish'
    then
      v_ret := 
        sm_sc.fv_activate_swish(v_param_1)
      ;
    elsif i_lambda = '03_softplus'
    then
      v_ret := 
        sm_sc.fv_activate_softplus(v_param_1)
      ;
    elsif i_lambda = '03_boxcox'
    then
      v_ret := 
        sm_sc.fv_activate_boxcox(v_param_1, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_softmax'
    then
      v_ret := 
        sm_sc.fv_redistr_softmax_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '03_softmax_ex'
    then
      v_ret := 
        sm_sc.fv_redistr_softmax_ex_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '03_zscore'
    then
      v_ret := 
        sm_sc.fv_redistr_zscore_py(v_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    end if;
    
  elsif i_lambda like '02_%'
  then 
    if i_lambda = '02_sin'
    then
      v_ret := 
        sm_sc.fv_sin(v_param_1)
      ;
    elsif i_lambda = '02_cos'
    then
      v_ret := 
        sm_sc.fv_cos(v_param_1)
      ;
    elsif i_lambda = '02_tan'
    then
      v_ret := 
        sm_sc.fv_tan(v_param_1)
      ;
    elsif i_lambda = '02_cot'
    then
      v_ret := 
        sm_sc.fv_cot(v_param_1)
      ;
    elsif i_lambda = '02_sec'
    then
      v_ret := 
        sm_sc.fv_sec(v_param_1)
      ;
    elsif i_lambda = '02_csc'
    then
      v_ret := 
        sm_sc.fv_csc(v_param_1)
      ;
    elsif i_lambda = '02_asin'
    then
      v_ret := 
        sm_sc.fv_asin(v_param_1)
      ;
    elsif i_lambda = '02_acos'
    then
      v_ret := 
        sm_sc.fv_acos(v_param_1)
      ;
    elsif i_lambda = '02_atan'
    then
      v_ret := 
        sm_sc.fv_atan(v_param_1)
      ;
    elsif i_lambda = '02_acot'
    then
      v_ret := 
        sm_sc.fv_acot(v_param_1)
      ;
    elsif i_lambda = '02_sinh'
    then
      v_ret := 
        sm_sc.fv_sinh(v_param_1)
      ;
    elsif i_lambda = '02_cosh'
    then
      v_ret := 
        sm_sc.fv_cosh(v_param_1)
      ;
    elsif i_lambda = '02_tanh'
    then
      v_ret := 
        sm_sc.fv_tanh(v_param_1)
      ;
    -- -- elsif i_lambda = '02_sech'
    -- -- then
    -- --   v_ret := 
    -- --     sm_sc.fv_sech(v_param_1)
    -- --   ;
    -- -- elsif i_lambda = '02_csch'
    -- -- then
    -- --   v_ret := 
    -- --     sm_sc.fv_csch(v_param_1)
    -- --   ;
    elsif i_lambda = '02_asinh'
    then
      v_ret := 
        sm_sc.fv_asinh(v_param_1)
      ;
    elsif i_lambda = '02_acosh'
    then
      v_ret := 
        sm_sc.fv_acosh(v_param_1)
      ;
    elsif i_lambda = '02_atanh'
    then
      v_ret := 
        sm_sc.fv_atanh(v_param_1)
      ;
    end if;
    
  elsif i_lambda like '01_%'
  then 
    if i_lambda = '01_add'
    then 
      v_ret := 
        sm_sc.fv_opr_add_py(v_param_1, v_param_2)
      ;
    elsif i_lambda = '01_mul'
    then
      v_ret := 
        sm_sc.fv_opr_mul_py(v_param_1, v_param_2)
      ;
    elsif i_lambda = '01_sub'
    then
      v_ret := 
        sm_sc.fv_opr_sub_py(v_param_1, v_param_2)
      ;
    elsif i_lambda = '01_0sub'
    then
      v_ret := 
        sm_sc.fv_opr_sub_py(v_param_1)
      ;
    elsif i_lambda = '01_div'
    then
      v_ret := 
        sm_sc.fv_opr_div_py(v_param_1, v_param_2)
      ;
    elsif i_lambda = '01_1div'
    then
      v_ret := 
        sm_sc.fv_opr_div_py(v_param_1)
      ;
    elsif i_lambda = '01_pow'
    then
      v_ret := 
        sm_sc.fv_opr_pow_py(v_param_1, v_param_2)
      ;
    elsif i_lambda = '01_log'
    then
      v_ret := 
        sm_sc.fv_opr_log_py(v_param_1, v_param_2)
      ;
    elsif i_lambda = '01_exp'
    then
      v_ret := 
        sm_sc.fv_opr_exp_py(v_param_1)
      ;
    elsif i_lambda = '01_ln'
    then
      v_ret := 
        sm_sc.fv_opr_ln_py(v_param_1)
      ;
    elsif i_lambda = '01_abs'
    then
      v_ret := 
        sm_sc.fv_opr_abs_py(v_param_1)
      ;
    elsif i_lambda = '01_prod_mx'
    then
      v_ret := 
        -- sm_sc.fv_opr_prod_mx_py(v_param_1, v_param_2)
        v_param_1 |**| v_param_2
      ;
    elsif i_lambda = '01_chunk_prod_mx'
    then
      v_ret := 
        sm_sc.fv_chunk_prod_mx(v_param_1, v_param_2,  i_input_arr_asso[1 : 3] :: int[])
      ;
    end if;
    
  elsif i_lambda like '00_%'
  then 
  
    if i_lambda = '00_none'
    then
      v_ret := 
        sm_sc.fv_nn_none(v_param_1)
      ;

    -- -- elsif i_lambda = '00_const'
    -- -- then 
    -- --   return 
    -- --     -- (select node_depdt_vals from sm_sc.tb_nn_node where node_no = i_node_no and work_no = i_work_no)
    -- --   ;

    -- -- -- 出于减少数据拷贝、内存交换、资源开销的优化目的，nn input 节点的数据准备不在 lambda 执行。
    -- -- elsif i_lambda = '00_full_dataset'
    -- -- then 
    -- --   return 
    -- --   (
    -- --     select 
    -- --       array_agg(i_indepdt order by ord_no)
    -- --     from sm_sc.tb_nn_train_input_buff 
    -- --     where work_no = (select work_no from sm_sc.tb_nn_node where node_no = i_node_no)
    -- --   );
    -- -- 
    -- -- elsif i_lambda = '00_buff_slice_rand_pick'
    -- -- then 
    -- --   return 
    -- --     -- sm_sc.ft_nn_buff_slice_rand_pick()
    -- --   ;
    
    end if;
    
  elsif i_lambda like '81_%'
  then 
    return 
      sm_sc.__fv_set_kv
      (
        sm_sc.ufv_lambda_arr
        (
          i_node_no       
        , i_lambda        
        , v_param_1       
        , v_param_2       
        , i_input_arr_asso
        , v_param_3       
        )
      )
    ;
    
  end if;
  
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if v_ret is null
      -- or sm_sc.fv_aggr_slice_is_exists_null(v_ret) is true
    then 
      raise exception 'there is null value in returning!  i_node_no: %.  ', i_node_no;
    elsif 'NaN' :: float = any(v_ret)
    then 
      raise exception 'there is NaN value in returning!  i_node_no: %.  ', i_node_no;
    end if;
  end if;

-- -- debug 
-- raise notice 'd:lambda % end:: i_lambda: %; time: %; use time: %;', i_node_no, i_lambda, to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS.MS'), v_begin_clock - clock_timestamp();
  
  return 
    sm_sc.__fv_set_kv
    (
      v_ret
    , i_model_code_6 || 
      '_' || i_work_no :: varchar ||
      '_' || i_node_no :: varchar ||
      '__d__' || -- 'depdt'
      coalesce(i_sess_id :: varchar, '')
    )
  ;

--   return v_ret;

  exception when others then
    raise exception 
    ' fn: sm_sc.fv_lambda_arr_p
      i_node_no: %
      i_lambda: %
      len of v_param_1: %
      len of v_param_2: %
      i_input_arr_asso: %
      sqlerrm: %
    '
    , i_node_no
    , i_lambda
    , array_dims(v_param_1)
    , array_dims(v_param_2)
    , i_input_arr_asso
    , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_lambda_arr_p
--   (
--     100001
--     , '03_elu'
--     , array[[1.23, 3.34],[-7.2, -0.25]]
--     , null
--     , array[0.1]
--   );





