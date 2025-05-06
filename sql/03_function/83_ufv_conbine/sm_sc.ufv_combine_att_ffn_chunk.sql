-- drop function if exists sm_sc.ufv_combine_att_ffn_chunk(int, int, float, int);
create or replace function sm_sc.ufv_combine_att_ffn_chunk
(
  i_w_ff1_heigh_ff2_width              int    -- 通常对应 attention_qkv 的 i_v_width 
                                              -- 或多头的 i_v_width 的 concat
                                              -- 或 i_token_embedding_len
, i_w_ff1_width_ff2_heigh              int
, i_leak_relu_alpha                    float    default   0.01
, i_ndims                              int      default   3
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
    , '01_add'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '+` token_embedding as res'                                      as node_desc       
    union all                                                          
    select                                                             
      2 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_zscore'                                                      as node_fn_type
    , sm_sc.fv_lpad(array[1, i_w_ff1_heigh_ff2_width], array[1], i_ndims - 2)                             
                                                                       as node_fn_asso_value
    , 'layer_normalize'                                                as node_desc
    union all                                                          
    select                                                             
      3 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_w_ff1_heigh_ff2_width, i_w_ff1_width_ff2_heigh]          as node_fn_asso_value
    , 'w1 of ffn'                                                      as node_desc
    union all                                                          
    select                                                             
      4 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[null, i_w_ff1_heigh_ff2_width, i_w_ff1_width_ff2_heigh]    as node_fn_asso_value
    , '|**| w1 of ffn'                                                 as node_desc
    union all                                                          
    select                                                             
      5 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_leaky_relu'                                                  as node_fn_type
    , array[i_leak_relu_alpha]                                         as node_fn_asso_value
    , 'leaky_relu of ffn'                                              as node_desc
    union all                                                          
    select                                                             
      6 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , 'weight'                                                         as node_type
    , '00_const'                                                       as node_fn_type
    , array[i_w_ff1_width_ff2_heigh, i_w_ff1_heigh_ff2_width]          as node_fn_asso_value
    , 'w2 of ffn'                                                      as node_desc
    union all                                                          
    select                                                             
      7 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[null, i_w_ff1_width_ff2_heigh, i_w_ff1_heigh_ff2_width]    as node_fn_asso_value
    , '|**| w2 of ffn'                                                 as node_desc
    union all                                                          
    select                                                             -- this is output of single transformer encoder or decoder
      8 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_add'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , '+` attention as res'                                            as node_desc       
    union all                                                          
    select                                                             
      9 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_chunk'                                                       as node_fn_type
    , array[[1, 1],[i_w_ff1_heigh_ff2_width, i_w_ff1_width_ff2_heigh]] as node_fn_asso_value
    , 'chunk w1 of ffn'                                                as node_desc
    union all                                                          
    select                                                             
      10 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '04_chunk'                                                       as node_fn_type
    , array[[1, 1],[i_w_ff1_width_ff2_heigh, i_w_ff1_heigh_ff2_width]] as node_fn_asso_value
    , 'chunk w2 of ffn'                                                as node_desc
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
    where tb_a_fore_node.a_tmp_no = 2               -- layer_normalize
      and tb_a_back_node.a_tmp_no = 1               -- +` token_embedding as res
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 4               -- |**| w1 of ffn
      and tb_a_back_node.a_tmp_no = 2               -- layer_normalize
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 9               -- chunk w1 of ffn
      and tb_a_back_node.a_tmp_no = 3               -- w1 of ffn
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 4               -- |**| w1 of ffn
      and tb_a_back_node.a_tmp_no = 9               -- chunk w1 of ffn
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 5               -- leaky_relu of ffn
      and tb_a_back_node.a_tmp_no = 4               -- |**| w1 of ffn
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 7               -- |**| w2 of ffn
      and tb_a_back_node.a_tmp_no = 5               -- leaky_relu of ffn
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 10              -- chunk w2 of ffn
      and tb_a_back_node.a_tmp_no = 6               -- w2 of ffn
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 7               -- |**| w2 of ffn
      and tb_a_back_node.a_tmp_no = 10              -- chunk w2 of ffn
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 8               -- +` attention as res
      and tb_a_back_node.a_tmp_no = 2               -- layer_normalize
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 8               -- +` attention as res
      and tb_a_back_node.a_tmp_no = 7               -- |**| w2 of ffn
  ),
  -- 准备输入路径
  cte_input_paths as 
  (
    select                                           -- need token_embedding input as p1
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 1                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 1
    union all
    select                                           -- need token_embedding input as p1
      node_no                                        as fore_node_no
    , 2                                              as path_ord_no
    , 2                                              as combine_in_no
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
    where a_tmp_no = 8
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
--   sm_sc.ufv_combine_att_ffn_chunk
--   (
--     40
--   , 64
--   )

-- with 
-- cte_j_trs as 
-- (
--   select
--     -- 以下 jsonb 由调用 sm_sc.ufv_combine_att_ffn_chunk 获得
--     '
--       {
--         "nodes": [
--           {
--             "node_no": 46,
--             "node_desc": "+` token_embedding as res",
--             "node_fn_type": "01_add",
--             "combine_node_ord_no": 1
--           },
--           {
--             "node_no": 47,
--             "node_desc": "layer_normalize",
--             "node_fn_type": "03_zscore",
--             "combine_node_ord_no": 2,
--             "node_fn_asso_value": "{1,1,40}"
--           },
--           {
--             "node_no": 48,
--             "node_desc": "w1 of ffn",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 3,
--             "node_fn_asso_value": "{40,64}"
--           },
--           {
--             "node_no": 49,
--             "node_desc": "|**| w1 of ffn",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 4,
--             "node_fn_asso_value": "{NULL,40,64}"
--           },
--           {
--             "node_no": 50,
--             "node_desc": "leaky_relu of ffn",
--             "node_fn_type": "03_leaky_relu",
--             "combine_node_ord_no": 5,
--             "node_fn_asso_value": "{0.01}"
--           },
--           {
--             "node_no": 51,
--             "node_desc": "w2 of ffn",
--             "node_type": "weight",
--             "node_fn_type": "00_const",
--             "combine_node_ord_no": 6,
--             "node_fn_asso_value": "{64,40}"
--           },
--           {
--             "node_no": 52,
--             "node_desc": "|**| w2 of ffn",
--             "node_fn_type": "01_prod_mx",
--             "combine_node_ord_no": 7,
--             "node_fn_asso_value": "{NULL,64,40}"
--           },
--           {
--             "node_no": 53,
--             "node_desc": "+` attention as res",
--             "node_fn_type": "01_add",
--             "combine_node_ord_no": 8
--           }
--         ],
--         "paths": [
--           {
--             "path_ord_no": 1,
--             "back_node_no": 46,
--             "fore_node_no": 47
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 47,
--             "fore_node_no": 49
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 48,
--             "fore_node_no": 49
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 49,
--             "fore_node_no": 50
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 50,
--             "fore_node_no": 52
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 51,
--             "fore_node_no": 52
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 47,
--             "fore_node_no": 53
--           },
--           {
--             "path_ord_no": 2,
--             "back_node_no": 52,
--             "fore_node_no": 53
--           }
--         ],
--         "combine_no": 54,
--         "input_paths": [
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 46,
--             "combine_in_no": 1
--           },
--           {
--             "path_ord_no": 2,
--             "fore_node_no": 46,
--             "combine_in_no": 2
--           }
--         ],
--         "output_nodes": [
--           {
--             "combine_out_no": 1,
--             "output_node_no": 53
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
-- -- ) -- select combine_node_ord_no, node_no, node_type, node_fn_type, node_desc from cte_nodes
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
