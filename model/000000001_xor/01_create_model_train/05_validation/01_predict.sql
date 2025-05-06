      select 
        o_depdt_01
      from
        sm_sc.ft_nn_in_out_p
        (
          -000000001
        , 0             -- sess_id = 0 训练后的缺省部署，仅用于测试。该 sess_id = 0 不用事先显式 call prc_subscribe_sess()
        , array[[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]] :: float[]
            +` sm_sc.fv_new_randn(0.0 :: float, 0.1, array[4, 2])
        ) tb_a