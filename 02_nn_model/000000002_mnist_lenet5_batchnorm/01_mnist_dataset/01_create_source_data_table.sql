-- step 1. 创建定制表 tb_tmp_mnist_0201 用于接收原始数据集
-- drop table if exists sm_sc.tb_tmp_mnist_0201;
create table sm_sc.tb_tmp_mnist_0201
(
  num       smallint,
  num_arr   smallint[]
);