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
  array[array_length(max(tb_a_node.node_depdt_vals)    , 1), array_length(max(tb_a_node.node_depdt_vals)    , 2)]  as len_vals            ,
  array[array_length(max(case when tb_a_path.path_ord_no = 1 then tb_a_path.ddepdt_dindepdt end) , 1), array_length(max(case when tb_a_path.path_ord_no = 1 then tb_a_path.ddepdt_dindepdt end) , 2)]  as len_ddepdt_dindepdt_1st         ,
  array[array_length(max(case when tb_a_path.path_ord_no = 2 then tb_a_path.ddepdt_dindepdt end) , 1), array_length(max(case when tb_a_path.path_ord_no = 2 then tb_a_path.ddepdt_dindepdt end) , 2)]  as len_ddepdt_dindepdt_2nd         ,
  array[array_length(max(tb_a_node.node_dloss_ddepdt), 1), array_length(max(tb_a_node.node_dloss_ddepdt), 2)]  as len_dloss_dy
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
, array_dims(node_depdt_vals)                            as a_len
, |@/=| node_depdt_vals                                  as a_depdt_ptp
, |@/| node_depdt_vals                                   as a_depdt_avg
, sm_sc.fv_aggr_slice_is_exists_null(node_depdt_vals)    as a_depdt_is_exists_null
, |@/=| node_dloss_ddepdt                                as a_dloss_ddepdt_ptp
, |@/| node_dloss_ddepdt                                 as a_dloss_ddepdt_avg
, sm_sc.fv_aggr_slice_is_exists_null(node_dloss_ddepdt)  as a_dloss_ddepdt_is_exists_null
from sm_sc.tb_nn_node
where work_no = -000000002
order by nn_depth_no desc