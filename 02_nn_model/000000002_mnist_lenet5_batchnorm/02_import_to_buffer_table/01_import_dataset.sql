-- step 3. 从 tb_tmp_mnist_0201 加工至本框架公共的 buff 表 sm_sc.tb_nn_train_input_buff，生成 onehot 编码，作为 i_y
delete from sm_sc.tb_nn_train_input_buff
where work_no = 2022030501;
commit;
insert into sm_sc.tb_nn_train_input_buff
(
  work_no,
  ord_no,
  i_y,
  i_x
)
select 
  2022030501 as work_no,
  row_number() over(order by num) as ord_no,
  case num
  when 0
    then array[1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  when 1
    then array[0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  when 2
    then array[0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  when 3
    then array[0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  when 4
    then array[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  when 5
    then array[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
  when 6
    then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]
  when 7
    then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0]
  when 8
    then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]
  when 9
    then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]
end as i_y
,
  num_arr as i_x
from sm_sc.tb_tmp_mnist_0201
;