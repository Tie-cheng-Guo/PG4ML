drop procedure if exists sm_sc.prc_nn_del_sess;
create or replace procedure sm_sc.prc_nn_del_sess
(
  i_work_no                          bigint            ,        -- 训练任务编号
  i_sess_multirange                  int8multirange
)
as
$$
-- declare -- here
  
begin
  set search_path to public;
  
  delete from sm_sc.__vt_nn_sess
  where work_no = i_work_no
    and sess_id <@ i_sess_multirange
  ;
  
  delete from sm_sc.__vt_tmp_nn_node
  where work_no = i_work_no
    and sess_id <@ i_sess_multirange
  ;
    
end
$$
language plpgsql;

