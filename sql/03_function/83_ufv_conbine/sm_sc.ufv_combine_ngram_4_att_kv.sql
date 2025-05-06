-- drop function if exists sm_sc.ufv_combine_ngram_4_att_kv(int, int, int);
create or replace function sm_sc.ufv_combine_ngram_4_att_kv
(
  i_seq_len                             int
, i_token_embedding_len                 int
, i_ngram_n                             int
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
    select                                           -- need token_embedding input as p1
      1 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_none'                                                        as node_fn_type
    , array
      [
        null :: float
      , i_ngram_n
      , i_token_embedding_len
      , 1
      , i_token_embedding_len
      , 0, 0, 0, 0
      , null
      ]                                                                as node_fn_asso_value
    , 'none'                                                           as node_desc       
    union all                                                          
    select                                                             
      a_ngram_no + 1 :: int                                           as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_sample_x'                                                    as node_fn_type
    , array
      [
        [i_ngram_n]
      , [null :: int]
      , [a_ngram_no]
      , [a_ngram_no]
      ]                                                                as node_fn_asso_value
    , 'sample_x'                                                       as node_desc
    from generate_series(1, i_ngram_n) tb_a_ngram_no(a_ngram_no)
    union all                                                          
    select                                                             
      i_ngram_n + 2 :: int                                             as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '06_aggr_mx_concat_x3'                                           as node_fn_type
    , array_fill
      (
        i_token_embedding_len
      , array[i_ngram_n]
      )                                                                as node_fn_asso_value
    , 'concat_x3'                                                      as node_desc
  ),
  -- 准备 path
  cte_paths as 
  (
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from generate_series(1, i_ngram_n) tb_a_ngram_no(a_ngram_no)
      , cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = a_ngram_no + 1  -- sample_x
      and tb_a_back_node.a_tmp_no = 1               -- pool_none
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , a_ngram_no                                     as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from generate_series(1, i_ngram_n) tb_a_ngram_no(a_ngram_no)
      , cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = i_ngram_n + 2   -- concat_x3
      and tb_a_back_node.a_tmp_no = a_ngram_no + 1  -- sample_x
  ),
  -- 准备输入路径
  cte_input_paths as 
  (
    select
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 1                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 1
  ),
  -- 准备输出节点
  cte_output_nodes as 
  (
    select 
      node_no
    , 1                                              as combine_out_no
    from cte_nodes
    where a_tmp_no = i_ngram_n + 2
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
--   sm_sc.ufv_combine_ngram_4_att_kv
--   (
--     40
--   , 64
--   )

-- with 
-- cte_j_trs as 
-- (
--   select
--     -- 以下 jsonb 由调用 sm_sc.ufv_combine_ngram_4_att_kv 获得
--     '
--       {
--         "nodes": [
--           {
--             "node_no": 82,
--             "node_desc": "+` token_embedding as res",
--             "node_type": null,
--             "node_fn_type": "01_add",
--             "node_fn_asso_value": null
--           },
--           {
--             "node_no": 83,
--             "node_desc": "layer_normalize",
--             "node_type": null,
--             "node_fn_type": "03_zscore",
--             "node_fn_asso_value": "{1,1,40}"
--           },
--           {
--             "node_no": 84,
--             "node_desc": "w1 of ffn",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{40,64}"
--           },
--           {
--             "node_no": 85,
--             "node_desc": "|**| w1 of ffn",
--             "node_type": null,
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{NULL,40,64}"
--           },
--           {
--             "node_no": 86,
--             "node_desc": "leaky_relu of ffn",
--             "node_type": null,
--             "node_fn_type": "03_leaky_relu",
--             "node_fn_asso_value": null
--           },
--           {
--             "node_no": 87,
--             "node_desc": "w2 of ffn",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{64,40}"
--           },
--           {
--             "node_no": 88,
--             "node_desc": "|**| w2 of ffn",
--             "node_type": null,
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{NULL,64,40}"
--           },
--           {
--             "node_no": 89,
--             "node_desc": "+` attention as res",
--             "node_type": null,
--             "node_fn_type": "01_add",
--             "node_fn_asso_value": null
--           }
--         ],
--         "paths": [
--           {
--             "path_ord_no": 1,
--             "back_node_no": 82,
--             "fore_node_no": 83
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 83,
--             "fore_node_no": 85
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 84,
--             "fore_node_no": 85
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 85,
--             "fore_node_no": 86
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 86,
--             "fore_node_no": 88
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 87,
--             "fore_node_no": 88
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 83,
--             "fore_node_no": 89
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 88,
--             "fore_node_no": 89
--           }
--         ],
--         "input_paths": [
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 82,
--             "combine_in_no": 1
--           },
--           {
--             "path_ord_no": 2,
--             "fore_node_no": 82,
--             "combine_in_no": 2
--           }
--         ],
--         "output_nodes": [
--           {
--             "combine_out_no": 1,
--             "output_node_no": 89
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
-- -- ) -- select node_no, node_type, node_fn_type, node_desc from cte_nodes
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
