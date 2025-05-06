-- step 1. 创建定制表 tb_tmp_mnist_000000002 用于接收原始数据集
create schema if not exists sm_dat;
-- drop table if exists sm_dat.tb_nn_node_000000002;
create table if not exists sm_dat.__vt_nn_node_000000002
(
  work_no                 bigint       ,         
  node_no                 bigint       ,      
  node_type               varchar(64)  ,  
  node_fn_type            varchar(64)  ,  
  node_fn_asso_value      float[]      ,       
  nn_depth_no             int          ,          
  node_depdt_vals         float[]      ,    
  primary key (work_no, node_no)
)
with
(parallel_workers = 64)
;
-- drop table if exists sm_dat.tb_nn_node_000000002;
create table if not exists sm_dat.__vt_nn_path_000000002
(
  work_no            bigint              ,     -- 训练任务序号
  fore_node_no       bigint              ,     -- 反向传播发起节点(前向传播目标节点)神经元（包含层数信息）序号
  path_ord_no        int                 ,     -- 对应前向目标（也即抵达节点）的传递顺序，从1起始 w0, w1, w2...。
  back_node_no       bigint              ,     -- 前向传播发起节点(反向传播目标节点)神经元（包含层数信息）序号
  primary key (work_no, fore_node_no, path_ord_no)
)
with
(parallel_workers = 64)
;