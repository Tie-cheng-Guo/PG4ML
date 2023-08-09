-- 训练集预测
select 
  (a_y_no - 1) / 9 + 1 as real_num,    -- 此处的 7，即：随机小批量梯度下降的每个分组小批量采样数量，请自行调整
                                       -- 与训练准备脚本 ./11_test/02_mnist_lenet5_batchnorm/04_train/01_prepare.sql 中的 v_batch_amt 一致
  array_position
  (
    sm_sc.fv_mx_ele_2d_2_1d(((tb.node_o).m_vals)[a_y_no : a_y_no][ : ]),
    sm_sc.fv_aggr_slice_max(sm_sc.fv_mx_ele_2d_2_1d(((tb.node_o).m_vals)[a_y_no : a_y_no][ : ]))
  )
  ,((tb.node_o).m_vals)[a_y_no : a_y_no][ : ]
from sm_sc.tb_nn_node tb
  , generate_series(1, 9 * 10) tb_a(a_y_no)    -- 此处的 7，即：随机小批量梯度下降的每个分组小批量采样数量，请自行调整
                                               -- 与训练准备脚本 ./11_test/02_mnist_lenet5_batchnorm/04_train/01_prepare.sql 中的 v_batch_amt 一致
where tb.work_no = 2022030501
  and tb.node_no = 200000000
;
-- -- 预测集预测
-- with cte_pred as
-- (
--   select 
--     num,
--     sm_sc.fv_nn_in_out
--     (
--       2022030501, 
--       array[num_arr]    -- -- (array[num_arr] :: float[] -` 0.13066235) /` 0.30810782
--     ) as a_pred_out_arr
--   from sm_sc.tb_tmp_mnist_0201 limit 2
-- )
-- select 
--   num,
--   array_position
--   (
--     sm_sc.fv_mx_ele_2d_2_1d(a_pred_out_arr),
--     sm_sc.fv_aggr_slice_max(a_pred_out_arr)
--   ) - 1 as pred_out,
--   a_pred_out_arr
-- from cte_pred
-- ;

-- set min_parallel_table_scan_size = 8;
-- set min_parallel_index_scan_size = 16;
-- set force_parallel_mode = 'off';
-- set max_parallel_workers_per_gather = 1;
-- set parallel_setup_cost = 10000;
-- set parallel_tuple_cost = 10000.0;

with 
cte_rand as
(
  select 
	   a_no
  from unnest((sm_sc.fv_new_rand(array[1, 10]) *` 60001.0 :: float) :: int[] +` 1) tb_a(a_no) -- 此处的 10 为验证样本抽样数量，可自行调整为少于 60001 的数量，
                                                                                         -- 60001 为 mnist 数据集样本数量，
                                                                                         -- 每个样本 0.5 秒左右，无法并行查询。
),
cte_pred as
(
  select 
       ord_no,
	   i_y,
    sm_sc.fv_nn_in_out
    (
      2022030501, 
      array[i_x]
    ) as a_pred_out_arr
  from sm_sc.tb_nn_train_input_buff, cte_rand
  where work_no = 2022030501
    and ord_no = a_no
),
cte_out as 
(
select 
  ord_no,
  case 
    when ord_no between 1 and 5923
	  then 0
    when ord_no between 5924 and 12665
	  then 1
    when ord_no between 12666 and 18623
	  then 2
    when ord_no between 18624 and 24754
	  then 3
    when ord_no between 24755 and 30596
	  then 4
    when ord_no between 30597 and 36017
	  then 5
    when ord_no between 36018 and 41935
	  then 6
    when ord_no between 41936 and 48200
	  then 7
    when ord_no between 48201 and 54052
	  then 8
    when ord_no between 54053 and 60001
	  then 9
  end as real_out,
  array_position
  (
    sm_sc.fv_mx_ele_2d_2_1d(a_pred_out_arr),
    sm_sc.fv_aggr_slice_max(a_pred_out_arr)
  ) - 1 as pred_out,
  i_y,
  a_pred_out_arr
from cte_pred
)
select count(*) from cte_out
where real_out <> pred_out
;