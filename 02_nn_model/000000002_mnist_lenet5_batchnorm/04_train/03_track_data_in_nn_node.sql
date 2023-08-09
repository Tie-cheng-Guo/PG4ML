-- 任务跟踪
select * from sm_sc.tb_classify_task where work_no = 2022030501

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
  max(tb_a_node.node_o_len                          ) as node_o_len                             ,
  max(array_length(tb_a_node.pick_y_idx, 1)         ) as cnt_pick                               ,
  array[array_length(max(tb_a_node.node_y_vals)    , 1), array_length(max(tb_a_node.node_y_vals)    , 2)]  as len_vals            ,
  array[array_length(max(case when tb_a_path.path_ord_no = 1 then tb_a_path.dy_dx end) , 1), array_length(max(case when tb_a_path.path_ord_no = 1 then tb_a_path.dy_dx end) , 2)]  as len_dy_dx_1st         ,
  array[array_length(max(case when tb_a_path.path_ord_no = 2 then tb_a_path.dy_dx end) , 1), array_length(max(case when tb_a_path.path_ord_no = 2 then tb_a_path.dy_dx end) , 2)]  as len_dy_dx_2nd         ,
  array[array_length(max(tb_a_node.node_dloss_dy), 1), array_length(max(tb_a_node.node_dloss_dy), 2)]  as len_dloss_dy
from sm_sc.tb_nn_node tb_a_node
left join sm_sc.tb_nn_path tb_a_path
on tb_a_path.fore_node_no = tb_a_node.node_no
  and tb_a_node.work_no = 2022030501
where tb_a_node.work_no = 2022030501
group by tb_a_node.node_no, tb_a_node.is_fore_node, tb_a_node.is_back_node
order by tb_a_node.node_no
