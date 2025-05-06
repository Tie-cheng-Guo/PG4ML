-- 本函数以数组为入参，标量版本参考 sm_sc.fv_gradient_opr
-- 对于 conv_2d, pool_max, pool_avg, softmax, zscore 本函数求取 dloss/dindepdt, 而不是求取 ddepdt/dindepdt
-- drop function if exists sm_sc.fv_lambda_arr_dloss_dindepdt(bigint, varchar(64), float[], int, float[], float[], float[], int, float[]);
create or replace function sm_sc.fv_lambda_arr_dloss_dindepdt
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
 
 -- -- debug 
 -- v_begin_clock    timestamp     := clock_timestamp();
begin
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
  
  if i_lambda like '07_%'
  then 
    if i_lambda = '07_aggr_slice_sum'
    then 
      return 
        sm_sc.fv_d_aggr_slice_sum_dloss_dindepdt_py(v_indepdt_var_len, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_slice_prod'
    then
      return 
        sm_sc.fv_d_aggr_slice_prod_dloss_dindepdt_py(i_indepdt_var, i_depdt_var, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_slice_avg'
    then
      return 
        sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py(v_indepdt_var_len, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_slice_max'
    then
      return 
        sm_sc.fv_d_aggr_slice_max_dloss_dindepdt_py(i_indepdt_var, i_depdt_var, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_slice_min'
    then
      return 
        sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py(i_indepdt_var, i_depdt_var, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_chunk_sum'
    then 
      return 
        sm_sc.fv_d_aggr_chunk_sum_dloss_dindepdt(i_input_arr_asso[1 : 6] :: int[], i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_chunk_prod'
    then
      return 
        sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt(i_indepdt_var, i_depdt_var, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_chunk_avg'
    then
      return 
        sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt(i_input_arr_asso[1 : 6] :: int[], i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_chunk_max'
    then
      return 
        sm_sc.fv_d_aggr_chunk_max_dloss_dindepdt(i_indepdt_var, i_depdt_var, i_dloss_ddepdt)
      ;
    elsif i_lambda = '07_aggr_chunk_min'
    then
      return 
        sm_sc.fv_d_aggr_chunk_min_dloss_dindepdt(i_indepdt_var, i_depdt_var, i_dloss_ddepdt)
      ;
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;
    
  elsif i_lambda like '06_%'
  then 
    if i_lambda = '06_aggr_mx_concat_y'
    then
      return 
      (
        with recursive 
        cte_idx as 
        (
          select 
            1 :: int as a_cur,
            0 :: int as a_accum_len
          union all 
          select 
            a_cur + 1 as a_cur, 
            a_accum_len + i_input_arr_asso[a_cur] :: int as a_accum_len
          from cte_idx
          where a_cur <= i_indepdt_var_loc - 1  -- array_length(i_input_arr_asso, 1)
        )
        select 
          sm_sc.fv_d_mx_concat_y_dloss_dindepdt_n
          (
            i_dloss_ddepdt, 
            a_accum_len + 1, 
            a_accum_len + i_input_arr_asso[i_indepdt_var_loc] :: int,
            v_indepdt_var_len
          )
        from cte_idx
        where a_cur = i_indepdt_var_loc
      )
      ;
    elsif i_lambda = '06_aggr_mx_concat_x'
    then
      return 
      (
        with recursive 
        cte_idx as 
        (
          select 
            1 :: int as a_cur,
            0 :: int as a_accum_len
          union all 
          select 
            a_cur + 1 as a_cur, 
            a_accum_len + i_input_arr_asso[a_cur] :: int as a_accum_len
          from cte_idx
          where a_cur <= i_indepdt_var_loc - 1  -- array_length(i_input_arr_asso, 1)
        )
        select 
          sm_sc.fv_d_mx_concat_x_dloss_dindepdt_n
          (
            i_dloss_ddepdt, 
            a_accum_len + 1, 
            a_accum_len + i_input_arr_asso[i_indepdt_var_loc] :: int,
            v_indepdt_var_len
          )
        from cte_idx
        where a_cur = i_indepdt_var_loc
      )
      ;
    elsif i_lambda = '06_aggr_mx_concat_x3'
    then
      return 
      (
        with recursive 
        cte_idx as 
        (
          select 
            1 :: int as a_cur,
            0 :: int as a_accum_len
          union all 
          select 
            a_cur + 1 as a_cur, 
            a_accum_len + i_input_arr_asso[a_cur] :: int as a_accum_len
          from cte_idx
          where a_cur <= i_indepdt_var_loc - 1  -- array_length(i_input_arr_asso, 1)
        )
        select 
          sm_sc.fv_d_mx_concat_x3_dloss_dindepdt_n
          (
            i_dloss_ddepdt, 
            a_accum_len + 1, 
            a_accum_len + i_input_arr_asso[i_indepdt_var_loc] :: int,
            v_indepdt_var_len
          )
        from cte_idx
        where a_cur = i_indepdt_var_loc
      )
      ;
    elsif i_lambda = '06_aggr_mx_concat_x4'
    then
      return 
      (
        with recursive 
        cte_idx as 
        (
          select 
            1 :: int as a_cur,
            0 :: int as a_accum_len
          union all 
          select 
            a_cur + 1 as a_cur, 
            a_accum_len + i_input_arr_asso[a_cur] :: int as a_accum_len
          from cte_idx
          where a_cur <= i_indepdt_var_loc - 1  -- array_length(i_input_arr_asso, 1)
        )
        select 
          sm_sc.fv_d_mx_concat_x4_dloss_dindepdt_n
          (
            i_dloss_ddepdt, 
            a_accum_len + 1, 
            a_accum_len + i_input_arr_asso[i_indepdt_var_loc] :: int,
            v_indepdt_var_len
          )
        from cte_idx
        where a_cur = i_indepdt_var_loc
      )
      ;
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;

  elsif i_lambda like '05_%'
  then 
    if i_lambda = '05_pool_max_2d_grp_x'
    then 
      return 
        sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt
        (
          i_indepdt_var                              ,                                       -- i_array_grp_x
          i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_dloss_ddepdt                         ,
          i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
          i_depdt_var                            ,                                       -- i_depdt_1d_grp
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
          coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_avg_2d_grp_x'
    then
      return 
        sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt
        (
          -- -- i_input_arr_asso[11] :: int         ,                                       -- 规约：存放 i_array_grp_x_len
          i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
          i_dloss_ddepdt                         ,
          i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
        )
      ;
    elsif i_lambda = '05_pool_max'
    then
      return 
        sm_sc.fv_d_pool_max_dloss_dindepdt
        (
          i_indepdt_var                              ,                                       -- i_array
          i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
          i_dloss_ddepdt                         ,
          i_depdt_var                            ,                                       -- i_depdt_1d_grp
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
          coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
        )
      ;
    elsif i_lambda = '05_pool_avg'
    then
      return 
        sm_sc.fv_d_pool_avg_dloss_dindepdt_ex
        (
          -- -- v_indepdt_var_len                 ,                                         -- 规约：自变量规格
          i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
          i_dloss_ddepdt                         ,
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
        )
      ;
    elsif i_lambda = '05_pool_none'
    then
      return 
        sm_sc.fv_d_pool_none_dloss_dindepdt
        (
          v_indepdt_var_len                 ,                                         -- 规约：自变量规格
          i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
          i_dloss_ddepdt                         ,
          coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
          coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
        )
      ;
    elsif i_lambda = '05_conv_2d_grp_x'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1
          (
            i_input_arr_asso[1] :: int          ,                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
            i_dloss_ddepdt                      ,
            i_co_value                          ,                                       -- i_window
            i_input_arr_asso[3] :: int          ,                                       -- 规约：存放 i_window_len_x
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_2
          (
            i_co_value                                                            -- i_array_grp_x
          , i_input_arr_asso[1] :: int                                            -- 规约：存放 i_1d_2_2d_cnt_per_grp
          , i_dloss_ddepdt                      
          , i_input_arr_asso[2 : 3] :: int[]                                      -- 规约：存放 i_window_len
          , i_input_arr_asso[12] :: int :: boolean                                     -- 规约：存放 i_window_bias_label
          , coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )        -- 规约：存放 i_stride
          , coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])        -- 规约：存放 i_padding
          , coalesce(i_input_arr_asso[10] :: float          ,0.0              )        -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_2d'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_2d_dloss_dindepdt_1_ex
          (
            i_dloss_ddepdt,
            i_co_value,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])         -- 规约：存放 i_padding
          , coalesce(i_input_arr_asso[11] :: int ,0                  )                  -- 规约：存放 i_padding_mode
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py
          (
            i_co_value,
            i_dloss_ddepdt,
            i_input_arr_asso[2 : 3] :: int[]    ,                                       -- 规约：存放 i_window_len
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          , coalesce(i_input_arr_asso[11] :: int ,0                  )                  -- 规约：存放 i_padding_mode
          )
        ;
      elsif i_indepdt_var_loc = 3
      then 
        return 
          sm_sc.fv_d_conv_2d_dloss_dindepdt_3(i_dloss_ddepdt, coalesce(v_indepdt_var_len, array[1, 1]))
        ;      
      end if;
    elsif i_lambda = '05_tunnel_conv'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py
          (
            i_dloss_ddepdt
          , v_co_value
          , i_input_arr_asso[1]     -- 规约：存放 i_tunnel_axis      
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py
          (
            i_dloss_ddepdt
          , v_co_value
          , i_indepdt_var_len
          , i_input_arr_asso[1]     -- 规约：存放 i_tunnel_axis       
          )
        ;
      elsif i_indepdt_var_loc = 3
      then 
        return 
          sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3_py
          (
            i_dloss_ddepdt
          , i_indepdt_var_len
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_add'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_add_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_add_dloss_dindepdt_2
          (
        --  i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_sub'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_sub_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_sub_dloss_dindepdt_2
          (
        --  i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_mul'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_mul_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_mul_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_div'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_div_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_div_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_indepdt_var,
        --  v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_pow'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_pow_dloss_dindepdt_1
          (
            i_indepdt_var,
        --  v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_depdt_var,
            array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_pow_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_indepdt_var,
            v_indepdt_var_len,
            i_depdt_var,
            array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_log'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_log_dloss_dindepdt_1
          (
            i_indepdt_var,
            v_indepdt_var_len,
            i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_log_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_indepdt_var,
        --  v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_prod_mx'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_prod_mx_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
            i_input_arr_asso[2] :: int,                                                 -- 规约：存放 i_window_len_heigh
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_prod_mx_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_input_arr_asso[2] :: int,                                                 -- 规约：存放 i_window_len_heigh
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_de_sub'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_de_sub_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_de_sub_dloss_dindepdt_2
          (
        --  i_co_value,
            array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_indepdt_var,
            v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_de_div'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_de_div_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_de_div_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_indepdt_var,
        --  v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_de_pow'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_de_pow_dloss_dindepdt_1
          (
            i_indepdt_var,
        --  v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_depdt_var,
            array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_indepdt_var,
            v_indepdt_var_len,
            i_depdt_var,
            array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_de_log'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_de_log_dloss_dindepdt_1
          (
            i_indepdt_var,
        --  v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_de_log_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_indepdt_var,
        --  v_indepdt_var_len,
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    elsif i_lambda = '05_conv_de_prod_mx'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_conv_de_prod_mx_dloss_dindepdt_1
          (
        --  i_indepdt_var,
            v_indepdt_var_len,
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
            i_input_arr_asso[3] :: int,                                                 -- 规约：存放 i_window_len_width
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding
            coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_conv_de_prod_mx_dloss_dindepdt_2
          (
            i_co_value,
        --  array[array_length(i_co_value, 1), array_length(i_co_value, 2)],
        --  i_indepdt_var,
            v_indepdt_var_len,
            i_input_arr_asso[3] :: int,                                                 -- 规约：存放 i_window_len_width
        --  i_depdt_var,
        --  array[array_length(i_depdt_var, 1), array_length(i_depdt_var, 2)],
            i_dloss_ddepdt,
            coalesce(i_input_arr_asso[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride
            coalesce(i_input_arr_asso[6 : 9] :: int[]       ,array[0, 0, 0, 0])  -- ,   -- 规约：存放 i_padding
        --  coalesce(i_input_arr_asso[10] :: float          ,0.0              )         -- 规约：存放 i_padding_value
          )
        ;      
      end if;
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;
  
  elsif i_lambda like '04_%'
  then 
    if i_lambda = '04_new'
    then 
      return 
        sm_sc.fv_d_new_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '04_reshape'
    then 
      return 
        sm_sc.fv_d_reshape_dloss_dindepdt(i_dloss_ddepdt, i_indepdt_var_len)
      ;
    elsif i_lambda = '04_repeat_axis'
    then 
      return 
        sm_sc.fv_d_repeat_axis_dloss_dindepdt(i_dloss_ddepdt, sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[1 : 1][ : ]) :: int[], sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[2 : 2][ : ]) :: int[])
      ;
    elsif i_lambda = '04_apad'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_apad_dloss_dindepdt_1(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1) - 1])
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_apad_dloss_dindepdt_2(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1) - 1], i_input_arr_asso[1] :: int)
        ;      
      end if;
    elsif i_lambda = '04_bpad'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_bpad_dloss_dindepdt_1(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1) - 1])
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_bpad_dloss_dindepdt_2(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1) - 1], i_input_arr_asso[1] :: int)
        ;      
      end if;
    elsif i_lambda = '04_lpad'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_lpad_dloss_dindepdt_1(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1)])
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_lpad_dloss_dindepdt_2(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1)], i_input_arr_asso[1] :: int)
        ;      
      end if;
    elsif i_lambda = '04_rpad'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_rpad_dloss_dindepdt_1(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1)])
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_rpad_dloss_dindepdt_2(i_dloss_ddepdt, v_indepdt_var_len[array_length(v_indepdt_var_len, 1)], i_input_arr_asso[1] :: int)
        ;      
      end if;
    elsif i_lambda = '04_transpose'
    then
      if i_input_arr_asso is null 
      then 
        return 
          sm_sc.fv_d_transpose_dloss_dindepdt(i_dloss_ddepdt)
        ;
      else 
        return 
          sm_sc.fv_d_transpose_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1 : 2] :: int[])
        ;
      end if;
    elsif i_lambda = '04_transpose_i'
    then
      return 
        sm_sc.fv_d_transpose_i_dloss_dindepdt(i_dloss_ddepdt)
      ;
    elsif i_lambda = '04_chunk_transpose'
    then
      return 
        sm_sc.fv_d_chunk_transpose_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_transpose_nd'
    then
      return 
        sm_sc.fv_d_transpose_nd_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso :: int[])
      ;
    elsif i_lambda = '04_turn_90'
    then
      return 
        sm_sc.fv_d_turn_90_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_turn_180'
    then
      return 
        sm_sc.fv_d_turn_180_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1 : 2] :: int[])
      ;
    elsif i_lambda = '04_mirror'
    then
      return 
        sm_sc.fv_d_mirror_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_mx_ele_3d_2_2d'
    then
      return 
        sm_sc.fv_d_mx_ele_3d_2_2d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        , v_indepdt_var_len
        )
      ;
    elsif i_lambda = '04_mx_ele_2d_2_3d'
    then
      return 
        sm_sc.fv_d_mx_ele_2d_2_3d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , i_input_arr_asso[2] :: int
        , i_input_arr_asso[3] :: int
        , i_input_arr_asso[4] :: int :: boolean
        )
      ;
    elsif i_lambda = '04_mx_ele_4d_2_3d'
    then
      return 
        sm_sc.fv_d_mx_ele_4d_2_3d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        , v_indepdt_var_len
        )
      ;
    elsif i_lambda = '04_mx_ele_3d_2_4d'
    then
      return 
        sm_sc.fv_d_mx_ele_3d_2_4d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        , i_input_arr_asso[3] :: int :: boolean
        )
      ;
    elsif i_lambda = '04_mx_ele_flatten_2dims'
    then
      return 
        sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt
        (
          i_dloss_ddepdt
        , i_input_arr_asso[1 : 2] :: int[]
        , i_input_arr_asso[3] :: int
        , v_indepdt_var_len
        )
      ;
    elsif i_lambda = '04_mx_slice_3d_2_2d'
    then
      return 
        sm_sc.fv_d_mx_slice_3d_2_2d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , v_indepdt_var_len
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        )
      ;
    elsif i_lambda = '04_mx_slice_4d_2_2d'
    then
      return 
        sm_sc.fv_d_mx_slice_4d_2_2d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , v_indepdt_var_len
        , sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[1 : 1][ : ] :: int[])
        , sm_sc.fv_mx_ele_2d_2_1d(i_input_arr_asso[2 : 2][ : ] :: int[])
        )
      ;
    elsif i_lambda = '04_mx_slice_4d_2_3d'
    then
      return 
        sm_sc.fv_d_mx_slice_4d_2_3d_dloss_dindepdt
        (
          i_dloss_ddepdt
        , v_indepdt_var_len
        , i_input_arr_asso[1] :: int
        , i_input_arr_asso[2] :: int
        )
      ;
    elsif i_lambda = '04_mx_ascend_dim'
    then
      return 
        sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_mx_descend_dim'
    then
      return 
        sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(i_dloss_ddepdt, i_input_arr_asso[1] :: int)
      ;
    elsif i_lambda = '04_chunk'
    then
      return 
        sm_sc.fv_d_chunk_dloss_dindepdt(i_dloss_ddepdt, v_indepdt_var_len, sm_sc.fv_mx_descend_dim(i_input_arr_asso[1][ : ]) :: int[])
      ;
    elsif i_lambda = '04_slice_y'
    then
      return 
      (
        select 
          sm_sc.fv_d_slice_y_dloss_dindepdt
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[1]
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x'
    then
      return 
      (
        select 
          sm_sc.fv_d_slice_x_dloss_dindepdt
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[2]
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x3'
    then
      return 
      (
        select 
          sm_sc.fv_d_slice_x3_dloss_dindepdt
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[3]
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_slice_x4'
    then
      return 
      (
        select 
          sm_sc.fv_d_slice_x4_dloss_dindepdt
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[4]
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[1 : 1][ : ], i_input_arr_asso[2 : 2][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_y'
    then
      return 
      (
        select 
          sm_sc.fv_d_sample_y_dloss_dindepdt_1
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[1]
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x'
    then
      return 
      (
        select 
          sm_sc.fv_d_sample_x_dloss_dindepdt_1
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[2]
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x3'
    then
      return 
      (
        select 
          sm_sc.fv_d_sample_x3_dloss_dindepdt_1
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[3]
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_sample_x4'
    then
      return 
      (
        select 
          sm_sc.fv_d_sample_x4_dloss_dindepdt_1
          (
            i_dloss_ddepdt
          , v_indepdt_var_len[4]
          , i_input_arr_asso[2][1] :: int
          , array_agg(int4range(a_range_lower :: int, a_range_upper :: int + 1, '[)'))
          )
        from unnest(i_input_arr_asso[3 : 3][ : ], i_input_arr_asso[4 : 4][ : ]) tb_a_range(a_range_lower, a_range_upper)
      )
      ;
    elsif i_lambda = '04_lower_tri_mx'
    then
      return sm_sc.fv_d_lower_tri_mx_dloss_dindepdt(i_dloss_ddepdt);
    elsif i_lambda = '04_upper_tri_mx'
    then
      return sm_sc.fv_d_upper_tri_mx_dloss_dindepdt(i_dloss_ddepdt);
    elsif i_lambda = '04_lower_tri_mx_ex'
    then
      return sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt(i_dloss_ddepdt);
    elsif i_lambda = '04_upper_tri_mx_ex'
    then
      return sm_sc.fv_d_upper_tri_mx_ex_dloss_dindepdt(i_dloss_ddepdt);
    elsif i_lambda = '04_lmask'
    then
      return sm_sc.fv_d_lmask_dloss_dindepdt_1(i_dloss_ddepdt, i_co_value :: int[]);
    elsif i_lambda = '04_rmask'
    then
      return sm_sc.fv_d_rmask_dloss_dindepdt_1(i_dloss_ddepdt, i_co_value :: int[]);
    elsif i_lambda = '04_amask'
    then
      return sm_sc.fv_d_amask_dloss_dindepdt_1(i_dloss_ddepdt, i_co_value :: int[]);
    elsif i_lambda = '04_bmask'
    then
      return sm_sc.fv_d_bmask_dloss_dindepdt_1(i_dloss_ddepdt, i_co_value :: int[]);
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;
    
  elsif i_lambda like '03_%'
  then 
    if i_lambda = '03_softmax'
    then
      return 
        sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(i_depdt_var, i_dloss_ddepdt, i_indepdt_var, i_input_arr_asso[1 : 6] :: int[])
      ;
    elsif i_lambda = '03_softmax_ex'
    then
      return 
        sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py(i_depdt_var, i_dloss_ddepdt, i_indepdt_var, i_input_arr_asso[1 : 6] :: int[])
      ;
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;
    
  elsif i_lambda like '01_%'
  then 
    if i_lambda = '01_prod_mx'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_prod_mx_dloss_dindepdt_1(i_dloss_ddepdt, i_co_value, v_indepdt_var_len)
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_prod_mx_dloss_dindepdt_2(i_dloss_ddepdt, i_co_value, v_indepdt_var_len)
        ;
      end if;
    elsif i_lambda = '01_chunk_prod_mx'
    then
      if i_indepdt_var_loc = 1
      then 
        return 
          sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1(i_dloss_ddepdt, i_co_value, v_indepdt_var_len, i_input_arr_asso[1 : 3] :: int[])
        ;
      elsif i_indepdt_var_loc = 2
      then 
        return 
          sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_2(i_dloss_ddepdt, i_co_value, v_indepdt_var_len, i_input_arr_asso[1 : 3] :: int[])
        ;
      end if;
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;
    
  elsif i_lambda like '00_%'
  then 
    if i_lambda = '00_none'
    then
      return 
        sm_sc.fv_d_nn_none_dloss_dindepdt(i_dloss_ddepdt)
      ;
    else 
      return i_dloss_ddepdt *` i_ddepdt_dindepdt;
    end if;
    
  elsif i_lambda like '81_%'
  then 
    return 
      sm_sc.ufv_lambda_arr_dloss_dindepdt
      (
        i_node_no        
      , i_lambda         
      , i_indepdt_var    
      , i_indepdt_var_loc
      , i_co_value       
      , i_input_arr_asso 
      , i_depdt_var      
      , i_dloss_ddepdt   
      , v_indepdt_var_len
      , i_ddepdt_dindepdt
      )
    ;
    
  else 
    return i_dloss_ddepdt *` i_ddepdt_dindepdt;
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

-- -- debug 
-- raise notice 'dldi: i_back_node_no: %; i_fore_node_no: %; loc: %; i_lambda: %; time: %;', i_back_node_no, i_fore_node_no, i_indepdt_var_loc, i_lambda, v_begin_clock - clock_timestamp();

  exception when others then
    raise exception 
    ' i_node_no: %
      fn: sm_sc.fv_lambda_arr_dloss_dindepdt
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
    , v_indepdt_var_len
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



