-- drop function if exists sm_sc.ufv_combine_att_qkv_ngram(int, int, int, int, boolean, int);
create or replace function sm_sc.ufv_combine_att_qkv_ngram
(
  i_seq_len                               int
, i_token_embedding_len                   int
, i_qk_width                              int
-- , i_kv_heigh                              int
, i_v_width                               int
, i_is_mask_arr                           boolean
, i_gram_n                                int
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
begin
  -- 准备 node
  with
  cte_nodes as 
  (
    select 
      000 + 1                                                          as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_none'                                                        as node_fn_type
    , null                                     :: float[]              as node_fn_asso_value
    , 'qkv_input'                                                      as node_desc
    union all                          
    select 
      100 + 1                                                          as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_token_embedding_len, i_qk_width] :: float[]              as node_fn_asso_value
    , 'w_q'                                                            as node_desc
    union all                                                          
    select                                                             
      200 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_token_embedding_len, i_qk_width]                         as node_fn_asso_value       -- array[i_token_embedding_len * i_ngram, i_qk_width]
    , 'w_k_' || a_no || 'gram'                                         as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      300 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_token_embedding_len, i_v_width]                          as node_fn_asso_value       -- array[i_token_embedding_len * i_ngram, i_v_width]
    , 'w_v_' || a_no || 'gram'                                         as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
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
      500 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_qk_width]              as node_fn_asso_value
    , '|**| w_k_' || a_no || 'gram'                                    as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)  
    union all                                                          
    select                                                             -- need token_embedding input as p1
      600 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_v_width]               as node_fn_asso_value
    , '|**| w_v_' || a_no || 'gram'                                    as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      700 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_transpose'                                                   as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'transpose(k)_' || a_no || 'gram'                                as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      800 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_qk_width, i_seq_len - a_no + 1]               as node_fn_asso_value
    , 'q |**| transpose(k)_' || a_no || 'gram'                         as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    -- 不采用下三角矩阵算子，而采用元素加 masked 矩阵的方式；后者可以灵活的调整 masked 策略
    select                                                             
      900 + a_no                                                       as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_seq_len, i_seq_len - a_no + 1]                           as node_fn_asso_value
    , 'masked_arr_' || a_no || 'gram'                                  as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    where i_is_mask_arr
    union all                                                          
    select                                                             
      1000 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_add'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '+ sequence_mask_' || a_no || 'gram'                             as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    where i_is_mask_arr
    union all                                                          
    select                                                             
      1100 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[1]                                                         as node_fn_asso_value   -- array[1, i_seq_len, i_seq_len - a_no + 1]
    , 'const(qk_width ^ 0.5)_' || a_no || 'gram'                       as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      1200 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_div'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '/` (qk_width ^ 0.5)_' || a_no || 'gram'                         as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      1300 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_softmax'                                                     as node_fn_type
    , array[1, 1, i_seq_len - a_no + 1]                                as node_fn_asso_value
    , 'softmax_' || a_no || 'gram'                                     as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      1400 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_seq_len - a_no + 1, i_v_width]                as node_fn_asso_value
    , '|**| v_' || a_no || 'gram'                                      as node_desc
    from generate_series(1, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      1700 + 1                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '06_aggr_mx_sum'                                                 as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'qkv_ngram mx_sum'                                               as node_desc
    union all                                                          
    select                                                             
      1800 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '05_pool_none'                                                   as node_fn_type
    , array[null, a_no, i_token_embedding_len, 1, 1, 0, 0, 0, 0, 0]    as node_fn_asso_value
    , 'ngram 05_pool_none'                                             as node_desc
    from generate_series(2, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      1900 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_seq_len - a_no + 1, a_no]                                as node_fn_asso_value
    , 'ngram 01_chunk_prod_mx weight 1st'                              as node_desc
    from generate_series(2, i_gram_n) as tb_a(a_no)
    union all                                                          
    select                                                             
      2000 + a_no                                                      as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_chunk_prod_mx'                                               as node_fn_type
    , array[1, a_no, i_token_embedding_len]                            as node_fn_asso_value
    , 'ngram 01_chunk_prod_mx'                                         as node_desc
    from generate_series(2, i_gram_n) as tb_a(a_no)
  ),
  -- 准备 path
  cte_paths as 
  (
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 400 + 1                -- |**| w_q
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
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
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 5                -- |**| w_k_1gram
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
      and tb_a_fore_node.a_tmp_no % 100 = 1
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 5                -- |**| w_k_ngram n >= 2
      and tb_a_back_node.a_tmp_no / 100 = 20               -- ngram 01_chunk_prod_mx
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 6                -- |**| w_v_1gram
      and tb_a_back_node.a_tmp_no = 000 + 1                -- qkv_input
      and tb_a_fore_node.a_tmp_no % 100 = 1
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 6                -- |**| w_v_ngram n > 2
      and tb_a_back_node.a_tmp_no / 100 = 20                -- ngram aggr_mx_concat_x3
      and tb_a_back_node.a_tmp_no % 100 = tb_a_fore_node.a_tmp_no % 100
      -- and tb_a_fore_node.a_tmp_no % 100 > 1
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 400 + 1                -- |**| w_q
      and tb_a_back_node.a_tmp_no = 100 + 1                -- w_q
    union all 
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
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 7                -- transpose(k)_ngram
      and tb_a_back_node.a_tmp_no / 100 = 5                -- |**| w_k_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 8                -- q |**| transpose(k)_ngram
      and tb_a_back_node.a_tmp_no = 400 + 1               -- |**| w_q_ngram
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 8                -- q |**| transpose(k)_ngram
      and tb_a_back_node.a_tmp_no / 100 = 7                -- transpose(k)_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 10               -- + sequence_mask_ngram
      and tb_a_back_node.a_tmp_no / 100 = 8                -- q |**| transpose(k)_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 10               -- + sequence_mask_ngram
      and tb_a_back_node.a_tmp_no / 100 = 9                -- masked_arr_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 12               -- /` -- -- -- (qk_width ^ 0.5)
      and tb_a_back_node.a_tmp_no / 100 = 10               -- + sequence_mask_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 12               -- /` (qk_width ^ 0.5)
      and tb_a_back_node.a_tmp_no / 100 = 11               -- const(qk_width ^ 0.5)_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 13               -- softmax_ngram
      and tb_a_back_node.a_tmp_no / 100 = 12               -- /` (qk_width ^ 0.5)
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 14               -- |**| v_ngram
      and tb_a_back_node.a_tmp_no / 100 = 13               -- softmax_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no / 100 = 14               -- |**| v_ngram
      and tb_a_back_node.a_tmp_no / 100 = 6                -- |**| w_v_ngram
      and tb_a_fore_node.a_tmp_no % 100 = tb_a_back_node.a_tmp_no % 100
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , tb_a_back_node.a_tmp_no % 100                  as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 1700 + 1               -- qkv_ngram mx_sum
      and tb_a_back_node.a_tmp_no / 100 = 14                -- |**| v_ngram
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
    where a_tmp_no = 1700 + 1
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
--   sm_sc.ufv_combine_att_qkv_ngram
--   (
--     40                                -- i_seq_len            
--   , 64                                -- i_token_embedding_len
--   , 64                                -- i_qk_width                  
--   , 64                                -- i_v_width            
--   , true                              -- i_is_mask_arr 
--   , 3     
--   )

-- with 
-- cte_j_trs as 
-- (
--   select
--     -- 以下 jsonb 由调用 sm_sc.ufv_combine_att_qkv_ngram 获得
--     '
--       {
--         "nodes": [
--           {
--             "node_no": 44050,
--             "node_desc": "qkv_input",
--             "node_fn_type": "00_none"
--           },
--           {
--             "node_no": 44051,
--             "node_desc": "w_q",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44052,
--             "node_desc": "w_k_1gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44053,
--             "node_desc": "w_k_2gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44054,
--             "node_desc": "w_k_3gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44055,
--             "node_desc": "w_v_1gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44056,
--             "node_desc": "w_v_2gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44057,
--             "node_desc": "w_v_3gram",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{32,64}"
--           },
--           {
--             "node_no": 44058,
--             "node_desc": "|**| w_q",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44059,
--             "node_desc": "|**| w_k_1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44060,
--             "node_desc": "|**| w_k_2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44061,
--             "node_desc": "|**| w_k_3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44062,
--             "node_desc": "|**| w_v_1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44063,
--             "node_desc": "|**| w_v_2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44064,
--             "node_desc": "|**| w_v_3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 44065,
--             "node_desc": "transpose(k)_1gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 44066,
--             "node_desc": "transpose(k)_2gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 44067,
--             "node_desc": "transpose(k)_3gram",
--             "node_fn_type": "04_transpose"
--           },
--           {
--             "node_no": 44068,
--             "node_desc": "q |**| transpose(k)_1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,40}"
--           },
--           {
--             "node_no": 44069,
--             "node_desc": "q |**| transpose(k)_2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,39}"
--           },
--           {
--             "node_no": 44070,
--             "node_desc": "q |**| transpose(k)_3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,38}"
--           },
--           {
--             "node_no": 44071,
--             "node_desc": "masked_arr_1gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{40,40}"
--           },
--           {
--             "node_no": 44072,
--             "node_desc": "masked_arr_2gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{40,39}"
--           },
--           {
--             "node_no": 44073,
--             "node_desc": "masked_arr_3gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{40,38}"
--           },
--           {
--             "node_no": 44074,
--             "node_desc": "+ sequence_mask_1gram",
--             "node_fn_type": "01_add"
--           },
--           {
--             "node_no": 44075,
--             "node_desc": "+ sequence_mask_2gram",
--             "node_fn_type": "01_add"
--           },
--           {
--             "node_no": 44076,
--             "node_desc": "+ sequence_mask_3gram",
--             "node_fn_type": "01_add"
--           },
--           {
--             "node_no": 44077,
--             "node_desc": "const(qk_width ^ 0.5)_1gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 44078,
--             "node_desc": "const(qk_width ^ 0.5)_2gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 44079,
--             "node_desc": "const(qk_width ^ 0.5)_3gram",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 44080,
--             "node_desc": "/` (qk_width ^ 0.5)_1gram",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 44081,
--             "node_desc": "/` (qk_width ^ 0.5)_2gram",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 44082,
--             "node_desc": "/` (qk_width ^ 0.5)_3gram",
--             "node_fn_type": "01_div"
--           },
--           {
--             "node_no": 44083,
--             "node_desc": "softmax_1gram",
--             "node_fn_type": "03_softmax",
--             "node_fn_asso_value": "{1,1,40}"
--           },
--           {
--             "node_no": 44084,
--             "node_desc": "softmax_2gram",
--             "node_fn_type": "03_softmax",
--             "node_fn_asso_value": "{1,1,39}"
--           },
--           {
--             "node_no": 44085,
--             "node_desc": "softmax_3gram",
--             "node_fn_type": "03_softmax",
--             "node_fn_asso_value": "{1,1,38}"
--           },
--           {
--             "node_no": 44086,
--             "node_desc": "|**| v_1gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,40,64}"
--           },
--           {
--             "node_no": 44087,
--             "node_desc": "|**| v_2gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,39,64}"
--           },
--           {
--             "node_no": 44088,
--             "node_desc": "|**| v_3gram",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,38,64}"
--           },
--           {
--             "node_no": 44089,
--             "node_desc": "qkv_ngram mx_sum",
--             "node_fn_type": "06_aggr_mx_sum"
--           },
--           {
--             "node_no": 44090,
--             "node_desc": "ngram 05_pool_none",
--             "node_fn_type": "05_pool_none",
--             "node_fn_asso_value": "{NULL,2,64,1,1,0,0,0,0,0}"
--           },
--           {
--             "node_no": 44091,
--             "node_desc": "ngram 05_pool_none",
--             "node_fn_type": "05_pool_none",
--             "node_fn_asso_value": "{NULL,3,64,1,1,0,0,0,0,0}"
--           },
--           {
--             "node_no": 44092,
--             "node_desc": "ngram 01_chunk_prod_mx weight 1st",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{39,2}"
--           },
--           {
--             "node_no": 44093,
--             "node_desc": "ngram 01_chunk_prod_mx weight 1st",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{38,3}"
--           },
--           {
--             "node_no": 44094,
--             "node_desc": "ngram 01_chunk_prod_mx",
--             "node_fn_type": "01_chunk_prod_mx",
--             "node_fn_asso_value": "{1,2,64}"
--           },
--           {
--             "node_no": 44095,
--             "node_desc": "ngram 01_chunk_prod_mx",
--             "node_fn_type": "01_chunk_prod_mx",
--             "node_fn_asso_value": "{1,3,64}"
--           }
--         ],
--         "paths": [
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44050,
--             "fore_node_no": 44058
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44051,
--             "fore_node_no": 44058
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44050,
--             "fore_node_no": 44059
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44052,
--             "fore_node_no": 44059
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44094,
--             "fore_node_no": 44060
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44053,
--             "fore_node_no": 44060
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44095,
--             "fore_node_no": 44061
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44054,
--             "fore_node_no": 44061
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44050,
--             "fore_node_no": 44062
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44055,
--             "fore_node_no": 44062
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44094,
--             "fore_node_no": 44063
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44056,
--             "fore_node_no": 44063
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44095,
--             "fore_node_no": 44064
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44057,
--             "fore_node_no": 44064
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44059,
--             "fore_node_no": 44065
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44060,
--             "fore_node_no": 44066
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44061,
--             "fore_node_no": 44067
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44058,
--             "fore_node_no": 44068
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44065,
--             "fore_node_no": 44068
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44058,
--             "fore_node_no": 44069
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44066,
--             "fore_node_no": 44069
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44058,
--             "fore_node_no": 44070
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44067,
--             "fore_node_no": 44070
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44068,
--             "fore_node_no": 44074
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44071,
--             "fore_node_no": 44074
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44069,
--             "fore_node_no": 44075
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44072,
--             "fore_node_no": 44075
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44070,
--             "fore_node_no": 44076
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44073,
--             "fore_node_no": 44076
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44074,
--             "fore_node_no": 44080
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44077,
--             "fore_node_no": 44080
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44075,
--             "fore_node_no": 44081
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44078,
--             "fore_node_no": 44081
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44076,
--             "fore_node_no": 44082
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44079,
--             "fore_node_no": 44082
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44080,
--             "fore_node_no": 44083
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44081,
--             "fore_node_no": 44084
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44082,
--             "fore_node_no": 44085
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44083,
--             "fore_node_no": 44086
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44062,
--             "fore_node_no": 44086
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44084,
--             "fore_node_no": 44087
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44063,
--             "fore_node_no": 44087
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44085,
--             "fore_node_no": 44088
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44064,
--             "fore_node_no": 44088
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44086,
--             "fore_node_no": 44089
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44087,
--             "fore_node_no": 44089
--           },
--           {
--             "path_ord_no": 3,
--             "back_node_no": 44088,
--             "fore_node_no": 44089
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44050,
--             "fore_node_no": 44090
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44050,
--             "fore_node_no": 44091
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44092,
--             "fore_node_no": 44094
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44090,
--             "fore_node_no": 44094
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 44093,
--             "fore_node_no": 44095
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 44091,
--             "fore_node_no": 44095
--           }
--         ],
--         "combine_no": 44096,
--         "input_paths": [
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 44050,
--             "combine_in_no": 1
--           }
--         ],
--         "output_nodes": [
--           {
--             "combine_out_no": 1,
--             "output_node_no": 44089
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