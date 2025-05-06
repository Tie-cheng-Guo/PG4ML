-- drop function if exists sm_sc.ufv_combine_att_seg4d_symm_ngram_pos_1head(int, int, int, int, int, int[], int);
create or replace function sm_sc.ufv_combine_att_seg4d_symm_ngram_pos_1head
(
  i_seq_len                               int
, i_seg_len                               int
, i_token_embedding_len                   int                 -- 设置：word_embedding 长度，对称性要求为偶数
, i_qk_width                              int
-- , i_kv_heigh                              int
, i_v_width                               int
, i_ngram                                 int[]
, i_seg_embedding_len                     int     default null
-- 多头涉及到 concat 节点是否必要，在 nn 构建时规划，而不在本 ufv_combine 实现。
)
returns jsonb
-- 复合算子的构建依赖于 sm_sc.__vt_global_seq 做为全局序列的稳定性
as 
$$
declare 
  v_j_nodes            jsonb   ;
  v_j_paths            jsonb   ;
  v_j_input_paths      jsonb   ;
  v_j_output_nodes     jsonb   ;
  v_gram_n             int     :=   array_length(i_ngram, 1)     ;
  v_seg_cnt            int     :=   i_seq_len / i_seg_len        ;  
begin
  if true = any(i_ngram >=` 100)
  then 
    raise exception 'unsupport n >= 100 in i_ngram[]';
  end if;

  if i_seg_embedding_len is null 
  then 
    i_seg_embedding_len := i_token_embedding_len * i_seg_len;
  end if;

  -- 准备 node
  with
  cte_nodes as 
  (
    select 
      000 + 1                                                          as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_zscore'                                                      as node_fn_type
    , array[1, 1, 1, i_token_embedding_len]      :: float[]            as node_fn_asso_value
    , 'qkv_input'                                                      as node_desc
    union all                          
    select 
      100 + 1                                                          as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[v_seg_cnt, i_token_embedding_len, i_qk_width]              as node_fn_asso_value
    , 'w_q'                                                            as node_desc
    union all                                                          
    select                                                             
      200 + i_ngram[a_no]                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[v_seg_cnt, i_token_embedding_len, i_qk_width]              as node_fn_asso_value       -- array[i_token_embedding_len * i_ngram, i_qk_width]
    , 'w_k_' || a_no || 'th_gram'                                      as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      300 + i_ngram[a_no]                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[v_seg_cnt, i_token_embedding_len, i_v_width]               as node_fn_asso_value       -- array[i_token_embedding_len * i_ngram, i_v_width]
    , 'w_v_' || a_no || 'th_gram'                                      as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             -- need token_embedding input as p1
      400 + 1                                                          as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_qk_width]              as node_fn_asso_value
    , '|**| w_q'                                                       as node_desc       
    union all                                                          
    select                                                             -- need token_embedding input as p1
      500 + i_ngram[a_no]                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_qk_width]              as node_fn_asso_value
    , '|**| w_k_' || a_no || 'gram'                                    as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)  
    union all                                                          
    select                                                             -- need token_embedding input as p1
      600 + i_ngram[a_no]                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_v_width]               as node_fn_asso_value
    , '|**| w_v_' || a_no || 'gram'                                    as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      700                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_transpose'                                                   as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'transpose(k)                   '                                as node_desc
    union all                                                          
    select                                                             
      800                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        i_seq_len
      , i_qk_width
      , (i_seg_len * array_length(i_ngram, 1)) - (|@+| i_ngram) + array_length(i_ngram, 1) + v_seg_cnt
      ]                                                                as node_fn_asso_value
    , 'q |**| transpose(k)'                                            as node_desc
    
    union all
    select 
      83400 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_none'                                                        as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'embedding_seg none ' || a_no || 'gram'                     as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      83500 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_transpose'                                                   as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'embedding_seg transpose ' || a_no || 'gram'                     as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      83600 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array
      [
        v_seg_cnt
      , i_token_embedding_len
      , i_token_embedding_len
      ]                                                                as node_fn_asso_value
    , 'embedding_seg prod_mx weight k ' || a_no || 'gram'              as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      83700 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        i_token_embedding_len
      , i_token_embedding_len
      , (i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]
      ]                                                                as node_fn_asso_value
    , 'embedding_seg prod_mx k ' || a_no || 'gram'                     as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      83800 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array
      [
        v_seg_cnt
      , 1
      , (i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]
      ]                                                                as node_fn_asso_value
    , 'embedding_seg prod_mx weight q ' || a_no || 'gram'              as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      83900 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        1
      , (i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]
      , i_token_embedding_len
      ]                                                                as node_fn_asso_value
    , 'embedding_seg prod_mx q ' || a_no || 'gram'                     as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      84000 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        1
      , i_token_embedding_len
      , (i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]
      ]                                                                as node_fn_asso_value
    , 'embedding_seg prod_mx qk ' || a_no || 'gram'                    as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      84100 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[1]                                                         as node_fn_asso_value
    , 'ngram_seg_len ^ 0.5 ' || a_no || 'gram'                         as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    union all
    select 
      84200 + i_ngram[a_no]                                            as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_div'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '/ ngram_seg_len ^ 0.5 ' || a_no || 'gram'                       as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    
    union all
    select 
      851                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '06_aggr_mx_concat_x4'                                           as node_fn_type
    , (
        select 
          array_agg
          (
            (i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no] 
            order by a_no
          ) 
        from generate_series(1, v_gram_n) tb_a(a_no)
      ) 
       || array[1]                                                     as node_fn_asso_value
    , 'embedding_seg concat_x4 position encode'                        as node_desc
    union all
    select                                                             
      852                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[1, v_seg_cnt, 1, 1]                                        as node_fn_asso_value
    , 'seg position encode'                                            as node_desc
    union all
    select 
      853                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_transpose'                                                   as node_fn_type
    , array[2, 3]                                                      as node_fn_asso_value
    , 'embedding_seg flatten transpose'                                as node_desc
    union all
    select 
      854                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array
      [
        -- (
        --   select sum((i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]) 
        --   from generate_series(1, v_gram_n) tb_a(a_no)
        -- ) + 1
        i_seg_embedding_len
      , i_qk_width
      ] :: float[]                                                     as node_fn_asso_value
    , 'w_ks_seg'                                                       as node_desc
    union all
    select 
      855                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array
      [
        -- (
        --   select sum((i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]) 
        --   from generate_series(1, v_gram_n) tb_a(a_no)
        -- ) + 1
        i_seg_embedding_len
      , i_v_width
      ] :: float[]                                                     as node_fn_asso_value
    , 'w_vs_seg'                                                       as node_desc
    union all                                                          
    select                                                             
      856                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        v_seg_cnt
      -- -- , (v_gram_n * i_token_embedding_len) + 1
      -- , (
      --     select sum((i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]) 
      --     from generate_series(1, v_gram_n) tb_a(a_no)
      --   ) + 1
      , i_seg_embedding_len
      , i_qk_width
      ]                                                                as node_fn_asso_value
    , 'embedding_seg |**| w_ks_seg'                                      as node_desc
    union all                                                          
    select                                                             
      857                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        v_seg_cnt
      -- -- , (v_gram_n * i_token_embedding_len) + 1
      -- , (
      --     select sum((i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]) 
      --     from generate_series(1, v_gram_n) tb_a(a_no)
      --   ) + 1
      , i_seg_embedding_len
      , i_v_width
      ]                                                                as node_fn_asso_value
    , 'embedding_seg |**| w_vs_seg'                                      as node_desc
    union all                                                          
    select                                                             
      858                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '06_aggr_mx_concat_x3'                                           as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'k aggr_mx_concat_x3'                                            as node_desc
    union all                                                          
    select                                                             
      859                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '06_aggr_mx_concat_x3'                                           as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'v aggr_mx_concat_x3'                                            as node_desc
    
    union all                                                          
    -- 不采用下三角矩阵算子，而采用元素加 masked 矩阵的方式；后者可以灵活的调整 masked 策略
    select                                                             
      900                                                              as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array
      [
        1
      , v_seg_cnt
      , i_seg_len
      , (i_seg_len * array_length(i_ngram, 1)) 
        - (|@+| i_ngram) 
        + array_length(i_ngram, 1) 
        + v_seg_cnt
      ]                                                                as node_fn_asso_value
    , 'masked_arr'                                                     as node_desc
    union all                                                          
    select                                                             
      1000                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_add'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '+ sequence_mask'                                                as node_desc
    union all                                                          
    select                                                             
      1100                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[1]                                                         as node_fn_asso_value   -- array[1, i_seq_len, i_seq_len - a_no + 1]
    , 'const(qk_width ^ 0.5)'                                          as node_desc
    union all                                                          
    select                                                             
      1200                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_div'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '/` (qk_width ^ 0.5)'                                            as node_desc
    union all                                                          
    select                                                             
      1300                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_softmax'                                                     as node_fn_type
    , array
      [
        1
      , 1
      , 1
      , (i_seg_len * array_length(i_ngram, 1)) 
        - (|@+| i_ngram) 
        + array_length(i_ngram, 1) 
        + v_seg_cnt
      ]                                                                as node_fn_asso_value
    , 'softmax'                                                        as node_desc
    union all                                                          
    select                                                             
      1400                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        i_seg_len
      , (i_seg_len * array_length(i_ngram, 1))
        - (|@+| i_ngram) 
        + array_length(i_ngram, 1)
        + v_seg_cnt
      , i_v_width
      ]                                                                as node_fn_asso_value
    , '|**| v'                                                         as node_desc
    
    -- ngram embedding
    union all                                                          
    select                                                             
      1800 + i_ngram[a_no]                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '05_pool_none'                                                   as node_fn_type
    , array[null, i_ngram[a_no], i_token_embedding_len, 1, 1, 0, 0, 0, 0, 0]    as node_fn_asso_value
    , 'ngram 05_pool_none'                                             as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    where i_ngram[a_no] > 1
    union all                                                          
    select                                                             
      1900 + i_ngram[a_no]                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[v_seg_cnt, i_seg_len - i_ngram[a_no] + 1, i_ngram[a_no]]   as node_fn_asso_value
    , 'ngram 01_chunk_prod_mx weight 1st'                              as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    where i_ngram[a_no] > 1
    union all                                                          
    select                                                             
      2000 + i_ngram[a_no]                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_chunk_prod_mx'                                               as node_fn_type
    , array[1, i_ngram[a_no], i_token_embedding_len]                   as node_fn_asso_value
    , 'ngram 01_chunk_prod_mx'                                         as node_desc
    from generate_series(1, v_gram_n) as tb_a(a_no)
    where i_ngram[a_no] > 1
    
    union all                                                          
    select                                                             
      2100                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array
      [
        1
      , (
          select sum((i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]) 
          from generate_series(1, v_gram_n) tb_a(a_no)
        ) + 1
      , i_seg_embedding_len
      ]                                                                as node_fn_asso_value
    , 'seg v 01_prod_mx'                                               as node_desc
    union all
    select 
      2200                                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array
      [
        v_seg_cnt
      , (
          select sum((i_seg_len - i_ngram[a_no] + 1) * i_ngram[a_no]) 
          from generate_series(1, v_gram_n) tb_a(a_no)
        ) + 1
      , i_seg_embedding_len
      ] :: float[]                                                     as node_fn_asso_value
    , 'w_seg_v'                                                        as node_desc
  ),
  -- 准备 path
  cte_paths as 
  (
    -- embedding_seg
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 834              -- embedding_seg none
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
      and tb_a_fore_node.a_tmp_no % 100 = 1
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 834              -- embedding_seg none
      and tb_a_back_node.a_tmp_no / 100 = 18               -- ngram 05_pool_none
      and tb_a_fore_node.a_tmp_no % 100 > 1
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
      
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 835              -- embedding_seg transpose
      and tb_a_back_node.a_tmp_no / 100 = 834              -- embedding_seg none
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 837              -- embedding_seg prod_mx k
      and tb_a_back_node.a_tmp_no / 100 = 836              -- embedding_seg prod_mx weight k
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 837              -- embedding_seg prod_mx k
      and tb_a_back_node.a_tmp_no / 100 = 835              -- embedding_seg transpose
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 839              -- embedding_seg prod_mx q
      and tb_a_back_node.a_tmp_no / 100 = 838              -- embedding_seg prod_mx weight q
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 839              -- embedding_seg prod_mx q
      and tb_a_back_node.a_tmp_no / 100 = 834              -- embedding_seg none
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 840              -- embedding_seg prod_mx qk
      and tb_a_back_node.a_tmp_no / 100 = 839              -- embedding_seg prod_mx q
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 840              -- embedding_seg prod_mx qk
      and tb_a_back_node.a_tmp_no / 100 = 837              -- embedding_seg prod_mx k
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 842              -- / i_token_embedding_len ^ 0.5
      and tb_a_back_node.a_tmp_no / 100 = 840              -- embedding_seg prod_mx qk
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 842              -- / i_token_embedding_len ^ 0.5
      and tb_a_back_node.a_tmp_no / 100 = 841              -- i_token_embedding_len ^ 0.5
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
      
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , tb_a_back_node.a_tmp_no % 100                  as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 851                    -- embedding_seg concat_x4
      and tb_a_back_node.a_tmp_no / 100 = 842              -- embedding_seg prod_mx ngram
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 853                    -- embedding_seg flatten transpose
      and tb_a_back_node.a_tmp_no = 2100                   -- seg v 01_prod_mx
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 2100                   -- seg v 01_prod_mx
      and tb_a_back_node.a_tmp_no = 2200                   -- w_seg_v
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 2100                   -- seg v 01_prod_mx
      and tb_a_back_node.a_tmp_no = 851                    -- embedding_seg concat_x4
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , v_gram_n + 1                                   as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 851                    -- embedding_seg concat_x4
      and tb_a_back_node.a_tmp_no = 852                    -- seg position encode

    -- seg ngram embedding
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 18                -- ngram 05_pool_none
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 20               -- ngram 01_chunk_prod_mx
      and tb_a_back_node.a_tmp_no / 100 = 18               -- ngram 05_pool_none
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 20               -- ngram 01_chunk_prod_mx
      and tb_a_back_node.a_tmp_no / 100 = 19               -- ngram 01_chunk_prod_mx weight 1st
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100    
    
    union all
    -- q embedding |**| weight
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 400 + 1                -- |**| w_q  path 1
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
    union all
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 400 + 1                -- |**| w_q  path 2
      and tb_a_back_node.a_tmp_no = 100 + 1                -- w_q
    union all 
    -- k token embedding |**| weight   gram 1
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 5                -- |**| w_k_1gram
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
      and i_ngram[tb_a_fore_node.a_tmp_no % 100] = 1  -- -- and tb_a_fore_node.a_tmp_no % 100 = 1
    union all 
    -- k token embedding |**| weight   gram 1  path n > 1
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 5                -- |**| w_k_ngram n >= 2
      and tb_a_back_node.a_tmp_no / 100 = 20                -- ngram 01_chunk_prod_mx
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
      -- and tb_a_fore_node.a_tmp_no % 100 > 1
    union all 
    -- v token embedding |**| weight   gram 1
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 6                -- |**| w_v_1gram
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
      and i_ngram[tb_a_fore_node.a_tmp_no % 100] = 1  -- -- and tb_a_fore_node.a_tmp_no % 100 = 1
    union all 
    -- v token embedding |**| weight   gram 1  path n > 1
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 6                -- |**| w_v_ngram n >= 2
      and tb_a_back_node.a_tmp_no / 100 = 20                -- ngram embedding_kv_
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
      -- and tb_a_fore_node.a_tmp_no % 100 > 1
    union all
    -- k token embedding |**| weight   path 2
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 5                -- |**| w_k_ngram
      and tb_a_back_node.a_tmp_no / 100 = 2                -- w_k_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100 % 10
    union all 
    -- v token embedding |**| weight   path 2
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 6                -- |**| w_v_ngram
      and tb_a_back_node.a_tmp_no / 100 = 3                -- w_v_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100 % 10
    union all 
    
    -- k seg embedding |**| weight    gram 1
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 856                -- embedding_seg |**| w_ks_seg
      and tb_a_back_node.a_tmp_no = 853                -- embedding_seg concat_x4 position encode
    union all
    -- k seg embedding |**| weight    gram 2
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 856                -- embedding_seg |**| w_ks_seg
      and tb_a_back_node.a_tmp_no = 854                -- w_ks_seg
    union all
    
    -- v seg embedding |**| weight    gram 1
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 857                -- embedding_seg |**| w_vs_seg
      and tb_a_back_node.a_tmp_no = 853                -- embedding_seg concat_x4 position encode
    union all
    
    -- v seg embedding |**| weight    gram 2
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 857                -- embedding_seg |**| w_vs_seg
      and tb_a_back_node.a_tmp_no = 855                -- w_vs_seg
      
    union all
    -- k part of token embedding
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , tb_a_back_node.a_tmp_no % 100                  as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 858                -- k aggr_mx_concat_x3
      and tb_a_back_node.a_tmp_no / 100 = 5            -- |**| w_k_
    union all
    -- k part of concat_x3 seg embedding
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , v_gram_n + 1                                   as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 858                -- k aggr_mx_concat_x3
      and tb_a_back_node.a_tmp_no = 856                -- embedding_seg |**| w_ks_seg
      
    union all
    -- v part of token embedding
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , tb_a_back_node.a_tmp_no % 100                  as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 859                -- k aggr_mx_concat_x3
      and tb_a_back_node.a_tmp_no / 100 = 6            -- |**| w_v_
    union all
    -- v part of concat_x3 seg embedding
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , v_gram_n + 1                                   as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 859                -- v aggr_mx_concat_x3
      and tb_a_back_node.a_tmp_no = 857                -- embedding_seg |**| w_vs_seg
    
    -- transpose(k)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 700                -- transpose(k)
      and tb_a_back_node.a_tmp_no = 858                -- k aggr_mx_concat_x3
    
    -- q |**| transpose(k)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 800                -- q |**| transpose(k)
      and tb_a_back_node.a_tmp_no = 400 + 1            -- |**| w_q
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 800                -- q |**| transpose(k)
      and tb_a_back_node.a_tmp_no = 700                -- transpose(k)
    
    -- + sequence_mask
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1000               -- + sequence_mask
      and tb_a_back_node.a_tmp_no = 800                -- q |**| transpose(k)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1000               -- + sequence_mask
      and tb_a_back_node.a_tmp_no = 900                -- masked_arr
    
    -- /` (qk_width ^ 0.5)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1200               -- /` (qk_width ^ 0.5)
      and tb_a_back_node.a_tmp_no = 1000               --+ sequence_mask
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1200               -- /` (qk_width ^ 0.5)
      and tb_a_back_node.a_tmp_no = 1100               -- const(qk_width ^ 0.5)
    
    -- softmax
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1300               -- softmax
      and tb_a_back_node.a_tmp_no = 1200               -- /` (qk_width ^ 0.5)
    
    -- |**| v
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1400               -- |**| v
      and tb_a_back_node.a_tmp_no = 1300               -- softmax
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1400               -- |**| v
      and tb_a_back_node.a_tmp_no = 859                -- v aggr_mx_concat_x3
    
    

    -- v aggr_mx_concat_x3
  ),
  -- 准备输入路径
  cte_input_paths as 
  (
    select                                           -- need token_embedding input as p1
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 1                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 000 + 1
  ),
  -- 准备输出节点
  cte_output_nodes as 
  (
    select 
      node_no
    , 1                                              as combine_out_no
    from cte_nodes
    where a_tmp_no = 1400
  )
  -- 装入四个 json
  select 
    (
      select 
        sm_sc.fa_concat
        (
          json_build_array
          (
            json_strip_nulls
            (
              json_build_object
              (
                'node_no'             , node_no
              , 'node_type'           , node_type
              , 'node_fn_type'        , node_fn_type
              , 'node_fn_asso_value'  , node_fn_asso_value :: text
              , 'node_desc'           , node_desc
              )
            )
          ) :: jsonb
        order by a_tmp_no
        )
      from cte_nodes
    ) as a_j_nodes
  , (
      select 
        sm_sc.fa_concat
        (
          json_build_array
          (
            json_build_object
            (
              'fore_node_no'        , fore_node_no
            , 'path_ord_no'         , path_ord_no
            , 'back_node_no'        , back_node_no
            )
          ) :: jsonb
        order by fore_node_no, path_ord_no
        )
      from cte_paths
    ) as a_j_paths
  , (
      select 
        sm_sc.fa_concat
        (
          json_build_array
          (
            json_build_object
            (
              'fore_node_no'        , fore_node_no
            , 'path_ord_no'         , path_ord_no
            , 'combine_in_no'       , combine_in_no
            )
          ) :: jsonb
        order by fore_node_no
        )
      from cte_input_paths
    ) as a_j_input_paths
  , (
      select 
        sm_sc.fa_concat
        (
          json_build_array
          (
            json_build_object
            (
              'output_node_no'      , node_no
            , 'combine_out_no'      , combine_out_no
            )
          ) :: jsonb
        order by node_no
        )
      from cte_output_nodes
    ) as a_j_output_nodes
  into 
    v_j_nodes
  , v_j_paths
  , v_j_input_paths
  , v_j_output_nodes
  ;

  return 
    jsonb_build_object
    (
      'combine_no'            , lower(sm_sc.fv_get_global_seq())
    , 'nodes'                 , v_j_nodes 
    , 'paths'                 , v_j_paths
    , 'input_paths'           , v_j_input_paths
    , 'output_nodes'          , v_j_output_nodes
    )
  ;
end
$$
language plpgsql volatile
parallel safe
;

-- select 
--   sm_sc.ufv_combine_att_seg4d_symm_ngram_pos_1head
--   (
--     40                                -- i_seq_len      
--   , 10                                -- i_seg_len         
--   , 24                                -- i_token_embedding_len
--   , 64                                -- i_qk_width           
-- --   , 64                                -- i_kv_heigh           
--   , 64                                -- i_v_width              
--   , array[1, 2, 3, 4]                 -- i_ngram                  
--   )

-- with 
-- cte_j_trs as 
-- (
--   select
--     -- 以下 jsonb 由调用 sm_sc.ufv_combine_att_seg4d_symm_ngram_pos_1head 获得
--     '
--       {
--         "nodes": [
--           {
--             "node_no": 3240,
--             "node_desc": "qkv_input",
--             "node_fn_type": "03_zscore",
--             "node_fn_asso_value": "{1,1,1,24}"
--           },
--           {
--             "node_no": 3241,
--             "node_desc": "w_q",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3242,
--             "node_desc": "w_k_1th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3243,
--             "node_desc": "w_k_2th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3244,
--             "node_desc": "w_k_3th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3245,
--             "node_desc": "w_k_4th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3246,
--             "node_desc": "w_v_1th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3247,
--             "node_desc": "w_v_2th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3248,
--             "node_desc": "w_v_3th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3249,
--             "node_desc": "w_v_4th_gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,64}"
--           },
--           {
--             "node_no": 3250,
--             "node_desc": "|**| w_q",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3251,
--             "node_desc": "|**| w_k_1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3252,
--             "node_desc": "|**| w_k_2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3253,
--             "node_desc": "|**| w_k_3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3254,
--             "node_desc": "|**| w_k_4gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3255,
--             "node_desc": "|**| w_v_1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3256,
--             "node_desc": "|**| w_v_2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3257,
--             "node_desc": "|**| w_v_3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3258,
--             "node_desc": "|**| w_v_4gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,24,64}"
--           },
--           {
--             "node_no": 3259,
--             "node_desc": "transpose(k)                   ",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 3260,
--             "node_desc": "q |**| transpose(k)",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,38}"
--           },
--           {
--             "node_no": 3297,
--             "node_desc": "embedding_seg concat_x4 position encode",
--             "node_fn_type": "06_aggr_mx_concat_x4",
--             "node_fn_asso_value": "{10,18,24,28,1}"
--           },
--           {
--             "node_no": 3298,
--             "node_desc": "seg position encode",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1,4,1,1}"
--           },
--           {
--             "node_no": 3299,
--             "node_desc": "embedding_seg flatten transpose",
--             "node_fn_type": "04_transpose",
--             "node_fn_asso_value": "{2,3}"
--           },
--           {
--             "node_no": 3300,
--             "node_desc": "w_ks_seg",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{96,64}"
--           },
--           {
--             "node_no": 3301,
--             "node_desc": "w_vs_seg",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{96,64}"
--           },
--           {
--             "node_no": 3302,
--             "node_desc": "embedding_seg |**| w_ks_seg",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{4,96,64}"
--           },
--           {
--             "node_no": 3303,
--             "node_desc": "embedding_seg |**| w_vs_seg",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{4,96,64}"
--           },
--           {
--             "node_no": 3304,
--             "node_desc": "k aggr_mx_concat_x3",
--             "node_fn_type": "06_aggr_mx_concat_x3"
--           },
--           {
--             "node_no": 3305,
--             "node_desc": "v aggr_mx_concat_x3",
--             "node_fn_type": "06_aggr_mx_concat_x3"
--           },
--           {
--             "node_no": 3306,
--             "node_desc": "masked_arr",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1,4,10,38}"
--           },
--           {
--             "node_no": 3307,
--             "node_desc": "+ sequence_mask",
--             "node_fn_type": "01_add"
--           },
--           {
--             "node_no": 3308,
--             "node_desc": "const(qk_width ^ 0.5)",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 3309,
--             "node_desc": "/` (qk_width ^ 0.5)",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 3310,
--             "node_desc": "softmax",
--             "node_fn_type": "03_softmax",
--             "node_fn_asso_value": "{1,1,1,38}"
--           },
--           {
--             "node_no": 3311,
--             "node_desc": "|**| v",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{10,38,64}"
--           },
--           {
--             "node_no": 3312,
--             "node_desc": "ngram 05_pool_none",
--             "node_fn_type": "05_pool_none",
--             "node_fn_asso_value": "{NULL,2,24,1,1,0,0,0,0,0}"
--           },
--           {
--             "node_no": 3313,
--             "node_desc": "ngram 05_pool_none",
--             "node_fn_type": "05_pool_none",
--             "node_fn_asso_value": "{NULL,3,24,1,1,0,0,0,0,0}"
--           },
--           {
--             "node_no": 3314,
--             "node_desc": "ngram 05_pool_none",
--             "node_fn_type": "05_pool_none",
--             "node_fn_asso_value": "{NULL,4,24,1,1,0,0,0,0,0}"
--           },
--           {
--             "node_no": 3315,
--             "node_desc": "ngram 01_chunk_prod_mx weight 1st",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,9,2}"
--           },
--           {
--             "node_no": 3316,
--             "node_desc": "ngram 01_chunk_prod_mx weight 1st",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,8,3}"
--           },
--           {
--             "node_no": 3317,
--             "node_desc": "ngram 01_chunk_prod_mx weight 1st",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,7,4}"
--           },
--           {
--             "node_no": 3318,
--             "node_desc": "ngram 01_chunk_prod_mx",
--             "node_fn_type": "01_chunk_prod_mx",
--             "node_fn_asso_value": "{1,2,24}"
--           },
--           {
--             "node_no": 3319,
--             "node_desc": "ngram 01_chunk_prod_mx",
--             "node_fn_type": "01_chunk_prod_mx",
--             "node_fn_asso_value": "{1,3,24}"
--           },
--           {
--             "node_no": 3320,
--             "node_desc": "ngram 01_chunk_prod_mx",
--             "node_fn_type": "01_chunk_prod_mx",
--             "node_fn_asso_value": "{1,4,24}"
--           },
--           {
--             "node_no": 3321,
--             "node_desc": "seg v 01_prod_mx",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,81,96}"
--           },
--           {
--             "node_no": 3322,
--             "node_desc": "w_seg_vs",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,81,96}"
--           },
--           {
--             "node_no": 3261,
--             "node_desc": "embedding_seg none 1gram",
--             "node_fn_type": "00_none"
--           },
--           {
--             "node_no": 3262,
--             "node_desc": "embedding_seg none 2gram",
--             "node_fn_type": "00_none"
--           },
--           {
--             "node_no": 3263,
--             "node_desc": "embedding_seg none 3gram",
--             "node_fn_type": "00_none"
--           },
--           {
--             "node_no": 3264,
--             "node_desc": "embedding_seg none 4gram",
--             "node_fn_type": "00_none"
--           },
--           {
--             "node_no": 3265,
--             "node_desc": "embedding_seg transpose 1gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 3266,
--             "node_desc": "embedding_seg transpose 2gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 3267,
--             "node_desc": "embedding_seg transpose 3gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 3268,
--             "node_desc": "embedding_seg transpose 4gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 3269,
--             "node_desc": "embedding_seg prod_mx weight k 1gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,24}"
--           },
--           {
--             "node_no": 3270,
--             "node_desc": "embedding_seg prod_mx weight k 2gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,24}"
--           },
--           {
--             "node_no": 3271,
--             "node_desc": "embedding_seg prod_mx weight k 3gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,24}"
--           },
--           {
--             "node_no": 3272,
--             "node_desc": "embedding_seg prod_mx weight k 4gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,24,24}"
--           },
--           {
--             "node_no": 3273,
--             "node_desc": "embedding_seg prod_mx k 1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{24,24,10}"
--           },
--           {
--             "node_no": 3274,
--             "node_desc": "embedding_seg prod_mx k 2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{24,24,18}"
--           },
--           {
--             "node_no": 3275,
--             "node_desc": "embedding_seg prod_mx k 3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{24,24,24}"
--           },
--           {
--             "node_no": 3276,
--             "node_desc": "embedding_seg prod_mx k 4gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{24,24,28}"
--           },
--           {
--             "node_no": 3277,
--             "node_desc": "embedding_seg prod_mx weight q 1gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,1,10}"
--           },
--           {
--             "node_no": 3278,
--             "node_desc": "embedding_seg prod_mx weight q 2gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,1,18}"
--           },
--           {
--             "node_no": 3279,
--             "node_desc": "embedding_seg prod_mx weight q 3gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,1,24}"
--           },
--           {
--             "node_no": 3280,
--             "node_desc": "embedding_seg prod_mx weight q 4gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{4,1,28}"
--           },
--           {
--             "node_no": 3281,
--             "node_desc": "embedding_seg prod_mx q 1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,10,24}"
--           },
--           {
--             "node_no": 3282,
--             "node_desc": "embedding_seg prod_mx q 2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,18,24}"
--           },
--           {
--             "node_no": 3283,
--             "node_desc": "embedding_seg prod_mx q 3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,24,24}"
--           },
--           {
--             "node_no": 3284,
--             "node_desc": "embedding_seg prod_mx q 4gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,28,24}"
--           },
--           {
--             "node_no": 3285,
--             "node_desc": "embedding_seg prod_mx qk 1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,24,10}"
--           },
--           {
--             "node_no": 3286,
--             "node_desc": "embedding_seg prod_mx qk 2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,24,18}"
--           },
--           {
--             "node_no": 3287,
--             "node_desc": "embedding_seg prod_mx qk 3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,24,24}"
--           },
--           {
--             "node_no": 3288,
--             "node_desc": "embedding_seg prod_mx qk 4gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{1,24,28}"
--           },
--           {
--             "node_no": 3289,
--             "node_desc": "ngram_seg_len ^ 0.5 1gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 3290,
--             "node_desc": "ngram_seg_len ^ 0.5 2gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 3291,
--             "node_desc": "ngram_seg_len ^ 0.5 3gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 3292,
--             "node_desc": "ngram_seg_len ^ 0.5 4gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 3293,
--             "node_desc": "/ ngram_seg_len ^ 0.5 1gram",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 3294,
--             "node_desc": "/ ngram_seg_len ^ 0.5 2gram",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 3295,
--             "node_desc": "/ ngram_seg_len ^ 0.5 3gram",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 3296,
--             "node_desc": "/ ngram_seg_len ^ 0.5 4gram",
--             "node_fn_type": "01_div"
--           }
--         ],
--         "paths": [
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3250
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3241,
--             "fore_node_no": 3250
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3251
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3242,
--             "fore_node_no": 3251
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3318,
--             "fore_node_no": 3252
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3243,
--             "fore_node_no": 3252
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3319,
--             "fore_node_no": 3253
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3244,
--             "fore_node_no": 3253
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3320,
--             "fore_node_no": 3254
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3245,
--             "fore_node_no": 3254
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3255
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3246,
--             "fore_node_no": 3255
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3318,
--             "fore_node_no": 3256
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3247,
--             "fore_node_no": 3256
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3319,
--             "fore_node_no": 3257
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3248,
--             "fore_node_no": 3257
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3320,
--             "fore_node_no": 3258
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3249,
--             "fore_node_no": 3258
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3304,
--             "fore_node_no": 3259
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3250,
--             "fore_node_no": 3260
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3259,
--             "fore_node_no": 3260
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3261
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3312,
--             "fore_node_no": 3262
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3313,
--             "fore_node_no": 3263
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3314,
--             "fore_node_no": 3264
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3261,
--             "fore_node_no": 3265
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3262,
--             "fore_node_no": 3266
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3263,
--             "fore_node_no": 3267
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3264,
--             "fore_node_no": 3268
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3269,
--             "fore_node_no": 3273
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3265,
--             "fore_node_no": 3273
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3270,
--             "fore_node_no": 3274
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3266,
--             "fore_node_no": 3274
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3271,
--             "fore_node_no": 3275
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3267,
--             "fore_node_no": 3275
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3272,
--             "fore_node_no": 3276
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3268,
--             "fore_node_no": 3276
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3277,
--             "fore_node_no": 3281
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3261,
--             "fore_node_no": 3281
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3278,
--             "fore_node_no": 3282
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3262,
--             "fore_node_no": 3282
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3279,
--             "fore_node_no": 3283
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3263,
--             "fore_node_no": 3283
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3280,
--             "fore_node_no": 3284
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3264,
--             "fore_node_no": 3284
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3281,
--             "fore_node_no": 3285
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3273,
--             "fore_node_no": 3285
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3282,
--             "fore_node_no": 3286
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3274,
--             "fore_node_no": 3286
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3283,
--             "fore_node_no": 3287
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3275,
--             "fore_node_no": 3287
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3284,
--             "fore_node_no": 3288
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3276,
--             "fore_node_no": 3288
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3285,
--             "fore_node_no": 3293
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3289,
--             "fore_node_no": 3293
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3286,
--             "fore_node_no": 3294
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3290,
--             "fore_node_no": 3294
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3287,
--             "fore_node_no": 3295
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3291,
--             "fore_node_no": 3295
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3288,
--             "fore_node_no": 3296
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3292,
--             "fore_node_no": 3296
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3293,
--             "fore_node_no": 3297
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3294,
--             "fore_node_no": 3297
--           },
--           {
--             "path_ord_no": 3,
--             "back_node_no": 3295,
--             "fore_node_no": 3297
--           },
--           {
--             "path_ord_no": 4,
--             "back_node_no": 3296,
--             "fore_node_no": 3297
--           },
--           {
--             "path_ord_no": 5,
--             "back_node_no": 3298,
--             "fore_node_no": 3297
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3321,
--             "fore_node_no": 3299
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3299,
--             "fore_node_no": 3302
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3300,
--             "fore_node_no": 3302
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3299,
--             "fore_node_no": 3303
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3301,
--             "fore_node_no": 3303
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3251,
--             "fore_node_no": 3304
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3252,
--             "fore_node_no": 3304
--           },
--           {
--             "path_ord_no": 3,
--             "back_node_no": 3253,
--             "fore_node_no": 3304
--           },
--           {
--             "path_ord_no": 4,
--             "back_node_no": 3254,
--             "fore_node_no": 3304
--           },
--           {
--             "path_ord_no": 5,
--             "back_node_no": 3302,
--             "fore_node_no": 3304
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3255,
--             "fore_node_no": 3305
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3256,
--             "fore_node_no": 3305
--           },
--           {
--             "path_ord_no": 3,
--             "back_node_no": 3257,
--             "fore_node_no": 3305
--           },
--           {
--             "path_ord_no": 4,
--             "back_node_no": 3258,
--             "fore_node_no": 3305
--           },
--           {
--             "path_ord_no": 5,
--             "back_node_no": 3303,
--             "fore_node_no": 3305
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3260,
--             "fore_node_no": 3307
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3306,
--             "fore_node_no": 3307
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3307,
--             "fore_node_no": 3309
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3308,
--             "fore_node_no": 3309
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3309,
--             "fore_node_no": 3310
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3310,
--             "fore_node_no": 3311
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3305,
--             "fore_node_no": 3311
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3312
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3313
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3240,
--             "fore_node_no": 3314
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3315,
--             "fore_node_no": 3318
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3312,
--             "fore_node_no": 3318
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3316,
--             "fore_node_no": 3319
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3313,
--             "fore_node_no": 3319
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3317,
--             "fore_node_no": 3320
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3314,
--             "fore_node_no": 3320
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 3297,
--             "fore_node_no": 3321
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 3322,
--             "fore_node_no": 3321
--           }
--         ],
--         "combine_no": 3323,
--         "input_paths": [
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 3240,
--             "combine_in_no": 1
--           }
--         ],
--         "output_nodes": [
--           {
--             "combine_out_no": 1,
--             "output_node_no": 3311
--           }
--         ]
--       }
--     ' :: jsonb
--     as a_j_trs
-- ),
-- -- cte_nodes as
-- -- (
-- --   select                                
-- --     (a_j_node         ->> 'node_no'             )  :: int          as node_no
-- --   , (a_j_node         ->> 'node_type'           )                  as node_type
-- --   , (a_j_node         ->> 'node_fn_type'        )                  as node_fn_type
-- --   , (a_j_node         ->> 'node_fn_asso_value'  )  :: float[]      as node_fn_asso_value
-- --   , (a_j_node         ->> 'node_desc'           )                  as node_desc
-- --   from cte_j_trs, jsonb_path_query(a_j_trs, '$.nodes[*]') tb_a_nodes(a_j_node)
-- -- ) -- select node_no, node_type, node_fn_type, node_fn_asso_value, node_desc from cte_nodes
-- -- cte_paths as
-- -- (
-- --   select 
-- --     (a_j_path         ->> 'path_ord_no'         )  :: int          as path_ord_no
-- --   , (a_j_path         ->> 'back_node_no'        )  :: int          as back_node_no
-- --   , (a_j_path         ->> 'fore_node_no'        )  :: int          as fore_node_no
-- --   from cte_j_trs, jsonb_path_query(a_j_trs, '$.paths[*]') tb_a_path(a_j_path)
-- -- ) -- select path_ord_no, back_node_no, fore_node_no from cte_paths
-- -- cte_input_paths as
-- -- (
-- --   select 
-- --     (a_j_input_paths  ->> 'path_ord_no'         )  :: int          as path_ord_no
-- --   , (a_j_input_paths  ->> 'fore_node_no'        )  :: int          as fore_node_no
-- --   , (a_j_input_paths  ->> 'combine_in_no'       )  :: int          as combine_in_no
-- --   from cte_j_trs, jsonb_path_query(a_j_trs, '$.input_paths[*]') tb_a_input_paths(a_j_input_paths)
-- -- ) -- select path_ord_no, fore_node_no, combine_in_no from cte_input_paths
-- -- cte_output_nodes as
-- -- (
-- --   select 
-- --     (a_j_output_nodes ->> 'output_node_no'      )  :: int          as output_node_no
-- --   , (a_j_output_nodes ->> 'combine_out_no'      )  :: int          as combine_out_no
-- --   from cte_j_trs, jsonb_path_query(a_j_trs, '$.output_nodes[*]') tb_a_output_nodes(a_j_output_nodes)
-- -- ) -- select output_node_no, combine_out_no from cte_output_nodes