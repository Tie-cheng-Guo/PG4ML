-- 清理部署模型
delete from sm_sc.__vt_nn_node where work_no = -000000001;
delete from sm_sc.__vt_nn_path where work_no = -000000001;
delete from sm_sc.__vt_tmp_nn_node where work_no = -000000001;
delete from sm_sc.__vt_nn_sess where work_no = -000000001;

-- 清理训练模型
delete from sm_sc.tb_classify_task where work_no = -000000001;
delete from sm_sc.tb_nn_node where work_no = -000000001;
delete from sm_sc.tb_nn_path where work_no = -000000001;

-- 清理数据集
delete from sm_sc.tb_nn_train_input_buff where work_no = -000000001;
drop table if exists sm_dat.__vt_nn_node_000000001;
drop table if exists sm_dat.__vt_nn_path_000000001;
drop table if exists sm_dat.tb_tmp_mnist_000000001;