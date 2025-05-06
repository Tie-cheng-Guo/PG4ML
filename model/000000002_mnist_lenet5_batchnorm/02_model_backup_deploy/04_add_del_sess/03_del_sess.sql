do 
$$
declare 
  v_sess_id_range    int8multirange := -- 此处设置要注销的 sess_id 数值范围，如下是将模型 -000000002 的 sess_id 全部注销
    (select int8range(min(sess_id), max(sess_id), '[]') :: int8multirange from sm_sc.__vt_tmp_nn_node where work_no = -000000002)
  ;
begin 
  call sm_sc.prc_nn_del_sess
  (
    -000000002
  , v_sess_id_range
  )
; 
end
$$
language plpgsql
;