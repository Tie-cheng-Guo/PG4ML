-- set min_parallel_table_scan_size = 8;
-- set min_parallel_index_scan_size = 16;
-- set force_parallel_mode = 'off';
-- set max_parallel_workers_per_gather = 1;
-- set parallel_setup_cost = 10000;
-- set parallel_tuple_cost = 10000.0;

-- 单条输入预测
-- set min_parallel_table_scan_size = 8;
-- set min_parallel_index_scan_size = 16;
-- set force_parallel_mode = 'off';
-- set max_parallel_workers_per_gather = 1;
-- set parallel_setup_cost = 10000;
-- set parallel_tuple_cost = 10000.0;

-- 单条输入预测
with 
cte_fft as 
(
  select 
    i_indepdt_01 as a_fft
  from sm_sc.tb_nn_train_input_buff
  where work_no = -000000019
    and ord_no = 846  -- 41, 91, 141, 191; 241, 291, 341, 391; 1641, 1691, 1741, 1791;
),
cte_ifft as 
(
  select 
    sm_sc.fv_sgn_ifft2
    (
      -- 1764.0 的含义: 42.0 * 42.0,  图像在制作成数据集的时候在直流频段上按照功率谱理论做了抑制，避免损失函数过大；推理时，还原为空间域要放大回来。
      ((a_pred_out_arr[1 : 1][1 : 1][ : ][ : ] |><| array[42, 42]) :: sm_sc.typ_l_complex[] *` ((1764.0 * 1.0, 0.0) :: sm_sc.typ_l_complex))
      +`
      ((a_pred_out_arr[1 : 1][2 : 2][ : ][ : ] |><| array[42, 42]) :: sm_sc.typ_l_complex[] *` ((0.0, 1764.0 * 1.0) :: sm_sc.typ_l_complex))
    ) 
      as a_ifft
  from cte_fft tb_a_fft
  , sm_sc.ft_nn_in_out_p
    (
      -000000019
    , 0 -- 这里填入申请到的 o_output_sess_id
    , array[a_fft]
    ) tb_a_pred_out_arr(a_pred_out_arr)
),
cte_redistr as 
(
  select 
    sm_sc.fv_redistr_0_1
    (
      (
        (0.0 :: float @>` (sm_sc.fv_opr_real(a_ifft) +` 0.0 ^` 2.0))
        +`
        (0.0 :: float @>` (sm_sc.fv_opr_imaginary(a_ifft) +` 0.0 ^` 2.0))
      )
      ^` 0.5
    ) 
    *` 256.0 
    -` 1.0  
    as a_output
  from cte_ifft
)
select 
  a_output >` ((|@/<| a_output) + 40.0)
from cte_redistr


-- select * from sm_sc.tb_nn_train_input_buff where work_no = -000000019 and ord_no = 32457 limit 5



-- -------------------------------------------------------
-- mnist 手写体数字位图矩阵可视化处理
-- 
-- ((\d+,){27,27}\d+)           \1\r\n
-- (?<=,|\{)(\d)(?=,|\r|\n)     00\1
-- (?<=,|\{)(\d\d)(?=,|\r|\n)   0\1
-- 000                          替换为三个空格
-- ,                            替换为空