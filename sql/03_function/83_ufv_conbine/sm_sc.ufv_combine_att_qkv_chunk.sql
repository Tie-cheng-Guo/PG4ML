-- drop function if exists sm_sc.ufv_combine_att_qkv_chunk(int, int, int, int, int, boolean);
create or replace function sm_sc.ufv_combine_att_qkv_chunk
(
  i_seq_len                               int
, i_token_embedding_len                   int
, i_qk_width                              int
, i_kv_heigh                              int
, i_v_width                               int
, i_is_mask_arr                           boolean
-- , i_ngram                                 int        default 1
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
      1 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_token_embedding_len, i_qk_width] :: float[]              as node_fn_asso_value
    , 'w_q'                                                            as node_desc
    union all                                                          
    select                                                             
      2 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_token_embedding_len, i_qk_width]                         as node_fn_asso_value       -- array[i_token_embedding_len * i_ngram, i_qk_width]
    , 'w_k'                                                            as node_desc
    union all                                                          
    select                                                             
      3 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_token_embedding_len, i_v_width]                          as node_fn_asso_value       -- array[i_token_embedding_len * i_ngram, i_v_width]
    , 'w_v'                                                            as node_desc
    union all                                                          
    select                                                             -- need token_embedding input as p1
      4 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_qk_width]              as node_fn_asso_value
    , '|**| w_q'                                                       as node_desc       
    union all                                                          
    select                                                             -- need token_embedding input as p1
      5 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_qk_width]              as node_fn_asso_value
    , '|**| w_k'                                                       as node_desc       
    union all                                                          
    select                                                             -- need token_embedding input as p1
      6 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_token_embedding_len, i_v_width]               as node_fn_asso_value
    , '|**| w_v'                                                       as node_desc       
    union all                                                          
    select                                                             
      7 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_transpose'                                                   as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'transpose(k)'                                                   as node_desc
    union all                                                          
    select                                                             
      8 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_qk_width, i_kv_heigh]                         as node_fn_asso_value
    , 'q |**| transpose(k)'                                            as node_desc
    union all                                                          
    -- 不采用下三角矩阵算子，而采用元素加 masked 矩阵的方式；后者可以灵活的调整 masked 策略
    select                                                             
      9 :: int                                                         as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_seq_len, i_kv_heigh]                                     as node_fn_asso_value
    , 'masked_arr'                                                     as node_desc
    where i_is_mask_arr
    union all                                                          
    select                                                             
      10 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_add'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '+ sequence_mask'                                                as node_desc
    where i_is_mask_arr
    union all                                                          
    select                                                             
      11 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , array[1]                                                         as node_fn_asso_value   -- array[1, i_seq_len, i_kv_heigh]
    , 'const(qk_width ^ 0.5)'                                          as node_desc
    union all                                                          
    select                                                             
      12 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_div'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '/` (qk_width ^ 0.5)'                                            as node_desc
    union all                                                          
    select                                                             
      13 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_softmax'                                                     as node_fn_type
    , array[1, 1, i_kv_heigh]                                          as node_fn_asso_value
    , 'softmax'                                                        as node_desc
    union all                                                          
    select                                                             
      14 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_seq_len, i_kv_heigh, i_v_width]                          as node_fn_asso_value
    , '|**| v'                                                         as node_desc
    union all                                                          
    select                                                             
      15 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_chunk'                                                       as node_fn_type
    , array[[1, 1],[i_token_embedding_len, i_qk_width]]                as node_fn_asso_value
    , 'w_q_chunk'                                                      as node_desc
    union all                                                          
    select                                                             
      16 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_chunk'                                                       as node_fn_type
    , array[[1, 1],[i_token_embedding_len, i_qk_width]]                as node_fn_asso_value
    , 'w_k_chunk'                                                      as node_desc
    union all                                                          
    select                                                             
      17 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_chunk'                                                       as node_fn_type
    , array[[1, 1],[i_token_embedding_len, i_v_width]]                 as node_fn_asso_value
    , 'w_v_chunk'                                                      as node_desc
    union all                                                          
    select                                                             
      18 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_chunk'                                                       as node_fn_type
    , array[[1, 1],[i_seq_len, i_kv_heigh]]                            as node_fn_asso_value
    , 'decode_mask_chunk'                                              as node_desc
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
    where tb_a_fore_node.a_tmp_no = 15               -- chunk w_q
      and tb_a_back_node.a_tmp_no = 1                -- w_q
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 4                -- |**| w_q
      and tb_a_back_node.a_tmp_no = 15               -- chunk w_q
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 16               -- chunk w_k
      and tb_a_back_node.a_tmp_no = 2                -- w_k
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 5                -- |**| w_k
      and tb_a_back_node.a_tmp_no = 16               -- chunk w_k
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 17               -- chunk w_v
      and tb_a_back_node.a_tmp_no = 3                -- w_v
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 6                -- |**| w_v
      and tb_a_back_node.a_tmp_no = 17               -- chunk w_v
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 7                -- transpose(k)
      and tb_a_back_node.a_tmp_no = 5                -- |**| w_k
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 8                -- q |**| transpose(k)
      and tb_a_back_node.a_tmp_no = 4                -- |**| w_q
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 8                -- q |**| transpose(k)
      and tb_a_back_node.a_tmp_no = 7                -- transpose(k)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 10               -- + sequence_mask
      and tb_a_back_node.a_tmp_no = 8                -- q |**| transpose(k)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 18               -- chunk masked_arr
      and tb_a_back_node.a_tmp_no = 9                -- masked_arr
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 10               -- + sequence_mask
      and tb_a_back_node.a_tmp_no = 18               -- chunk masked_arr
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 12               -- /` (qk_width ^ 0.5)
      and tb_a_back_node.a_tmp_no = 10               -- + sequence_mask
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 12               -- /` (qk_width ^ 0.5)
      and tb_a_back_node.a_tmp_no = 11               -- const(qk_width ^ 0.5)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 13               -- softmax
      and tb_a_back_node.a_tmp_no = 12               -- /` (qk_width ^ 0.5)
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 14               -- |**| v
      and tb_a_back_node.a_tmp_no = 13               -- softmax
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 14               -- |**| v
      and tb_a_back_node.a_tmp_no = 6                -- |**| w_v
  ),
  -- 准备输入路径
  cte_input_paths as 
  (
    select                                           -- need token_embedding input as p1
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 1                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 4
    union all
    select                                           -- need token_embedding input as p1
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 2                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 5
    union all
    select                                           -- need token_embedding input as p1
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 3                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 6
  ),
  -- 准备输出节点
  cte_output_nodes as 
  (
    select 
      node_no
    , 1                                              as combine_out_no
    from cte_nodes
    where a_tmp_no = 14 -- 23
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
                'combine_node_ord_no' , a_tmp_no
              , 'node_no'             , node_no
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
--   sm_sc.ufv_combine_att_qkv_chunk
--   (
--     40                                -- i_seq_len            
--   , 64                                -- i_token_embedding_len
--   , 64                                -- i_qk_width           
--   , 64                                -- i_kv_heigh           
--   , 64                                -- i_v_width            
--   , true                                  -- i_is_mask_arr      
--   )

-- with 
-- cte_j_trs as 
-- (
--   select
--     -- 以下 jsonb 由调用 sm_sc.ufv_combine_att_qkv_chunk 获得
--     '
--       {
--         "nodes": [
--           {
--             "node_no": 23,
--             "node_desc": "w_q",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 1,
--             "node_fn_asso_value": "{64,64}"
--           },
--           {
--             "node_no": 24,
--             "node_desc": "w_k",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 2,
--             "node_fn_asso_value": "{64,64}"
--           },
--           {
--             "node_no": 25,
--             "node_desc": "w_v",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 3,
--             "node_fn_asso_value": "{64,64}"
--           },
--           {
--             "node_no": 26,
--             "node_desc": "|**| w_q",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 4,
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 27,
--             "node_desc": "|**| w_k",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 5,
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 28,
--             "node_desc": "|**| w_v",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 6,
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 29,
--             "node_desc": "transpose(k)",
--             "node_fn_type": "04_transpose",
--             "combine_node_ord_no": 7
--           },
--           {
--             "node_no": 30,
--             "node_desc": "q |**| transpose(k)",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 8,
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 31,
--             "node_desc": "masked_arr",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 9,
--             "node_fn_asso_value": "{40,64}"
--           },
--           {
--             "node_no": 32,
--             "node_desc": "+ sequence_mask",
--             "node_fn_type": "01_add",
--             "combine_node_ord_no": 10
--           },
--           {
--             "node_no": 33,
--             "node_desc": "const(qk_width ^ 0.5)",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 11,
--             "node_fn_asso_value": "{1}"
--           },
--           {
--             "node_no": 34,
--             "node_desc": "/` (qk_width ^ 0.5)",
--             "node_fn_type": "01_div",
--             "combine_node_ord_no": 12
--           },
--           {
--             "node_no": 35,
--             "node_desc": "softmax",
--             "node_fn_type": "03_softmax",
--             "combine_node_ord_no": 13,
--             "node_fn_asso_value": "{1,1,64}"
--           },
--           {
--             "node_no": 36,
--             "node_desc": "|**| v",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 14,
--             "node_fn_asso_value": "{40,64,64}"
--           },
--           {
--             "node_no": 37,
--             "node_desc": "w_q_chunk",
--             "node_fn_type": "04_chunk",
--             "combine_node_ord_no": 15,
--             "node_fn_asso_value": "{64,64}"
--           },
--           {
--             "node_no": 38,
--             "node_desc": "w_k_chunk",
--             "node_fn_type": "04_chunk",
--             "combine_node_ord_no": 16,
--             "node_fn_asso_value": "{64,64}"
--           },
--           {
--             "node_no": 39,
--             "node_desc": "w_v_chunk",
--             "node_fn_type": "04_chunk",
--             "combine_node_ord_no": 17,
--             "node_fn_asso_value": "{64,64}"
--           },
--           {
--             "node_no": 40,
--             "node_desc": "decode_mask_chunk",
--             "node_fn_type": "04_chunk",
--             "combine_node_ord_no": 18,
--             "node_fn_asso_value": "{40,64}"
--           }
--         ],
--         "paths": [
--           {
--             "path_ord_no": 2,
--             "back_node_no": 37,
--             "fore_node_no": 26
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 38,
--             "fore_node_no": 27
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 39,
--             "fore_node_no": 28
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 27,
--             "fore_node_no": 29
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 26,
--             "fore_node_no": 30
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 29,
--             "fore_node_no": 30
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 30,
--             "fore_node_no": 32
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 40,
--             "fore_node_no": 32
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 32,
--             "fore_node_no": 34
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 33,
--             "fore_node_no": 34
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 34,
--             "fore_node_no": 35
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 35,
--             "fore_node_no": 36
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 28,
--             "fore_node_no": 36
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 23,
--             "fore_node_no": 37
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 24,
--             "fore_node_no": 38
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 25,
--             "fore_node_no": 39
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 31,
--             "fore_node_no": 40
--           }
--         ],
--         "combine_no": 41,
--         "input_paths": [
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 26,
--             "combine_in_no": 1
--           },
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 27,
--             "combine_in_no": 2
--           },
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 28,
--             "combine_in_no": 3
--           }
--         ],
--         "output_nodes": [
--           {
--             "combine_out_no": 1,
--             "output_node_no": 36
--           }
--         ]
--       }
--     ' :: jsonb
--     as a_j_trs
-- ),
-- -- cte_combine_no as
-- -- (
-- --   select                                
-- --     a_j_combine_no  :: int          as combine_no
-- --   from cte_j_trs, jsonb_path_query(a_j_trs, '$.combine_no') tb_a_combine_no(a_j_combine_no)
-- -- ) -- select combine_no from cte_combine_no
-- -- cte_nodes as
-- -- (
-- --   select                                
-- --     (a_j_node         ->> 'combine_node_ord_no' )  :: int          as combine_node_ord_no
-- --   , (a_j_node         ->> 'node_no'             )  :: int          as node_no
-- --   , (a_j_node         ->> 'node_type'           )                  as node_type
-- --   , (a_j_node         ->> 'node_fn_type'        )                  as node_fn_type
-- --   , (a_j_node         ->> 'node_fn_asso_value'  )  :: float[]      as node_fn_asso_value
-- --   , (a_j_node         ->> 'node_desc'           )                  as node_desc
-- --   from cte_j_trs, jsonb_path_query(a_j_trs, '$.nodes[*]') tb_a_nodes(a_j_node)
-- -- ) -- select combine_node_ord_no, node_no, node_type, node_fn_type, node_fn_asso_value, node_desc from cte_nodes
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