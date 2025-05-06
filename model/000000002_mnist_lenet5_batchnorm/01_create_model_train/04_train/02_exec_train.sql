-- 训练
-- -- select * from pg_settings where name ~ 'paral' or name in ('max_worker_processes') limit 100
-- set min_parallel_table_scan_size = 0;
-- set min_parallel_index_scan_size = 0;
-- set force_parallel_mode = 'off';
-- set max_parallel_workers_per_gather = 64;
-- set parallel_setup_cost = 0;
-- set parallel_tuple_cost = 0.0;

-- 参数一：work_no
-- 参数二：初始学习率
-- 参数三：损失函数梯度阈值。小于阈值后，训练中止
call sm_sc.prc_nn_train
(
  i_work_no                         =>  -000000002
, i_learn_rate                      =>  0.00084
, i_loss_delta_least_stop_threshold =>  0.001
);