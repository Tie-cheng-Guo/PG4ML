-- step 1. 创建定制表 tb_tmp_mnist_000000016 用于接收原始数据集
create schema if not exists sm_dat;
-- drop table if exists sm_dat.tb_tmp_mnist_000000016;
create table if not exists sm_dat.tb_tmp_mnist_000000016
(
  num       smallint,
  num_arr   smallint[]
);