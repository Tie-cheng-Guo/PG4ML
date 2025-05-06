-- ----------------------------------------------------------------------------------------------------------------------------
-- part 1. 首先
        -- 设置小批量随机的样本数量和策略，可以细化至每个分类：训练过程中，准备过程之前，动态修改 v_batch_amt
        
        call sm_sc.prc_nn_prepare_p
        (
          i_work_no             =>  -000000001
        , i_limit_train_times   =>  300    -- 本轮(第一轮)训练规划至 300 次，至于已经训练了几次，
                                           -- 要查询 select learn_cnt from sm_sc.tb_classify_task where work_no = -000000001 
        , i_batch_amt_per_range =>  array_fill(16, array[4])     -- 在此修改v_batch_amt
        , i_batch_range         =>  
          array
          [
            int4range(    01,    100, '[]')
          , int4range(   101,    200, '[]')
          , int4range(   201,    300, '[]')
          , int4range(   301,    400, '[]')
          ]
        );
        
        -- -- 执行训练 
        -- -- call sm_sc.prc_nn_train(

-- ----------------------------------------------------------------------------------------------------------------------------
-- part 2. 其次
        -- 设置小批量随机的样本数量和策略，可以细化至每个分类：训练过程中，准备过程之前，动态修改 v_batch_amt

        call sm_sc.prc_nn_prepare_p
        (
          i_work_no             =>  -000000001
        , i_limit_train_times   =>  400    -- 本轮(第一轮)训练规划至 300 次，至于已经训练了几次，
                                           -- 要查询 select learn_cnt from sm_sc.tb_classify_task where work_no = -000000001 
        , i_batch_amt_per_range =>  array_fill(16, array[4])     -- 在此修改v_batch_amt
        , i_batch_range         =>  
          array
          [
            int4range(   401,    500, '[]')
          , int4range(   501,    600, '[]')
          , int4range(   601,    700, '[]')
          , int4range(   701,    800, '[]')
          ]
        );
        
        -- -- 执行训练 
        -- -- call sm_sc.prc_nn_train(

-- ----------------------------------------------------------------------------------------------------------------------------
-- part 3. 再次
        -- 设置小批量随机的样本数量和策略，可以细化至每个分类：训练过程中，准备过程之前，动态修改 v_batch_amt
        
        call sm_sc.prc_nn_prepare_p
        (
          i_work_no             =>  -000000001
        , i_limit_train_times   =>  500    -- 本轮(第一轮)训练规划至 300 次，至于已经训练了几次，
                                           -- 要查询 select learn_cnt from sm_sc.tb_classify_task where work_no = -000000001 
        , i_batch_amt_per_range =>  array_fill(16, array[4])     -- 在此修改v_batch_amt
        , i_batch_range         =>  
          array
          [
            int4range(   801,    900, '[]')
          , int4range(   901,   1000, '[]')
          , int4range(  1001,   1100, '[]')
          , int4range(  1101,   1200, '[]')
          ]
        );
        
        -- -- 执行训练 
        -- -- call sm_sc.prc_nn_train(