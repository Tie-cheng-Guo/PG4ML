-- drop function if exists sm_sc.fv_lambda_arr_len(bigint, varchar(64), int[], int[], float[], int[]);
create or replace function sm_sc.fv_lambda_arr_len
(
  i_node_no                   bigint                          ,
  i_lambda                    varchar(64)                     ,
  i_input_p1_len              int[]                           ,
  i_input_p2_len              int[]             default null  ,      -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立
  i_input_arr_asso            float[]           default null  ,    
  i_input_p3_len              int[]             default null  
)
returns int[]
as
$$
declare 
  v_arr_asso       int[]     := i_input_arr_asso ;
  v_p1_ndims       int       := array_length(i_input_p1_len, 1);
  v_p2_ndims       int       := array_length(i_input_p2_len, 1);
  v_p3_ndims       int       := array_length(i_input_p3_len, 1);
  v_p1_len_heigh   int       := i_input_p1_len[v_p1_ndims - 1];
  v_p1_len_width   int       := i_input_p1_len[v_p1_ndims];
  v_p2_len_heigh   int       := i_input_p2_len[v_p2_ndims - 1];
  v_p2_len_width   int       := i_input_p2_len[v_p2_ndims];
  v_p3_len_heigh   int       := i_input_p3_len[v_p3_ndims - 1];
  v_p3_len_width   int       := i_input_p3_len[v_p3_ndims];
  v_n_ndims_len    int[]     := 
    -- case 
    --   when v_p1_ndims = 4 then i_input_p1_len[1 : 2] 
    --   when v_p1_ndims = 3 then i_input_p1_len[1 : 1]
    --   when v_p2_ndims = 4 then i_input_p2_len[1 : 2]
    --   when v_p2_ndims = 3 then i_input_p2_len[1 : 1]
    --   when v_p3_ndims = 4 then i_input_p3_len[1 : 2]
    --   when v_p3_ndims = 3 then i_input_p3_len[1 : 1]
    --   else null
    -- end
    (
      select 
        sm_sc.fa_mx_max(a_n_ndims_len)
      from 
      (
        select 
          (sm_sc.fv_lpad(i_input_p1_len, array[1], greatest(v_p1_ndims, v_p2_ndims, v_p3_ndims) - v_p1_ndims))
            [ : greatest(v_p1_ndims, v_p2_ndims, v_p3_ndims) - 2]
          as a_n_ndims_len
        union all 
        select 
          (sm_sc.fv_lpad(i_input_p2_len, array[1], greatest(v_p1_ndims, v_p2_ndims, v_p3_ndims) - v_p2_ndims))
            [ : greatest(v_p1_ndims, v_p2_ndims, v_p3_ndims) - 2]
        union all 
        select 
          (sm_sc.fv_lpad(i_input_p3_len, array[1], greatest(v_p1_ndims, v_p2_ndims, v_p3_ndims) - v_p3_ndims))
            [ : greatest(v_p1_ndims, v_p2_ndims, v_p3_ndims) - 2]
      ) tb_a
    )
    ;
  
begin
  -- 审计各参数各维度长度是否匹配
  if i_lambda like '00_%'
  then 
    if i_lambda = '00_buff_slice_rand_pick'
    then 
      return 
        sm_sc.fv_aggr_slice_sum_py(v_arr_asso[3 : 3][ : ])
      ;

    elsif i_lambda = '00_const'
    then 
      return 
      (
        select 
          array_agg(array_length(i_input_arr_asso, a_ndim) order by a_ndim) 
        from generate_series(1, array_ndims(i_input_arr_asso)) tb_a_ndim(a_ndim)
      )
      ;

    elsif i_lambda = '00_none'
    then 
      return 
        i_input_p1_len
      ;

    elsif i_lambda = '00_full_dataset'
    then 
      return 
        (
          select 
            count(*) 
          from sm_sc.tb_nn_train_input_buff 
          where work_no = (select work_no from sm_sc.tb_nn_node where node_no = i_node_no)
        )
      ;

    elsif i_lambda = '00_buff_slice_rand_pick'
    then 
      return 
        sm_sc.fv_aggr_slice_sum_py(i_input_arr_asso[3 : 3][ : ])
      ;
  
    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    end if;
    
  elsif i_lambda like '01_%'
  then 
    if i_lambda in ('01_add', '01_mul', '01_sub', '01_div', '01_mod', '01_pow', '01_log')
    then
      if not exists 
             (
               select  
               from unnest(sm_sc.__fv_mirror_y(i_input_p1_len), sm_sc.__fv_mirror_y(i_input_p2_len)) tb_a_len(a_len_left, a_len_right)
               where a_len_left <> a_len_right
                 and a_len_left <> 1
                 and a_len_right <> 1
             )
      then 
        return 
          (
            select 
              sm_sc.__fv_mirror_y(array_agg(greatest(a_len_left, a_len_right)))
            from unnest(sm_sc.__fv_mirror_y(i_input_p1_len), sm_sc.__fv_mirror_y(i_input_p2_len)) tb_a_len(a_len_left, a_len_right)
          )
        ;
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '01_prod_mx'
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0 
        and v_p1_len_width > 0 and coalesce(v_p2_len_width, v_arr_asso[3]) > 0
        and v_p1_len_width = coalesce(v_p2_len_heigh, v_arr_asso[2]) 
      then 
        return 
          -- v_arr_asso[1] :: int                                                   -- 规约：存放 array_length(i_indepdt, 1)
          -- v_arr_asso[2] :: int                                                   -- 规约：存放 array_length(i_indepdt, 2), 也即 array_length(i_w, 1)
          -- v_arr_asso[3] :: int                                                   -- 规约：存放 array_length(i_w, 2)
          v_n_ndims_len ||
          array[v_p1_len_heigh, coalesce(v_p2_len_width, v_arr_asso[3])];
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '01_chunk_prod_mx'
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0 and v_p2_len_heigh > 0 and v_p2_len_width > 0
        and v_p1_len_heigh % v_arr_asso[1] :: int = 0
        and v_p1_len_width % v_arr_asso[2] :: int = 0
        and v_p2_len_heigh % v_arr_asso[2] :: int = 0
        and v_p2_len_width % v_arr_asso[3] :: int = 0
        and v_p1_len_heigh / v_arr_asso[1] = v_p2_len_heigh / v_arr_asso[2]
        and v_p1_len_width / v_arr_asso[2] = v_p2_len_width / v_arr_asso[3]
      then 
        return 
          -- v_arr_asso[1] :: int                                                   -- 规约：存放 矩阵乘法 chunk 入参一高度规格                    
          -- v_arr_asso[2] :: int                                                   -- 规约：存放 矩阵乘法 chunk 入参一宽度规格，也即入参二高度规格
          -- v_arr_asso[3] :: int                                                   -- 规约：存放 矩阵乘法 chunk 入参二宽度规格                    
          v_n_ndims_len ||
          array[v_p1_len_heigh, v_p2_len_width];
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;

    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    end if;

  elsif i_lambda like '03_%'
  then 
    if i_lambda in ('03_softmax', '03_softmax_ex', '03_zscore')
    then
      v_arr_asso := 
        sm_sc.fv_coalesce
        (
          -- sm_sc.fv_lpad
          -- (
          --   v_arr_asso
          -- , array[null :: int]
          -- , array_length(i_input_p1_len, 1) - array_length(v_arr_asso, 1)
          -- )
          i_input_p1_len[ : array_length(i_input_p1_len, 1) - coalesce(array_length(v_arr_asso, 1), 0)] || v_arr_asso
        , i_input_p1_len
        )
      ;
      
      if array_length(i_input_p1_len, 1) >= array_length(v_arr_asso, 1)
        and 0 = all(i_input_p1_len %` v_arr_asso)
      then 
        return 
          i_input_p1_len
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;

    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    end if;

  elsif i_lambda like '04_%'
  then 
    if i_lambda = '04_new'
    then
      if array_length(i_input_p1_len, 1) = array_length(v_arr_asso, 1)
      then 
        return 
          i_input_p1_len * v_arr_asso
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '04_reshape'
    then
      if array_length(i_input_p1_len, 1) = array_length(v_arr_asso, 1)
      then 
        return 
          sm_sc.fv_coalesce(v_arr_asso, i_input_p1_len)
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
     
    elsif i_lambda = '04_repeat_axis'
    then
      return 
        i_input_p1_len
        *
        (
          select 
            array_agg(coalesce(a_repeat, 1) order by a_dim_no)
          from generate_series(1, v_p1_ndims) tb_a_dim_no(a_dim_no)
          left join unnest(v_arr_asso[1 : 1][ : ], v_arr_asso[2 : 2][ : ]) tb_a_axis_no(a_axis_no, a_repeat)
            on tb_a_axis_no.a_axis_no = tb_a_dim_no.a_dim_no
        )
      ;
      
    elsif i_lambda = '04_apad'
    then
      if (array_length(i_input_p2_len, 1) = array_length(i_input_p1_len, 1)
          or array_length(i_input_p2_len, 1) <= array_length(i_input_p1_len, 1) and array_length(i_input_p2_len, 1) <= 2
         )
        and v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh >= 0 and v_p2_len_width >= 0
        and v_p1_len_width = v_p2_len_width
        and (v_n_ndims_len = i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] 
             or i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] is null
            )
      then 
        return 
          v_n_ndims_len ||
          array
          [
            (v_p2_len_heigh * v_arr_asso[1]) + v_p1_len_heigh
          , v_p1_len_width
          ]
        ;
      else 
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_bpad'
    then
      if (array_length(i_input_p2_len, 1) = array_length(i_input_p1_len, 1)
          or array_length(i_input_p2_len, 1) <= array_length(i_input_p1_len, 1) and array_length(i_input_p2_len, 1) <= 2
         )
        and v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh >= 0 and v_p2_len_width >= 0
        and v_p1_len_width = v_p2_len_width
        and (v_n_ndims_len = i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] 
             or i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] is null
            )
      then 
        return 
          v_n_ndims_len ||
          array
          [
            v_p1_len_heigh + (v_p2_len_heigh * v_arr_asso[1])
          , v_p1_len_width
          ]
        ;
      else 
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_lpad'
    then
      if (array_length(i_input_p2_len, 1) = array_length(i_input_p1_len, 1)
          or array_length(i_input_p2_len, 1) <= array_length(i_input_p1_len, 1) and array_length(i_input_p2_len, 1) <= 2
         )
        and v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh >= 0 and v_p2_len_width >= 0
        and v_p1_len_heigh = v_p2_len_heigh
        and (v_n_ndims_len = i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] 
             or i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] is null
            )
      then 
        return 
          v_n_ndims_len ||
          array
          [
            v_p1_len_heigh
          , (v_p2_len_width * v_arr_asso[1]) + v_p1_len_width
          ]
        ;
      else 
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_rpad'
    then
      if (array_length(i_input_p2_len, 1) = array_length(i_input_p1_len, 1)
          or array_length(i_input_p2_len, 1) <= array_length(i_input_p1_len, 1) and array_length(i_input_p2_len, 1) <= 2
         )
        and v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh >= 0 and v_p2_len_width >= 0
        and v_p1_len_heigh = v_p2_len_heigh
        and (v_n_ndims_len = i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] 
             or i_input_p2_len[ : array_length(i_input_p2_len, 1) - 2] is null
            )
      then 
        return 
          v_n_ndims_len ||
          array
          [
            v_p1_len_heigh
          , v_p1_len_width + (v_p2_len_width * v_arr_asso[1])
          ]
        ;
      else 
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda in ('04_transpose_i', '04_chunk_transpose')
    then
      return 
        v_n_ndims_len ||
        array
        [
          v_p1_len_width
        , v_p1_len_heigh
        ]
      ;
      
    elsif i_lambda = '04_transpose_nd'
    then
      return 
        (select array_agg(i_input_p1_len[v_arr_asso[a_no]] order by a_no) from generate_series(1, array_length(i_input_p1_len, 1)) tb_a(a_no))
      ;
    elsif i_lambda = '04_transpose'
    then
      if v_arr_asso is null 
      then 
        v_arr_asso := array[array_length(i_input_p1_len, 1) - 1, array_length(i_input_p1_len, 1)];
      end if;
      
      if array_length(i_input_p1_len, 1) = 2
      then 
        return 
          array
          [
            i_input_p1_len[2]
          , i_input_p1_len[1]
          ]
        ;
      elsif array_length(i_input_p1_len, 1) = 3 
      then 
        if v_arr_asso in (array[1, 2], array[2, 1])
        then 
          return 
            array
            [
              i_input_p1_len[2]
            , i_input_p1_len[1]
            , i_input_p1_len[3]
            ]
          ;
        elsif v_arr_asso in (array[1, 3], array[3, 1])
        then 
          return 
            array
            [
              i_input_p1_len[3]
            , i_input_p1_len[2]
            , i_input_p1_len[1]
            ]
          ;
        elsif v_arr_asso in (array[3, 2], array[2, 3])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[3]
            , i_input_p1_len[2]
            ]
          ;
        end if;
      elsif array_length(i_input_p1_len, 1) = 4 
      then 
        if v_arr_asso in (array[1, 2], array[2, 1])
        then 
          return 
            array
            [
              i_input_p1_len[2]
            , i_input_p1_len[1]
            , i_input_p1_len[3]
            , i_input_p1_len[4]
            ]
          ;
        elsif v_arr_asso in (array[1, 3], array[3, 1])
        then 
          return 
            array
            [
              i_input_p1_len[3]
            , i_input_p1_len[2]
            , i_input_p1_len[1]
            , i_input_p1_len[4]
            ]
          ;
        elsif v_arr_asso in (array[3, 2], array[2, 3])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[3]
            , i_input_p1_len[2]
            , i_input_p1_len[4]
            ]
          ;
        elsif v_arr_asso in (array[1, 4], array[4, 1])
        then 
          return 
            array
            [
              i_input_p1_len[4]
            , i_input_p1_len[2]
            , i_input_p1_len[3]
            , i_input_p1_len[1]
            ]
          ;
        elsif v_arr_asso in (array[2, 4], array[4, 2])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[4]
            , i_input_p1_len[3]
            , i_input_p1_len[2]
            ]
          ;
        elsif v_arr_asso in (array[3, 4], array[4, 3])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[2]
            , i_input_p1_len[4]
            , i_input_p1_len[3]
            ]
          ;
        end if;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_turn_90'
    then
      if array_length(i_input_p1_len, 1) = 2 
      then 
        return 
          array
          [
            i_input_p1_len[2]
          , i_input_p1_len[1]
          ]
        ;
      elsif array_length(i_input_p1_len, 1) = 3 
      then 
        if v_arr_asso in (array[1, 2], array[2, 1])
        then 
          return 
            array
            [
              i_input_p1_len[2]
            , i_input_p1_len[1]
            , i_input_p1_len[3]
            ]
          ;
        elsif v_arr_asso in (array[1, 3], array[3, 1])
        then 
          return 
            array
            [
              i_input_p1_len[3]
            , i_input_p1_len[2]
            , i_input_p1_len[1]
            ]
          ;
        elsif v_arr_asso in (array[3, 2], array[2, 3])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[3]
            , i_input_p1_len[2]
            ]
          ;
        end if;
      elsif array_length(i_input_p1_len, 1) = 4 
      then 
        if v_arr_asso in (array[1, 2], array[2, 1])
        then 
          return 
            array
            [
              i_input_p1_len[2]
            , i_input_p1_len[1]
            , i_input_p1_len[3]
            , i_input_p1_len[4]
            ]
          ;
        elsif v_arr_asso in (array[1, 3], array[3, 1])
        then 
          return 
            array
            [
              i_input_p1_len[3]
            , i_input_p1_len[2]
            , i_input_p1_len[1]
            , i_input_p1_len[4]
            ]
          ;
        elsif v_arr_asso in (array[3, 2], array[2, 3])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[3]
            , i_input_p1_len[2]
            , i_input_p1_len[4]
            ]
          ;
        elsif v_arr_asso in (array[1, 4], array[4, 1])
        then 
          return 
            array
            [
              i_input_p1_len[4]
            , i_input_p1_len[2]
            , i_input_p1_len[3]
            , i_input_p1_len[1]
            ]
          ;
        elsif v_arr_asso in (array[2, 4], array[4, 2])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[4]
            , i_input_p1_len[3]
            , i_input_p1_len[2]
            ]
          ;
        elsif v_arr_asso in (array[3, 4], array[4, 3])
        then 
          return 
            array
            [
              i_input_p1_len[1]
            , i_input_p1_len[2]
            , i_input_p1_len[4]
            , i_input_p1_len[3]
            ]
          ;
        end if;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_ele_3d_2_2d'
    then
      if array_length(i_input_p1_len, 1) = 3
      then 
        i_input_p1_len[v_arr_asso[2]] 
          := i_input_p1_len[v_arr_asso[1]] * i_input_p1_len[v_arr_asso[2]]
        ;
        return 
          i_input_p1_len[ : v_arr_asso[1] - 1] || i_input_p1_len[v_arr_asso[1] + 1 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_ele_2d_2_3d'
    then
      if array_length(i_input_p1_len, 1) = 2
      then 
        if v_arr_asso[4] :: int :: boolean -- i_if_dim_pin_ele_on_from
        then 
          v_arr_asso[4] := i_input_p1_len[v_arr_asso[2]];   -- 借 v_arr_asso[4] 当临时变量寄存 i_input_p1_len[v_arr_asso[2]]
          i_input_p1_len[v_arr_asso[2]] := v_arr_asso[1];
          return 
            i_input_p1_len[ : v_arr_asso[3] - 1] || v_arr_asso[4] / v_arr_asso[1] || i_input_p1_len[ : v_arr_asso[3] + 1]
          ;
        else -- not i_if_dim_pin_ele_on_from
          v_arr_asso[4] := i_input_p1_len[v_arr_asso[3]];   -- 借 v_arr_asso[4] 当临时变量寄存 i_input_p1_len[v_arr_asso[3]]
          i_input_p1_len[v_arr_asso[3]] := v_arr_asso[1];
          return 
            i_input_p1_len[ : v_arr_asso[2] - 1] || v_arr_asso[4] / v_arr_asso[1] || i_input_p1_len[ : v_arr_asso[2] + 1]
          ;
        end if;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_ele_4d_2_3d'
    then
      if array_length(i_input_p1_len, 1) = 4
      then 
        i_input_p1_len[v_arr_asso[2]] 
          := i_input_p1_len[v_arr_asso[1]] * i_input_p1_len[v_arr_asso[2]]
        ;
        return 
          i_input_p1_len[ : v_arr_asso[1] - 1] || i_input_p1_len[v_arr_asso[1] + 1 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_ele_3d_2_4d'
    then
      if array_length(i_input_p1_len, 1) = 3
      then 
        if v_arr_asso[4] :: int :: boolean -- i_if_dim_pin_ele_on_from
        then 
          v_arr_asso[4] := i_input_p1_len[v_arr_asso[2]];   -- 借 v_arr_asso[4] 当临时变量寄存 i_input_p1_len[v_arr_asso[2]]
          i_input_p1_len[v_arr_asso[2]] := v_arr_asso[1];
          return 
            i_input_p1_len[ : v_arr_asso[3] - 1] || v_arr_asso[4] / v_arr_asso[1] || i_input_p1_len[ : v_arr_asso[3] + 1]
          ;
        else -- not i_if_dim_pin_ele_on_from
          v_arr_asso[4] := i_input_p1_len[v_arr_asso[3]];   -- 借 v_arr_asso[4] 当临时变量寄存 i_input_p1_len[v_arr_asso[3]]
          i_input_p1_len[v_arr_asso[3]] := v_arr_asso[1];
          return 
            i_input_p1_len[ : v_arr_asso[2] - 1] || v_arr_asso[4] / v_arr_asso[1] || i_input_p1_len[ : v_arr_asso[2] + 1]
          ;
        end if;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_ele_flatten_2dims'
    then
      if array_length(i_input_p1_len, 1) between 2 and 4
      then 
        i_input_p1_len[v_arr_asso[2]] := i_input_p1_len[v_arr_asso[1]] * i_input_p1_len[v_arr_asso[2]];
        i_input_p1_len[v_arr_asso[1]] := 1;
        return 
          i_input_p1_len
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda in ('04_mx_slice_3d_2_2d', '04_mx_slice_4d_2_3d')
    then
      if array_length(i_input_p1_len, 1) in (3, 4)
      then 
        return 
          sm_sc.fv_pos_replaces(i_input_p1_len, v_arr_asso[1 : 1], 1)
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_slice_4d_2_2d'
    then
      if array_length(i_input_p1_len, 1) = 4
      then 
        return 
          sm_sc.fv_pos_replaces(i_input_p1_len, sm_sc.fv_mx_ele_2d_2_1d(v_arr_asso[1 : 1][ : ]), 1)
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_ascend_dim'
    then
      if array_length(i_input_p1_len, 1) + v_arr_asso[1] <= 4
      then 
        return 
          array_fill(1, v_arr_asso[1 : 1]) || i_input_p1_len
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_mx_descend_dim'
    then
      if array_length(i_input_p1_len, 1) <= 4
      then 
        return 
          i_input_p1_len[1 + v_arr_asso[1] : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_rand_pick_y'
    then
      if array_length(i_input_p1_len, 1) >= 1
        and i_input_p1_len[1] >= v_arr_asso[1]
      then 
        return 
          -- 规约：v_arr_asso[1] 存放所设置的 取样数量
          v_arr_asso[1 : 1] || i_input_p1_len[2 : ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '04_rand_pick_x'
    then
      if array_length(i_input_p1_len, 1) >= 2
        and i_input_p1_len[2] >= v_arr_asso[1]
      then 
        return 
          -- 规约：v_arr_asso[1] 存放所设置的 取样数量
          i_input_p1_len[1 : 1] || v_arr_asso[1 : 1] || i_input_p1_len[3 : ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '04_rand_pick_x3'
    then
      if array_length(i_input_p1_len, 1) >= 3
        and i_input_p1_len[3] >= v_arr_asso[1]
      then 
        return 
          -- 规约：v_arr_asso[1] 存放所设置的 取样数量
          i_input_p1_len[1 : 2] || v_arr_asso[1 : 1] || i_input_p1_len[4 : ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '04_rand_pick_x4'
    then
      if array_length(i_input_p1_len, 1) >= 4
        and i_input_p1_len[4] >= v_arr_asso[1]
      then 
        return 
          -- 规约：v_arr_asso[1] 存放所设置的 取样数量
          i_input_p1_len[ : 3] || v_arr_asso[1 : 1];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_chunk'
    then
      if false = all(v_arr_asso[1][ : ] <=` 0)
      or false = all(v_arr_asso[1][ : ] >` v_arr_asso[2][ : ])
      or false = all(v_arr_asso[2][ : ] >` array[i_input_p1_len])
      then 
        return 
          -- 规约：v_arr_asso[1][1 : ] 存放所设置的切块儿位置下界
          --       v_arr_asso[2][1 : ] 存放所设置的切块儿位置上界
          sm_sc.fv_mx_descend_dim(v_arr_asso[2 : 2][1 : ] -` v_arr_asso[1 : 1][1 : ]) +` 1;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_slice_y'
    then
      if array_length(i_input_p1_len, 1) >= 1
        and i_input_p1_len[1] >= any(v_arr_asso)
      then 
        return 
          -- 规约：v_arr_asso[1 : 2] 存放所设置的切片位置上下界
          array
          [
            (
              select 
                sum(coalesce(v_arr_asso[2][a_range_cur], i_input_p1_len[1]) - coalesce(v_arr_asso[1][a_range_cur], 1) + 1)
              from generate_series(1, array_length(v_arr_asso, 2)) tb_a_range_cur(a_range_cur)
            )
          ] || 
          i_input_p1_len[2 : ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_slice_x'
    then
      if array_length(i_input_p1_len, 1) >= 2
        and i_input_p1_len[2] >= any(v_arr_asso)
      then 
        return 
          -- 规约：v_arr_asso[1 : 2] 存放所设置的切片位置上下界
          i_input_p1_len[1 : 1] || 
          array
          [
            (
              select 
                sum(coalesce(v_arr_asso[2][a_range_cur], i_input_p1_len[2]) - coalesce(v_arr_asso[1][a_range_cur], 1) + 1)
              from generate_series(1, array_length(v_arr_asso, 2)) tb_a_range_cur(a_range_cur)
            )
          ] || 
          i_input_p1_len[3 : ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_slice_x3'
    then
      if array_length(i_input_p1_len, 1) >= 3
        and i_input_p1_len[3] >= any(v_arr_asso)
      then 
        return 
          -- 规约：v_arr_asso[1 : 2] 存放所设置的切片位置上下界
          i_input_p1_len[1 : 2] || 
          array
          [
            (
              select 
                sum(coalesce(v_arr_asso[2][a_range_cur], i_input_p1_len[3]) - coalesce(v_arr_asso[1][a_range_cur], 1) + 1)
              from generate_series(1, array_length(v_arr_asso, 2)) tb_a_range_cur(a_range_cur)
            )
          ] || 
          i_input_p1_len[4 : ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_slice_x4'
    then
      if array_length(i_input_p1_len, 1) >= 4
        and i_input_p1_len[4] >= any(v_arr_asso)
      then 
        return 
          -- 规约：v_arr_asso[1 : 2] 存放所设置的切片位置上下界
          i_input_p1_len[1 : 3] || 
          array
          [
            (
              select 
                sum(coalesce(v_arr_asso[2][a_range_cur], i_input_p1_len[4]) - coalesce(v_arr_asso[1][a_range_cur], 1) + 1)
              from generate_series(1, array_length(v_arr_asso, 2)) tb_a_range_cur(a_range_cur)
            )
          ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_sample_y'
    then
      if array_length(i_input_p1_len, 1) >= 1
        and i_input_p1_len[1] % v_arr_asso[1][1] = 0
      then 
        return
          (
            with 
            cte_multirange as 
            (
              select 
                int4range(1, v_arr_asso[2][1], '[]') * int4range(a_range_lower, a_range_upper + 1, '[)')
                as a_range
              from unnest(v_arr_asso[3 : 3], v_arr_asso[4 : 4]) tb_a(a_range_lower, a_range_upper)
            )
            select 
              sum 
              (
                i_input_p1_len[1] 
                / v_arr_asso[1][1]
                * (upper(a_range) - lower(a_range))
              )
            from cte_multirange
          )
          || i_input_p1_len[2 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_sample_x'
    then
      if array_length(i_input_p1_len, 1) >= 2
        and i_input_p1_len[2] % v_arr_asso[1][1] = 0
      then 
        return 
          i_input_p1_len[1 : 1] ||   
          (
            with 
            cte_multirange as 
            (
              select 
                int4range(1, v_arr_asso[2][1], '[]') * int4range(a_range_lower, a_range_upper + 1, '[)')
                as a_range
              from unnest(v_arr_asso[3 : 3], v_arr_asso[4 : 4]) tb_a(a_range_lower, a_range_upper)
            )
            select 
              sum 
              (
                i_input_p1_len[2] 
                / v_arr_asso[1][1]
                * (upper(a_range) - lower(a_range))
              )
            from cte_multirange
          )
          || i_input_p1_len[3 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_sample_x3'
    then
      if array_length(i_input_p1_len, 1) >= 3
        and i_input_p1_len[3] % v_arr_asso[1][1] = 0
      then 
        return 
          i_input_p1_len[ : 2] ||   
          (
            with 
            cte_multirange as 
            (
              select 
                int4range(1, v_arr_asso[2][1], '[]') * int4range(a_range_lower, a_range_upper + 1, '[)')
                as a_range
              from unnest(v_arr_asso[3 : 3], v_arr_asso[4 : 4]) tb_a(a_range_lower, a_range_upper)
            )
            select 
              sum 
              (
                i_input_p1_len[3] 
                / v_arr_asso[1][1]
                * (upper(a_range) - lower(a_range))
              )
            from cte_multirange
          )
          || i_input_p1_len[4 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '04_sample_x4'
    then
      if array_length(i_input_p1_len, 1) >= 4
        and i_input_p1_len[4] % v_arr_asso[1][1] = 0
      then 
        return 
          i_input_p1_len[ : 3] ||   
          (
            with 
            cte_multirange as 
            (
              select 
                int4range(1, v_arr_asso[2][1], '[]') * int4range(a_range_lower, a_range_upper + 1, '[)')
                as a_range
              from unnest(v_arr_asso[3 : 3], v_arr_asso[4 : 4]) tb_a(a_range_lower, a_range_upper)
            )
            select 
              sum 
              (
                i_input_p1_len[4] 
                / v_arr_asso[1][1]
                * (upper(a_range) - lower(a_range))
              )
            from cte_multirange
          )
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;

    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    end if;

  elsif i_lambda like '05_%'
  then 
    if i_lambda in ('05_pool_max_2d_grp_x', '05_pool_avg_2d_grp_x')
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p1_len_width % (v_arr_asso[1]) = 0
        and (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) % coalesce(v_arr_asso[4], 1) = 0
        and (v_p1_len_width / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) % coalesce(v_arr_asso[5], 1) = 0
      then 
        return 
          -- v_arr_asso[1]                                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
          -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
          -- coalesce(v_arr_asso[10] :: float ,0.0              )       -- 规约：存放 i_padding_value
          v_n_ndims_len ||
          array
          [
            v_p1_len_heigh,
            ((v_p1_len_width / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) / coalesce(v_arr_asso[5], 1) + 1)   
            * ((v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) / coalesce(v_arr_asso[4], 1) + 1)         
          ];
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda in ('05_pool_max', '05_pool_avg', '05_pool_none')
    then
      -- coalesce(v_arr_asso[2 : 3]        ,array[1, 1]      )       -- 规约：存放 i_window_len
      -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
      -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding   
      -- coalesce(v_arr_asso[10] :: float ,0.0              )        -- 规约：存放 i_padding_value   
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], 1)) % coalesce(v_arr_asso[4], 1) = 0
        and (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], 1)) % coalesce(v_arr_asso[5], 1) = 0
      then 
        if i_lambda in ('05_pool_max', '05_pool_avg')
        then 
          return 
            v_n_ndims_len ||
            array
            [
              (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], 1)) / coalesce(v_arr_asso[4], 1) + 1,
              (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], 1)) / coalesce(v_arr_asso[5], 1) + 1
            ]
          ;
        elsif i_lambda = '05_pool_none'
        then 
          return 
            v_n_ndims_len ||
            array
            [
              ((coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], 1)) / coalesce(v_arr_asso[4], 1) + 1) * coalesce(v_arr_asso[2], 1),
              ((coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], 1)) / coalesce(v_arr_asso[5], 1) + 1) * coalesce(v_arr_asso[3], 1)
            ]
          ;
        end if;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
          
    elsif i_lambda = '05_conv_2d_grp_x'
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh = 1 and v_p2_len_width > 0
        and v_arr_asso[2] * v_arr_asso[3] in (v_p2_len_width - 1, v_p2_len_width)
        and v_p1_len_width % (v_arr_asso[1]) = 0
        and (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) % coalesce(v_arr_asso[4], 1) = 0
        and (v_p1_len_width / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) % coalesce(v_arr_asso[5], 1) = 0
      then 
        return
          -- v_arr_asso[1]                                               -- 规约：存放 i_1d_2_2d_cnt_per_grp
          -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
          -- coalesce(v_arr_asso[10] :: float ,0.0              )        -- 规约：存放 i_padding_value
          v_n_ndims_len ||
          array
          [
            v_p1_len_heigh,
            ((v_p1_len_width / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], v_p2_len_width / v_arr_asso[2])) / coalesce(v_arr_asso[5], 1) + 1)      
            * ((v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], v_p2_len_heigh / v_arr_asso[3])) / coalesce(v_arr_asso[4], 1) + 1)     
          ];
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '05_conv_2d'
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh > 0 and v_p2_len_width > 0
        and (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p2_len_heigh) % coalesce(v_arr_asso[4], 1) = 0
        and (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_width) % coalesce(v_arr_asso[5], 1) = 0
        and (i_input_p3_len is null or v_p3_ndims = v_p2_ndims and v_p3_len_heigh = 1 and v_p3_len_width = 1)
        and (
              i_input_p3_len is null 
             or v_p3_ndims = 2 
             or v_p3_ndims = 3 and i_input_p3_len[1] = i_input_p2_len[1] 
             or v_p3_ndims = 4 and i_input_p3_len[1] = i_input_p2_len[1] and i_input_p3_len[2] = i_input_p2_len[2]
            )
      then 
        return
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
          -- coalesce(v_arr_asso[10] :: float ,0.0              )        -- 规约：存放 i_padding_value
          v_n_ndims_len ||
          array
          [
            (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p2_len_heigh) / coalesce(v_arr_asso[4], 1) + 1,
            (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_width) / coalesce(v_arr_asso[5], 1) + 1     
          ];
      else
        raise exception 'unmatch p1, p2, p3.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_p3_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, i_input_p3_len, v_arr_asso;
      end if;
      
    elsif i_lambda = '05_tunnel_conv'
    then
      if 0 = all(i_input_p1_len %` (i_input_p2_len[ : v_arr_asso[1]] || i_input_p2_len[v_arr_asso[1] + 2 : ]))
        and (
               i_input_p3_len is null 
            or 0 = all((i_input_p1_len[ : v_arr_asso[1] - 1] || i_input_p2_len[v_arr_asso[1] + 1 : v_arr_asso[1] + 1] || i_input_p1_len[v_arr_asso[1] + 1 : ]) %` i_input_p3_len) 
            )
      then 
        -- v_arr_asso[1]    -- 规约：存放 i_tunnel_axis 
        return
          i_input_p1_len[ : v_arr_asso[1] - 1] || i_input_p2_len[v_arr_asso[1] + 1 : v_arr_asso[1] + 1] || i_input_p1_len[v_arr_asso[1] + 1 : ]
          ;
      else
        raise exception 'unmatch p1, p2, p3.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_p3_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, i_input_p3_len, v_arr_asso;
      end if;
    
    elsif i_lambda in ('05_conv_add', '05_conv_sub', '05_conv_mul', '05_conv_div', '05_conv_pow', '05_conv_log')
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh > 0 and v_p2_len_width > 0
        and (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p2_len_heigh) % coalesce(v_arr_asso[4], 1) = 0
        and (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_width) % coalesce(v_arr_asso[5], 1) = 0
      then 
        return
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
          -- coalesce(v_arr_asso[10] :: float ,0.0              )        -- 规约：存放 i_padding_value
          v_n_ndims_len ||
          array
          [
            ((coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p2_len_heigh) / coalesce(v_arr_asso[4], 1) + 1) * v_p2_len_heigh,
            ((coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_width) / coalesce(v_arr_asso[5], 1) + 1) * v_p2_len_width
          ];
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda in ('05_conv_de_sub', '05_conv_de_div', '05_conv_de_pow', '05_conv_de_log')
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh > 0 and v_p2_len_width > 0
        and (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p2_len_heigh) % coalesce(v_arr_asso[4], 1) = 0
        and (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_width) % coalesce(v_arr_asso[5], 1) = 0
      then 
        return
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
          -- coalesce(v_arr_asso[10] :: float ,0.0              )        -- 规约：存放 i_padding_value
          v_n_ndims_len ||
          array
          [
            ((coalesce(v_arr_asso[6], 0) + v_p2_len_heigh + coalesce(v_arr_asso[7], 0) - v_p1_len_heigh) / coalesce(v_arr_asso[4], 1) + 1) * v_p1_len_heigh,
            ((coalesce(v_arr_asso[8], 0) + v_p2_len_width + coalesce(v_arr_asso[9], 0) - v_p1_len_width) / coalesce(v_arr_asso[5], 1) + 1) * v_p1_len_width
          ];
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p2_len: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p2_len, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '05_conv_prod_mx'
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh > 0 and v_p2_len_width > 0
        and (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) % coalesce(v_arr_asso[4], 1) = 0
        and (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_heigh) % coalesce(v_arr_asso[5], 1) = 0
      then 
        return
          -- coalesce(v_arr_asso[2 : 2]        ,array[1, 1]      )       -- 规约：存放 i_window_len_heigh
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding     
          v_n_ndims_len ||
          array
          [
            ((coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) / coalesce(v_arr_asso[4], 1) + 1) * v_arr_asso[2],
            ((coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_p2_len_width) / coalesce(v_arr_asso[5], 1) + 1) * v_p2_len_width
          ]
        ;
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '05_conv_de_prod_mx'
    then
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
        and v_p2_len_heigh > 0 and v_p2_len_width > 0
        and (coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p1_len_width) % coalesce(v_arr_asso[4], 1) = 0
        and (coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) % coalesce(v_arr_asso[5], 1) = 0
      then 
        return
          -- coalesce(v_arr_asso[3 : 3]        ,array[1, 1]      )       -- 规约：存放 i_window_len_width
          -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
          -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding     
          v_n_ndims_len ||
          array
          [
            ((coalesce(v_arr_asso[6], 0) + v_p1_len_heigh + coalesce(v_arr_asso[7], 0) - v_p1_len_width) / coalesce(v_arr_asso[4], 1) + 1) * v_p1_len_width,
            ((coalesce(v_arr_asso[8], 0) + v_p1_len_width + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) / coalesce(v_arr_asso[5], 1) + 1) * v_arr_asso[3]
          ]
        ;
      else
        raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p2_len: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p2_len, i_input_p1_len, v_arr_asso;
      end if;

    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
      
    end if;

  elsif i_lambda like '06_%'
  then 
    if i_lambda = '06_aggr_mx_concat_y'
    then
      if array_length(i_input_p1_len, 1) >= 1 -- or array_length(i_input_p2_len, 1) >= 1
      then 
        return 
          sm_sc.fv_aggr_slice_sum_py(v_arr_asso[1 : ]) || i_input_p1_len[2 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '06_aggr_mx_concat_x'
    then
      if array_length(i_input_p1_len, 2) >= 1 or array_length(i_input_p1_len, 1) >= 1
      then 
        return 
          i_input_p1_len[1 : 1] || sm_sc.fv_aggr_slice_sum_py(v_arr_asso[1 : ]) || i_input_p1_len[3 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '06_aggr_mx_concat_x3'
    then
      if array_length(i_input_p1_len, 3) >= 1 or array_length(i_input_p1_len, 1) >= 1
      then 
        return 
          i_input_p1_len[ : 2] || sm_sc.fv_aggr_slice_sum_py(v_arr_asso[1 : ]) || i_input_p1_len[4 : ]
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda = '06_aggr_mx_concat_x4'
    then
      if array_length(i_input_p1_len, 4) >= 1 or array_length(i_input_p1_len, 1) >= 1
      then 
        return 
          i_input_p1_len[ : 3] || sm_sc.fv_aggr_slice_sum_py(v_arr_asso[1 : ])
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    end if;

  elsif i_lambda like '07_%'
  then 
    if i_lambda in ('07_aggr_slice_sum', '07_aggr_slice_avg', '07_aggr_slice_max', '07_aggr_slice_min')
    then
      v_arr_asso := 
        sm_sc.fv_coalesce
        (
          i_input_p1_len[ : array_length(i_input_p1_len, 1) - coalesce(array_length(v_arr_asso, 1), 0)] || v_arr_asso
        , i_input_p1_len
        )
      ;
      
      if array_length(i_input_p1_len, 1) >= array_length(v_arr_asso, 1)
        and 0 = all(i_input_p1_len %` v_arr_asso)
      then 
        return 
          i_input_p1_len / v_arr_asso
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    
    elsif i_lambda in ('07_aggr_chunk_sum', '07_aggr_chunk_avg', '07_aggr_chunk_max', '07_aggr_chunk_min')
    then
      v_arr_asso := 
        sm_sc.fv_coalesce
        (
          -- sm_sc.fv_lpad
          -- (
          --   v_arr_asso
          -- , array[null :: int]
          -- , array_length(i_input_p1_len, 1) - array_length(v_arr_asso, 1)
          -- )
          i_input_p1_len[ : array_length(i_input_p1_len, 1) - coalesce(array_length(v_arr_asso, 1), 0)] || v_arr_asso
        , i_input_p1_len
        )
      ;
      
      if array_length(i_input_p1_len, 1) >= array_length(v_arr_asso, 1)
        and 0 = all(i_input_p1_len %` v_arr_asso)
      then 
        return 
          v_arr_asso
        ;
      else 
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;

    else
      if v_p1_len_heigh > 0 and v_p1_len_width > 0
      then 
        return 
          i_input_p1_len;
      else
        raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
      end if;
    end if;
    
  elsif i_lambda like '81_%'
  then 
    return 
      sm_sc.ufv_lambda_arr_len
      (
        i_node_no       
      , i_lambda        
      , i_input_p1_len  
      , i_input_p2_len  
      , i_input_arr_asso
      , i_input_p3_len  
      )
    ;
      
  else 
    if v_p1_len_heigh > 0 and v_p1_len_width > 0
    then 
      return 
        i_input_p1_len;
    else
      raise exception 'unmatch p1.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, v_arr_asso;
    end if;

  end if;

  exception when others then
    raise exception 
    ' fn: sm_sc.fv_lambda_arr_len
      i_node_no: %
      i_lambda: %
      i_input_p1_len: %
      i_input_p2_len: %
      v_arr_asso: %
      sqlerrm: %
    '
    , i_node_no
    , i_lambda
    , i_input_p1_len
    , i_input_p2_len
    , v_arr_asso
    , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;



-- select 
--   sm_sc.fv_lambda_arr_len
--   (
--     null
--     '05_conv_2d_grp_x',                       -- i_lambda              
--     array[70, 784],                           -- i_input_p1_len
--     array[1, 25],                             -- i_input_p2_len        
--     array[28, 5, 5, 1, 1, 2, 2, 2, 2, 0]      -- v_arr_asso 
--   )

-- -- select 
-- --         array
-- --         [
-- --           v_p1_len_heigh,
-- --           (v_p1_len_width / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], v_p2_len_width)) / coalesce(v_arr_asso[5], 1)       
-- --           * (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], v_p2_len_heigh)) / coalesce(v_arr_asso[4], 1)     
-- --         ]
-- -- 
-- --         -- v_arr_asso[1]                                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
-- --         -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
-- --         -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
-- --         -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
-- --         -- coalesce(v_arr_asso[10] :: float ,0.0              )       -- 规约：存放 i_padding_value