-- drop function if exists sm_sc.fv_lambda_arr(bigint, varchar(64), float[], float[][], float[], float[][]);
create or replace function sm_sc.fv_lambda_arr
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
 
 -- -- debug 
 -- v_begin_clock    timestamp     := clock_timestamp();
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
  
  if i_lambda like '07_%'
  then 
    if i_lambda = '07_aggr_slice_sum'
    then 
      _v_debug := 
        sm_sc.fv_aggr_slice_sum_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_prod'
    then
      _v_debug := 
        sm_sc.fv_aggr_slice_prod_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_avg'
    then
      _v_debug := 
        sm_sc.fv_aggr_slice_avg_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_max'
    then
      _v_debug := 
        sm_sc.fv_aggr_slice_max_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_slice_min'
    then
      _v_debug := 
        sm_sc.fv_aggr_slice_min_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_sum'
    then 
      _v_debug := 
        sm_sc.fv_aggr_chunk_sum(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_prod'
    then
      _v_debug := 
        sm_sc.fv_aggr_chunk_prod(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_avg'
    then
      _v_debug := 
        sm_sc.fv_aggr_chunk_avg(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_max'
    then
      _v_debug := 
        sm_sc.fv_aggr_chunk_max(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '07_aggr_chunk_min'
    then
      _v_debug := 
        sm_sc.fv_aggr_chunk_min(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    end if;
    
  -- -- elsif i_lambda like '06_%'
  -- -- then 
  -- --   if i_lambda = '06_aggr_mx_sum'
  -- --   then 
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_prod'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_avg'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_max'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_min'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_y'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_x'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_x3'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   elsif i_lambda = '06_aggr_mx_concat_x4'
  -- --   then
  -- --     _v_debug := 
  -- --       
  -- --     ;
  -- --   end if;
    
  elsif i_lambda like '05_%'
  then 
    if i_lambda = '05_pool_max_2d_grp_x'
    then 
      _v_debug := 
        sm_sc.fv_pool_max_2d_grp_x
        (
          i_param_1                                                           ,   
          i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_avg_2d_grp_x'
    then
      _v_debug := 
        sm_sc.fv_pool_avg_2d_grp_x
        (
          i_param_1                                                           ,   
          i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_max'
    then
      _v_debug := 
        sm_sc.fv_pool_max_py
        (
          i_param_1                                                           ,   
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_avg'
    then
      _v_debug := 
        sm_sc.fv_pool_avg_py
        (
          i_param_1                                                           ,   
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_none'
    then
      _v_debug := 
        sm_sc.fv_pool_none_py
        (
          i_param_1                                                           ,   
          i_input_arr_asso[2 : 3] :: int[]                                        ,   -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_2d_grp_x'
    then
      _v_debug := 
        sm_sc.fv_conv_2d_grp_x
        (
          i_param_1   :: float[]                                     ,   
          i_input_arr_asso[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_param_2           :: float[]                                     ,   
          i_input_arr_asso[3] :: int                                              ,   -- 规约：存放 i_window_len_x 
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_2d'
    then
      _v_debug := 
        sm_sc.fv_conv_2d_im2col_py
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          i_param_3                                              ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_tunnel_conv'
    then
      _v_debug := 
        sm_sc.fv_tunnel_conv_py
        (
          i_param_1                 
        , i_param_2                  
        , i_input_arr_asso[1] :: int        -- 规约：存放 i_tunnel_axis         
        , i_param_3              
        )
      ;
    elsif i_lambda = '05_conv_add'
    then
      _v_debug := 
        sm_sc.fv_conv_add
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_sub'
    then
      _v_debug := 
        sm_sc.fv_conv_sub
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_mul'
    then
      _v_debug := 
        sm_sc.fv_conv_mul
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_div'
    then
      _v_debug := 
        sm_sc.fv_conv_div
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_pow'
    then
      _v_debug := 
        sm_sc.fv_conv_pow
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_log'
    then
      _v_debug := 
        sm_sc.fv_conv_log
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_prod_mx'
    then
      _v_debug := 
        sm_sc.fv_conv_prod_mx
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
          i_input_arr_asso[2] :: int                                        ,   -- 规约：存放 i_window_len_heigh
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_sub'
    then
      _v_debug := 
        sm_sc.fv_conv_de_sub
        (
          i_param_1   :: float[]                                     ,   -- 窗口
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_div'
    then
      _v_debug := 
        sm_sc.fv_conv_de_div
        (
          i_param_1   :: float[]                                     ,   -- 窗口
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_pow'
    then
      _v_debug := 
        sm_sc.fv_conv_de_pow
        (
          i_param_1   :: float[]                                     ,   -- 窗口
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_log'
    then
      _v_debug := 
        sm_sc.fv_conv_de_log
        (
          i_param_1   :: float[]                                     ,   -- 窗口
          i_param_2           :: float[]                                     ,   
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
          coalesce(i_input_arr_asso[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_conv_de_prod_mx'
    then
      _v_debug := 
        sm_sc.fv_conv_de_prod_mx
        (
          i_param_1   :: float[]                                     ,   
          i_param_2           :: float[]                                     ,   
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
      _v_debug := 
        sm_sc.fv_new(i_param_1, i_input_arr_asso[1 : 4] :: int[])
      ;
    elsif i_lambda = '04_reshape'
    then 
      i_input_arr_asso := 
        (
          sm_sc.fv_coalesce
          (
            i_input_arr_asso
          , (select array_agg(array_length(i_param_1, a_no) order by a_no) :: float[] from generate_series(1, array_ndims(i_param_1)) tb_a(a_no))
          )
        )
          [1 : array_length(i_input_arr_asso, 1)]
      ;
      _v_debug := 
        sm_sc.fv_opr_reshape_py(i_param_1, i_input_arr_asso[1 : 4] :: int[])
      ;
    elsif i_lambda = '04_repeat_axis'
    then
      _v_debug := 
        sm_sc.fv_repeat_axis_py(i_param_1, sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[1 : 1][ : ]) :: int[], sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[2 : 2][ : ]) :: int[])
      ;
    elsif i_lambda = '04_apad'
    then
      _v_debug := 
        sm_sc.fv_apad(i_param_1, i_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_bpad'
    then
      _v_debug := 
        sm_sc.fv_bpad(i_param_1, i_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_lpad'
    then
      _v_debug := 
        sm_sc.fv_lpad(i_param_1, i_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_rpad'
    then
      _v_debug := 
        sm_sc.fv_lpad(i_param_1, i_param_2, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_transpose'
    then
      if i_input_arr_asso is null 
      then 
        _v_debug := 
          sm_sc.fv_opr_transpose_py(i_param_1)
        ;
      else 
        _v_debug := 
          sm_sc.fv_opr_transpose_py(i_param_1, i_input_arr_asso[1 : 2] :: int[])
        ;
      end if;
    elsif i_lambda = '04_transpose_i'
    then
      _v_debug := 
        sm_sc.fv_opr_transpose_i_py(i_param_1)
      ;
    elsif i_lambda = '04_chunk_transpose'
    then
      _v_debug := 
        sm_sc.fv_chunk_transpose(i_param_1, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_transpose_nd'
    then
      _v_debug := 
        sm_sc.fv_opr_transpose_nd_py(i_param_1, i_input_arr_asso :: int[])
      ;
    elsif i_lambda = '04_turn_90'
    then
      _v_debug := 
        sm_sc.fv_opr_turn_90_py(i_param_1, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_turn_180'
    then
      _v_debug := 
        sm_sc.fv_opr_turn_180_py(i_param_1, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_mirror'
    then
      _v_debug := 
        sm_sc.fv_opr_mirror_py(i_param_1, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_mx_ele_3d_2_2d'
    then
      _v_debug := 
        sm_sc.fv_mx_ele_3d_2_2d_py
        (
          i_param_1
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        )
      ;
    elsif i_lambda = '04_mx_ele_2d_2_3d'
    then
      _v_debug := 
        sm_sc.fv_mx_ele_2d_2_3d_py
        (
          i_param_1
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        , i_input_arr_asso[3] :: int
        , i_input_arr_asso[4] :: int :: boolean
        )
      ;
    elsif i_lambda = '04_mx_ele_4d_2_3d'
    then
      _v_debug := 
        sm_sc.fv_mx_ele_4d_2_3d_py
        (
          i_param_1
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        )
      ;
    elsif i_lambda = '04_mx_ele_3d_2_4d'
    then
      _v_debug := 
        sm_sc.fv_mx_ele_3d_2_4d_py
        (
          i_param_1
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        , i_input_arr_asso[3] :: int
        , i_input_arr_asso[4] :: int :: boolean
        )
      ;
    elsif i_lambda = '04_mx_ele_flatten_2dims'
    then
      _v_debug := 
        sm_sc.fv_mx_ele_flatten_2dims_py
        (
          i_param_1
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        )
      ;
    elsif i_lambda = '04_mx_slice_3d_2_2d'
    then
      _v_debug := 
        sm_sc.fv_mx_slice_3d_2_2d_py(i_param_1, i_input_arr_asso[1] :: int, i_input_arr_asso[2] :: int)
      ;
    elsif i_lambda = '04_mx_slice_4d_2_2d'
    then
      _v_debug := 
        sm_sc.fv_mx_slice_4d_2_2d_py(i_param_1, sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[1 : 1][1 : 2]) :: int[], sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[2 : 2][1 : 2]) :: int[])
      ;
    elsif i_lambda = '04_mx_slice_4d_2_3d'
    then
      _v_debug := 
        sm_sc.fv_mx_slice_4d_2_3d_py(i_param_1, i_input_arr_asso[1] :: int, i_input_arr_asso[2] :: int)
      ;
    elsif i_lambda = '04_mx_ascend_dim'
    then
      _v_debug := 
        sm_sc.fv_mx_ascend_dim(i_param_1, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_mx_descend_dim'
    then
      _v_debug := 
        sm_sc.fv_mx_descend_dim_py(i_param_1, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_rand_pick_y'
    then
      _v_debug := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_y_pick(i_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_rand_pick_x'
    then
      _v_debug := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_x_pick(i_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_rand_pick_x3'
    then
      _v_debug := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_x3_pick(i_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_rand_pick_x4'
    then
      _v_debug := 
      (
        select 
          o_slices
        from sm_sc.ft_rand_slice_x4_pick(i_param_1, i_input_arr_asso[1] :: int)
      )
      ;
    elsif i_lambda = '04_chunk'
    then
      _v_debug := 
        sm_sc.fv_chunk
        (
          i_param_1
        , i_input_arr_asso :: int[]
        )
      ;
    elsif i_lambda = '04_slice_y'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_slice_y
          (
            i_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_slice_x
          (
            i_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x3'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_slice_x3
          (
            i_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x4'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_slice_x4
          (
            i_param_1
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_y'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_sample_y    -- fv_sample_y_py
          (
            i_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(i_param_2, case array_ndims(i_param_1) when 1 then array[0.0] when 2 then array[[0.0]] when 3 then array[[[0.0]]] when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_sample_x    -- fv_sample_x_py
          (
            i_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(i_param_2, case array_ndims(i_param_1) when 2 then array[[0.0]] when 3 then array[[[0.0]]] when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x3'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_sample_x3    -- fv_sample_x3_py
          (
            i_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(i_param_2, case array_ndims(i_param_1) when 3 then array[[[0.0]]] when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x4'
    then
      _v_debug := 
      (
        select 
          sm_sc.fv_sample_x4     -- fv_sample_x4_py
          (
            i_param_1
          , i_input_arr_asso[1][1] :: int
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          , coalesce(i_param_2, case array_ndims(i_param_1) when 4 then array[[[[0.0]]]] end)
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_lower_tri_mx'
    then
      _v_debug := sm_sc.fv_lower_tri_mx(i_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_upper_tri_mx'
    then
      _v_debug := sm_sc.fv_upper_tri_mx(i_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_lower_tri_mx_ex'
    then
      _v_debug := sm_sc.fv_lower_tri_mx_ex(i_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_upper_tri_mx_ex'
    then
      _v_debug := sm_sc.fv_upper_tri_mx_ex(i_param_1, i_input_arr_asso[1]);
    elsif i_lambda = '04_lmask'
    then
      _v_debug := sm_sc.fv_lmask(i_param_1, i_param_2 :: int[], i_input_arr_asso[1]);
    elsif i_lambda = '04_rmask'
    then
      _v_debug := sm_sc.fv_rmask(i_param_1, i_param_2 :: int[], i_input_arr_asso[1]);
    elsif i_lambda = '04_amask'
    then
      _v_debug := sm_sc.fv_amask(i_param_1, i_param_2 :: int[], i_input_arr_asso[1]);
    elsif i_lambda = '04_bmask'
    then
      _v_debug := sm_sc.fv_bmask(i_param_1, i_param_2 :: int[], i_input_arr_asso[1]);
    end if;
    
  elsif i_lambda like '03_%'
  then 
    if i_lambda = '03_sigmoid'
    then 
      _v_debug := 
        sm_sc.fv_activate_sigmoid(i_param_1)
      ;
    elsif i_lambda = '03_absqrt'
    then
      _v_debug := 
        sm_sc.fv_activate_absqrt_py(i_param_1, i_input_arr_asso[1 : 2])
      ;
    elsif i_lambda = '03_relu'
    then
      _v_debug := 
        sm_sc.fv_activate_relu(i_param_1)
      ;
    elsif i_lambda = '03_leaky_relu'
    then
      _v_debug := 
        sm_sc.fv_activate_leaky_relu(i_param_1, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_elu'
    then
      _v_debug := 
        sm_sc.fv_activate_elu(i_param_1, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_selu'
    then
      _v_debug := 
        sm_sc.fv_activate_selu(i_param_1)
      ;
    elsif i_lambda = '03_gelu'
    then
      _v_debug := 
        sm_sc.fv_activate_gelu(i_param_1)
      ;
    elsif i_lambda = '03_swish'
    then
      _v_debug := 
        sm_sc.fv_activate_swish(i_param_1)
      ;
    elsif i_lambda = '03_softplus'
    then
      _v_debug := 
        sm_sc.fv_activate_softplus(i_param_1)
      ;
    elsif i_lambda = '03_boxcox'
    then
      _v_debug := 
        sm_sc.fv_activate_boxcox(i_param_1, i_input_arr_asso[1])
      ;
    elsif i_lambda = '03_softmax'
    then
      _v_debug := 
        sm_sc.fv_redistr_softmax_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '03_softmax_ex'
    then
      _v_debug := 
        sm_sc.fv_redistr_softmax_ex_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '03_zscore'
    then
      _v_debug := 
        sm_sc.fv_redistr_zscore_py(i_param_1, i_input_arr_asso[1 : 6] :: int[])
      ;
    end if;
    
  elsif i_lambda like '02_%'
  then 
    if i_lambda = '02_sin'
    then
      _v_debug := 
        sm_sc.fv_sin_py(i_param_1)
      ;
    elsif i_lambda = '02_cos'
    then
      _v_debug := 
        sm_sc.fv_cos_py(i_param_1)
      ;
    elsif i_lambda = '02_tan'
    then
      _v_debug := 
        sm_sc.fv_tan_py(i_param_1)
      ;
    elsif i_lambda = '02_cot'
    then
      _v_debug := 
        sm_sc.fv_cot(i_param_1)
      ;
    elsif i_lambda = '02_sec'
    then
      _v_debug := 
        sm_sc.fv_sec(i_param_1)
      ;
    elsif i_lambda = '02_csc'
    then
      _v_debug := 
        sm_sc.fv_csc(i_param_1)
      ;
    elsif i_lambda = '02_asin'
    then
      _v_debug := 
        sm_sc.fv_asin(i_param_1)
      ;
    elsif i_lambda = '02_acos'
    then
      _v_debug := 
        sm_sc.fv_acos(i_param_1)
      ;
    elsif i_lambda = '02_atan'
    then
      _v_debug := 
        sm_sc.fv_atan(i_param_1)
      ;
    elsif i_lambda = '02_acot'
    then
      _v_debug := 
        sm_sc.fv_acot(i_param_1)
      ;
    elsif i_lambda = '02_sinh'
    then
      _v_debug := 
        sm_sc.fv_sinh_py(i_param_1)
      ;
    elsif i_lambda = '02_cosh'
    then
      _v_debug := 
        sm_sc.fv_cosh_py(i_param_1)
      ;
    elsif i_lambda = '02_tanh'
    then
      _v_debug := 
        sm_sc.fv_tanh_py(i_param_1)
      ;
    -- -- elsif i_lambda = '02_sech'
    -- -- then
    -- --   _v_debug := 
    -- --     sm_sc.fv_sech(i_param_1)
    -- --   ;
    -- -- elsif i_lambda = '02_csch'
    -- -- then
    -- --   _v_debug := 
    -- --     sm_sc.fv_csch(i_param_1)
    -- --   ;
    elsif i_lambda = '02_asinh'
    then
      _v_debug := 
        sm_sc.fv_asinh(i_param_1)
      ;
    elsif i_lambda = '02_acosh'
    then
      _v_debug := 
        sm_sc.fv_acosh(i_param_1)
      ;
    elsif i_lambda = '02_atanh'
    then
      _v_debug := 
        sm_sc.fv_atanh(i_param_1)
      ;
    end if;
    
  elsif i_lambda like '01_%'
  then 
    if i_lambda = '01_add'
    then 
      _v_debug := 
        sm_sc.fv_opr_add_py(i_param_1, i_param_2)
      ;
    elsif i_lambda = '01_mul'
    then
      _v_debug := 
        sm_sc.fv_opr_mul_py(i_param_1, i_param_2)
      ;
    elsif i_lambda = '01_sub'
    then
      _v_debug := 
        sm_sc.fv_opr_sub_py(i_param_1, i_param_2)
      ;
    elsif i_lambda = '01_0sub'
    then
      _v_debug := 
        sm_sc.fv_opr_sub_py(i_param_1)
      ;
    elsif i_lambda = '01_div'
    then
      _v_debug := 
        sm_sc.fv_opr_div_py(i_param_1, i_param_2)
      ;
    elsif i_lambda = '01_1div'
    then
      _v_debug := 
        sm_sc.fv_opr_div_py(i_param_1)
      ;
    elsif i_lambda = '01_pow'
    then
      _v_debug := 
        sm_sc.fv_opr_pow_py(i_param_1, i_param_2)
      ;
    elsif i_lambda = '01_log'
    then
      _v_debug := 
        sm_sc.fv_opr_log_py(i_param_1, i_param_2)
      ;
    elsif i_lambda = '01_exp'
    then
      _v_debug := 
        sm_sc.fv_opr_exp_py(i_param_1)
      ;
    elsif i_lambda = '01_ln'
    then
      _v_debug := 
        sm_sc.fv_opr_ln_py(i_param_1)
      ;
    elsif i_lambda = '01_abs'
    then
      _v_debug := 
        sm_sc.fv_opr_abs_py(i_param_1)
      ;
    elsif i_lambda = '01_prod_mx'
    then
      _v_debug := 
        -- sm_sc.fv_opr_prod_mx_py(i_param_1, i_param_2)
        i_param_1 |**| i_param_2
      ;
    elsif i_lambda = '01_chunk_prod_mx'
    then
      _v_debug := 
        sm_sc.fv_chunk_prod_mx(i_param_1, i_param_2,  i_input_arr_asso[1 : 3] :: int[])
      ;
    end if;
    
  elsif i_lambda like '00_%'
  then 
  
    if i_lambda = '00_none'
    then
      _v_debug := 
        sm_sc.fv_nn_none(i_param_1)
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
      sm_sc.ufv_lambda_arr
      (
        i_node_no       
      , i_lambda        
      , i_param_1       
      , i_param_2       
      , i_input_arr_asso
      , i_param_3       
      )
    ;
    
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


-- -- debug 
-- raise notice 'i_node_no: %; i_lambda: %; time: %;', i_node_no, i_lambda, v_begin_clock - clock_timestamp();

  exception when others then
    raise exception 
    ' fn: sm_sc.fv_lambda_arr
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
--   sm_sc.fv_lambda_arr
--   (
--     100001
--     , '03_elu'
--     , array[[1.23, 3.34],[-7.2, -0.25]]
--     , null
--     , array[0.1]
--   );





