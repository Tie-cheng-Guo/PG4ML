-- 任务跟踪
select * from sm_sc.tb_classify_task where work_no = -000000002

-- 训练模型跟踪查看
select 
  -- work_no                                                                                    ,
  node_no                                                                                       ,
  max(tb_a_node.node_type                           ) as node_type                              ,
  max(tb_a_node.node_fn_type                        ) as node_fn_type                           ,
  max(array_length(tb_a_node.node_fn_asso_value, 1) ) as len_asso_val                           ,
  max(tb_a_node.nn_depth_no                         ) as nn_depth_no                            ,
  max(tb_a_node.learn_cnt_fore                      ) as learn_cnt_fore                         ,
  max(tb_a_node.learn_cnt_back                      ) as learn_cnt_back                         ,
  tb_a_node.is_fore_node                              as is_fore_node                           ,
  tb_a_node.is_back_node                              as is_back_node                           ,
  max(tb_a_node.node_depdt_len                      ) as node_o_len                             ,
  max(array_length(tb_a_node.pick_depdt_idx, 1)         ) as cnt_pick                               ,
  max(array_dims(sm_sc.__fv_get_kv(p_node_depdt)))  as len_vals            ,
  max(case when tb_a_path.path_ord_no = 1 then array_dims(sm_sc.__fv_get_kv(tb_a_path.p_ddepdt_dindepdt)) end)  as len_ddepdt_dindepdt_1st         ,
  max(case when tb_a_path.path_ord_no = 2 then array_dims(sm_sc.__fv_get_kv(tb_a_path.p_ddepdt_dindepdt)) end)  as len_ddepdt_dindepdt_2nd         ,
  max(array_dims(sm_sc.__fv_get_kv(tb_a_node.p_node_dloss_ddepdt))) as len_dloss_dy
from sm_sc.tb_nn_node tb_a_node
left join sm_sc.tb_nn_path tb_a_path
on tb_a_path.fore_node_no = tb_a_node.node_no
  and tb_a_node.work_no = -000000002
where tb_a_node.work_no = -000000002
group by tb_a_node.node_no, tb_a_node.is_fore_node, tb_a_node.is_back_node
order by tb_a_node.node_no

-- 查看神经网络各节点因变量的数值分布
select 
  node_no
, node_type
, node_fn_type
, nn_depth_no
, array_dims(sm_sc.__fv_get_kv(p_node_depdt))                            as a_len
, |@/=| sm_sc.__fv_get_kv(p_node_depdt)                                  as a_depdt_ptp
, |@/| sm_sc.__fv_get_kv(p_node_depdt)                                   as a_depdt_avg
, sm_sc.fv_aggr_slice_is_exists_null(sm_sc.__fv_get_kv(p_node_depdt))    as a_depdt_is_exists_null
, |@/=| sm_sc.__fv_get_kv(p_node_dloss_ddepdt)                                as a_dloss_ddepdt_ptp
, |@/| sm_sc.__fv_get_kv(p_node_dloss_ddepdt)                                 as a_dloss_ddepdt_avg
, sm_sc.fv_aggr_slice_is_exists_null(sm_sc.__fv_get_kv(p_node_dloss_ddepdt))  as a_dloss_ddepdt_is_exists_null
from sm_sc.tb_nn_node
where work_no = -000000002
order by nn_depth_no desc