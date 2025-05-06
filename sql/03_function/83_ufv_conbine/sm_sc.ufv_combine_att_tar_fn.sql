-- drop function if exists sm_sc.ufv_combine_att_tar_fn(int, int, int, int);
create or replace function sm_sc.ufv_combine_att_tar_fn
(
  i_z_heigh              int                       -- 通常对应 i_seq_len
, i_z_width              int                       -- 通常对应 i_w_ff1_width_ff2_heigh 和 i_token_embedding_len
, i_token_dic_len        int                       -- 词表中 token 的总数量
, i_array_ndims          int    default 3          -- 张量维度数，3 或 4
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
      10 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '00_const'                                                       as node_fn_type
    , case i_array_ndims 
        when 3
          then array[1, i_z_width, i_token_dic_len] 
        when 4
          then array[1, 1, i_z_width, i_token_dic_len] 
      end                                                              as node_fn_asso_value
    , 'tar_fn token_dic_embedding'                                     as node_desc       
    union all                                                          
    select                                                             
      20 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_prod_mx'                                                     as node_fn_type
    , array[i_z_heigh, i_z_width, i_token_dic_len]                     as node_fn_asso_value
    , 'tar_fn prod_mx'                                                 as node_desc
    union all                                                          
    select                                                             
      30 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '01_add'                                                         as node_fn_type
    , null                                                             as node_fn_asso_value
    , 'tar_fn add padding'                                             as node_desc
    union all                                                          
    select                                                             
      40 :: int                                                        as a_tmp_no
    , lower(sm_sc.fv_get_global_seq())                                 as node_no
    , null                                                             as node_type
    , '03_softmax'                                                     as node_fn_type
    , case i_array_ndims
        when 3
          then array[1, 1, i_token_dic_len]                          
        when 4
          then array[1, 1, 1, i_token_dic_len]                                   
      end                                                              as node_fn_asso_value
    , 'tar_fn softmax'                                                 as node_desc   
  ),
  -- 准备 path
  cte_paths as 
  (
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 2                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 20               -- tar_fn prod_mx
      and tb_a_back_node.a_tmp_no = 10               -- tar_fn token_dic_embedding
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 30               -- tar_fn add padding
      and tb_a_back_node.a_tmp_no = 20               -- tar_fn prod_mx
    union all 
    select 
      tb_a_fore_node.node_no                         as fore_node_no   
    , 1                                              as path_ord_no
    , tb_a_back_node.node_no                         as back_node_no     
    from cte_nodes tb_a_fore_node
      , cte_nodes tb_a_back_node
    where tb_a_fore_node.a_tmp_no = 40               -- tar_fn softmax
      and tb_a_back_node.a_tmp_no = 30               -- tar_fn add padding
  ),
  -- 准备输入路径
  cte_input_paths as 
  (
    select                                           -- trs decoder as input p1
      node_no                                        as fore_node_no
    , 1                                              as path_ord_no
    , 1                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 20
    union all
    select                                           -- trs decoder as input p1
      node_no                                        as fore_node_no
    , 2                                              as path_ord_no
    , 2                                              as combine_in_no
    from cte_nodes
    where a_tmp_no = 30
  ),
  -- 准备输出节点
  cte_output_nodes as 
  (
    select 
      node_no
    , 1                                              as combine_out_no
    from cte_nodes
    where a_tmp_no = 40
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
--   sm_sc.ufv_combine_att_tar_fn
--   (
--     40
--   , 64
--   , 25000
--   )

-- with 
-- cte_j_trs as 
-- (
--   select
--     -- 以下 jsonb 由调用 sm_sc.ufv_combine_att_tar_fn 获得
--     '
--       {
--         "nodes": [
--           {
--             "node_no": 4916,
--             "node_desc": "token_dic_embedding",
--             "node_fn_type": "00_const",
--             "node_fn_asso_value": "{1,64,25000}"
--           },
--           {
--             "node_no": 4917,
--             "node_desc": "attention |**| (|^~| token_dic_embedding)",
--             "node_fn_type": "01_prod_mx",
--             "node_fn_asso_value": "{40,64,25000}"
--           },
--           {
--             "node_no": 4918,
--             "node_desc": "seq token probability on each dic embedding",
--             "node_fn_type": "03_softmax",
--             "node_fn_asso_value": "{1,1,25000}"
--           },
--           {
--             "node_no": 4919,
--             "node_desc": "get seq token probability on true token by idx",
--             "node_fn_type": "81_query_from_row"
--           },
--           {
--             "node_no": 4920,
--             "node_desc": "^!` (u[1] ... u[i])",
--             "node_fn_type": "01_ln"
--           },
--           {
--             "node_no": 4921,
--             "node_desc": "sum(^!` (u[1] ... u[i]))",
--             "node_fn_type": "07_aggr_slice_sum"
--           },
--           {
--             "node_no": 4922,
--             "node_desc": "-` sum(^!` (u[1] ... u[i]))",
--             "node_fn_type": "01_0sub"
--           }
--         ],
--         "paths": [
--           {
--             "path_ord_no": 2,
--             "back_node_no": 4916,
--             "fore_node_no": 4917
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 4917,
--             "fore_node_no": 4918
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 4918,
--             "fore_node_no": 4919
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 4919,
--             "fore_node_no": 4920
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 4920,
--             "fore_node_no": 4921
--           },
--           {
--             "path_ord_no": 1,
--             "back_node_no": 4921,
--             "fore_node_no": 4922
--           }
--         ],
--         "input_paths": [
--           {
--             "path_ord_no": 1,
--             "fore_node_no": 4917,
--             "combine_in_no": 1
--           },
--           {
--             "path_ord_no": 2,
--             "fore_node_no": 4919,
--             "combine_in_no": 2
--           }
--         ],
--         "output_nodes": [
--           {
--             "combine_out_no": 1,
--             "output_node_no": 4922
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
