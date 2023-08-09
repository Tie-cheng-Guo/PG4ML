delete from sm_sc.tb_classify_task where work_no = 2022030501; commit;
insert into sm_sc.tb_classify_task(work_no)
select 2022030501;
commit;