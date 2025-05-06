drop procedure if exists sm_sc.prc_del_pretrain_model(bigint);
create or replace procedure sm_sc.prc_del_pretrain_model
(
  i_work_no           bigint
) as 
$$
declare
begin
  delete from sm_sc.tb_classify_task where work_no = i_work_no;
  delete from sm_sc.tb_nn_node where work_no = i_work_no;
  delete from sm_sc.tb_nn_path where work_no = i_work_no;
  delete from sm_sc.tb_nn_train_input_buff where work_no = i_work_no;
  commit;
end
$$
language plpgsql;

-- call 
-- sm_sc.prc_del_pretrain_model
-- (
--   -000000002
-- );