drop procedure if exists sm_sc.prc_del_pretrain_model_p(bigint);
create or replace procedure sm_sc.prc_del_pretrain_model_p
(
  i_work_no           bigint
) as 
$$
declare
begin
  
  perform 
    sm_sc.__fv_delete_kv(array_agg(p_node_depdt)) 
  , sm_sc.__fv_delete_kv(array_agg(p_node_dloss_ddepdt)) 
  from sm_sc.tb_nn_node 
  where work_no = i_work_no
  ;
  delete from sm_sc.tb_nn_node where work_no = i_work_no;
  
  perform 
    sm_sc.__fv_delete_kv(array_agg(p_ddepdt_dindepdt)) 
  from sm_sc.tb_nn_path 
  where work_no = i_work_no
  ;
  delete from sm_sc.tb_nn_path where work_no = i_work_no;
  
  delete from sm_sc.tb_nn_train_input_buff where work_no = i_work_no;
  delete from sm_sc.tb_classify_task where work_no = i_work_no;
  commit;
end
$$
language plpgsql;

-- call 
-- sm_sc.prc_del_pretrain_model_p
-- (
--   -000000002
-- );