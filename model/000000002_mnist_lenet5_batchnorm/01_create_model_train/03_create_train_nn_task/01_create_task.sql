delete from sm_sc.tb_classify_task where work_no = -000000002; commit;
insert into sm_sc.tb_classify_task(work_no, loss_fn_type)
select -000000002, array[201];
commit;