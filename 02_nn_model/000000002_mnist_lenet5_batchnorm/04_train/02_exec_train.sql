-- 训练
select * from pg_settings where name ~ 'paral' or name in ('max_worker_processes') limit 100
-- set min_parallel_table_scan_size = 0;
-- set min_parallel_index_scan_size = 0;
-- set force_parallel_mode = 'off';
-- set max_parallel_workers_per_gather = 64;
-- set parallel_setup_cost = 0;
-- set parallel_tuple_cost = 0.0;

-- 参数一：work_no
-- 参数二：损失函数类型，参看字典表 sm_sc.tb_dic_enum where enum_name = 'loss_fn_type'
-- 参数三：初始学习率
-- 参数四：损失函数梯度阈值。小于阈值后，训练中止
call sm_sc.prc_nn_train
(
  2022030501   ,
  2        ,
  0.00084      ,
  0.001,
  true
);