drop procedure if exists sm_sc.prc_del_infer_model(bigint);
create or replace procedure sm_sc.prc_del_infer_model
(
  i_work_no           bigint
) as 
$$
declare
begin
  delete from sm_sc.__vt_nn_node where work_no = i_work_no;
  delete from sm_sc.__vt_nn_path where work_no = i_work_no;
  delete from sm_sc.__vt_tmp_nn_node where work_no = i_work_no;
  commit;
end
$$
language plpgsql;

-- call 
-- sm_sc.prc_del_infer_model
-- (
--   -000000002
-- );