insert into sm_sc.__vt_nn_node
(
  work_no, node_no, node_type, node_fn_type, node_fn_asso_value, nn_depth_no, node_depdt_vals
)
select 
  work_no, node_no, node_type, node_fn_type, node_fn_asso_value, nn_depth_no, node_depdt_vals
from sm_dat.__vt_nn_node_000000002
;

insert into sm_sc.__vt_nn_path
(
  work_no, fore_node_no, path_ord_no, back_node_no 
)
select 
  work_no, fore_node_no, path_ord_no, back_node_no 
from sm_dat.__vt_nn_path_000000002
;

drop table if exists sm_dat.__vt_nn_node_000000002;
drop table if exists sm_dat.__vt_nn_path_000000002;