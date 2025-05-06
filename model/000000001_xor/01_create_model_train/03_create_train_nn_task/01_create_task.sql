        delete from sm_sc.tb_classify_task where work_no = -000000001;
        insert into sm_sc.tb_classify_task(work_no, loss_fn_type)
        select -000000001, '101';   -- v_work_no, 最小二乘法损失函数类型