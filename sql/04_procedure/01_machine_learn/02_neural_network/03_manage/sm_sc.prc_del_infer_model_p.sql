drop procedure if exists sm_sc.prc_del_infer_model_p(bigint);
create or replace procedure sm_sc.prc_del_infer_model_p
(
  i_work_no           bigint
) as 
$$
declare
begin
  delete from sm_sc.__vt_tmp_nn_node 
  where work_no = i_work_no
  ;
  
  perform 
    sm_sc.__fv_delete_kv(array_agg(p_node_depdt)) 
  from sm_sc.__vt_nn_node 
  where work_no = i_work_no
  ;
  delete from sm_sc.__vt_nn_node 
  where work_no = i_work_no
  ; 
    
  delete from sm_sc.__vt_nn_path where work_no = i_work_no;
  
  perform 
    sm_sc.__fv_delete_kv(array_agg(p_node_depdt)) 
  from sm_sc.__vt_tmp_nn_node 
  where work_no = i_work_no
  ;
end
$$
language plpgsql;

-- call 
-- sm_sc.prc_del_infer_model_p
-- (
--   -000000002
-- );