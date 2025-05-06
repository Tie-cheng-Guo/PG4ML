delete from sm_sc.tb_classify_task where work_no = -000000016; commit;
insert into sm_sc.tb_classify_task(work_no, loss_fn_type)
select -000000016, '201';
commit;