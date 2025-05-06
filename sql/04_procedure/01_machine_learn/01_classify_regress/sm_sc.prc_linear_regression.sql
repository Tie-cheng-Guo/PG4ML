-- 参考 https://blog.csdn.net/zhq9695/article/details/82805097

-- 初始学习率：1e-4
-- https://www.zhihu.com/question/387050717

drop procedure if exists sm_sc.prc_linear_regression;
create or replace procedure sm_sc.prc_linear_regression
(
  i_work_no                          bigint                                   ,                                                                                                -- 训练任务编号，用于任务暂停和接续、数据回显
  -- i_indepdt_01                                float[][]                       ,      -- [v_len_x1_y1][v_len_x2_w1]                                                         -- 乘法左矩阵，其中自行填写 w0 = 1.0 规约为该入参首列
  -- i_depdt_01                                float[][]                       ,      -- [v_len_x1_y1][v_len_w2_y2]                                                         -- 乘法结果
  i_learn_rate                       float    default    0.0001        ,                                                                                                -- 学习率
  i_limit_train_times                int               default    10000       ,                                                                                                -- 最大训练次数，然后未完成中止
  -- i_grad_descent_batch_cnt           int               default    10000       ,   -- 建议大一些，远远超过 v_i_indepdt_01, v_i_depdt_01 的各维度长度，尽量防止因小批量梯度下降引起的鞍点训练终止 -- 小批量梯度下降，每批记录数
  i_loss_delta_least_stop_threshold  float    default    0.0001                                                                                                       -- 触发收敛的损失函数梯度阈值
)
as
$$
declare -- here
-- -- 数学原理：已知矩阵 v_i_indepdt_01, v_i_depdt_01, 且 v_i_indepdt_01 |**| v_ret_w == (v_i_depdt_01), 求 v_ret_w
  v_i_indepdt_01                       float[][]:= (select array_agg(i_indepdt_01 order by ord_no) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
  v_i_depdt_01                       float[][]:= (select array_agg(i_depdt_01 order by ord_no) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
  v_len_x1_y1                 int               := array_length(v_i_indepdt_01, 1);
  v_len_x1_y1_samp            int               := least(greatest(floor(v_len_x1_y1 / 10), 10000), v_len_x1_y1, 10000);       -- least(i_grad_descent_batch_cnt, v_len_x1_y1); -- 小批量梯度下降，每批记录数 
  v_len_x2_w1                 int               := array_length(v_i_indepdt_01, 2);
  v_len_w2_y2                 int               := array_length(v_i_depdt_01, 2);
  v_ret_w                     float[];           -- [v_len_x2_w1][v_len_w2_y2] 
  v_x_rand_samp               float[];           -- [v_len_x1_y1_samp][v_len_x2_w1];
  v_y_rand_samp               float[];           -- [v_len_x1_y1][v_len_w2_y2]
  v_cur_loss_delta            float[];           -- [v_len_x2_w1][v_len_w2_y2]
  -- -- v_cur_loss_delta_last       float[];           -- [v_len_x2_w1][v_len_w2_y2]
  v_cur_no                    int               := 1;
  v_cur_loss_delta_l1_sum     float[];           -- [v_len_x2_w1][v_len_w2_y2]   
  v_cur_loss_delta_l2_sum     float[];           -- [v_len_x2_w1][v_len_w2_y2]   
  v_beta_l1                   float    := 0.9;
  v_beta_l2                   float    := 0.999;
  v_grad_l1                   float;             -- 寄存梯度本次变化的一阶矩，优化重复计算


begin
  set search_path to public;
  -- 审计 array_length(v_i_depdt_01, 1) == v_len_x1_y1
  if array_length(v_i_depdt_01, 1) <> v_len_x1_y1
  then
    raise exception 'error length of v_i_depdt_01';
  end if;

  -- 新建任务或者提取既有任务寄存信息
  if exists (select  from sm_sc.tb_classify_task where work_no = i_work_no)
  then
    select 
      -- work_no,
      coalesce(learn_cnt + 1, v_cur_no),
      -- loss_delta,
      coalesce(ret_w, sm_sc.fv_new_randn(0.0 :: float, 0.5 :: float, array[v_len_x2_w1, v_len_w2_y2]))
    into  
      v_cur_no,
      v_ret_w
    from sm_sc.tb_classify_task 
    where work_no = i_work_no
    ;
  else
    insert into sm_sc.tb_classify_task
    (
      work_no, 
      learn_cnt, 
      -- loss_delta,
      ret_w
    )
    select 
      i_work_no, 
      0,
      -- sm_sc.fv_aggr_slice_sum(sqart(v_cur_loss_delta ^` 2)), 
      coalesce(ret_w, sm_sc.fv_new_randn(0.0 :: float, 0.5 :: float, array[v_len_x2_w1, v_len_w2_y2]))
    ;
  end if;

raise notice 'step 00, v_cur_loss_delta: %;', v_cur_loss_delta ~=` 4;

  while 
    (
      v_cur_loss_delta is null
      or v_grad_l1 >= i_loss_delta_least_stop_threshold
    )
    and v_cur_no <= i_limit_train_times
  loop

raise notice 'step 0, loop: %;', v_cur_no;
    -- -- v_cur_loss_delta_last = v_cur_loss_delta;

raise notice 'step 1 begin: v_x_rand_samp: %', v_x_rand_samp :: decimal[] ~=` 4;
raise notice 'step 1 begin: v_y_rand_samp: %', v_y_rand_samp :: decimal[] ~=` 4;

    -- 小批量随机梯度下降
    -- -- 小批量取样，降低复杂度和计算量
    select 
      array_agg(array(select unnest(v_i_indepdt_01[a_y_no : a_y_no][:]))),
      array_agg(array(select unnest(v_i_depdt_01[a_y_no : a_y_no][:])))
    into 
      v_x_rand_samp, 
      v_y_rand_samp 
    from (select a_y_no from generate_series(1, v_len_x1_y1) tb_a(a_y_no) order by random() limit v_len_x1_y1_samp) tb_a_ex
    ;

raise notice 'step 1 end: v_x_rand_samp: %', v_x_rand_samp :: decimal[] ~=` 4;
raise notice 'step 1 end: v_y_rand_samp: %', v_y_rand_samp :: decimal[] ~=` 4;
raise notice 'step 2 begin: v_cur_loss_delta: %', v_cur_loss_delta :: decimal[] ~=` 4;

    -- -- 计算梯度
    v_cur_loss_delta := 
    (
      with 
      cte_cur_loss_delta_x1_y1 as
      (
        select 
          a_cur_w2_y2,
          array_agg
          (
            array(select unnest
            (
              sm_sc.fv_aggr_slice_sum
              (
                v_x_rand_samp[a_cur_x1_y1 : a_cur_x1_y1][:] 
                |**| v_ret_w[:][a_cur_w2_y2 : a_cur_w2_y2]
              , array[1, 1]
              )
              -` v_y_rand_samp[a_cur_x1_y1 : a_cur_x1_y1][a_cur_w2_y2 : a_cur_w2_y2]
            ))
            order by a_cur_x1_y1
          ) 
          *` v_x_rand_samp
            as a_cur_loss_delta_x1_y1
        from generate_series(1, v_len_x1_y1_samp) tb_a_x1_y1(a_cur_x1_y1)
          , generate_series(1, v_len_w2_y2) tb_a_w2_y2(a_cur_w2_y2)
        group by a_cur_w2_y2
      ),
      cte_cur_cost_w2_y2 as
      (
        select 
          a_cur_w2_y2,
          array_agg
          (
            array
            [
              sm_sc.fv_aggr_slice_sum(a_cur_loss_delta_x1_y1[1 : v_len_x1_y1_samp][a_cur_x2_w1 : a_cur_x2_w1]) 
            ]
            order by a_cur_x2_w1
          ) as a_cur_loss_delta_w2_y2
        from cte_cur_loss_delta_x1_y1
          , generate_series(1, v_len_x2_w1) tb_a_x2_w1(a_cur_x2_w1)
        group by a_cur_w2_y2
      )
      select sm_sc.fa_mx_concat_x(a_cur_loss_delta_w2_y2 order by a_cur_w2_y2) / v_len_x1_y1_samp :: float from cte_cur_cost_w2_y2
    );

raise notice 'step 2 end: v_cur_loss_delta: %', v_cur_loss_delta :: decimal[] ~=` 4;
raise notice 'step 3 begin: v_ret_w: %', v_ret_w :: decimal[] ~=` 4;

    v_grad_l1 = sm_sc.fv_aggr_slice_sum(@|`  v_cur_loss_delta);

    -- -- -- -- 梯度加入惯性（混入历史梯度成分），协助摆脱局部最优
    -- -- -- 下面已经实现了Adam，本质是带动量的RMSProp
    -- -- v_cur_loss_delta := coalesce((v_cur_loss_delta +` (0.618 *` v_cur_loss_delta_last)) /` 1.618, v_cur_loss_delta);  -- 裴波那契等比衰减系数

    -- -- 梯度下降优化 https://blog.csdn.net/jiaoyangwm/article/details/81457623
    -- -- 自适应学习率
    -- 一阶矩等比衰减系数 0.9
    v_cur_loss_delta_l1_sum = (v_beta_l1 *` coalesce(v_cur_loss_delta_l1_sum, v_cur_loss_delta)) +` ((1.0 :: float - v_beta_l1) *` v_cur_loss_delta);
    -- 二阶矩等比衰减系数 0.999
    v_cur_loss_delta_l2_sum = (v_beta_l2 *` coalesce(v_cur_loss_delta_l2_sum, (v_cur_loss_delta ^` 2.0 :: float))) +` ((1.0 :: float - v_beta_l2) *` (v_cur_loss_delta ^` 2.0 :: float));

    -- -- -- 梯度下降一次，迭代一次 v_ret_w   -- 原始的梯度下降算法
    -- v_ret_w := v_ret_w -` (i_learn_rate *` v_cur_loss_delta);
    -- -- -- 梯度下降一次，迭代一次 v_ret_w   -- adam 梯度下降算法，以及一阶矩、二阶矩无偏估计
    v_ret_w := 
      v_ret_w -` 
      (
        (
          v_cur_loss_delta_l1_sum *` 
          (i_learn_rate / (1.0 :: float - (v_beta_l1 ^ v_cur_no)))
        ) /` 
        (
          sm_sc.fv_ele_replace
          (
            (
              v_cur_loss_delta_l2_sum /` (1.0 :: float - (v_beta_l2 ^ v_cur_no))
            ) ^` (0.5 :: float)
            , array[0.0 :: float]
            , 0.00000001 :: float       -- -- -- 全局 eps = 0.00000001
          )
        )
      );


raise notice 'step 3 end: v_ret_w: %', v_ret_w :: decimal[] ~=` 4;
    -- 寄存至 sm_sc.tb_classify_task
    insert into sm_sc.tb_classify_task
    (
      work_no, 
      learn_cnt , 
      loss_delta,
      ret_w
    )
    select 
      i_work_no, 
      v_cur_no, 
      v_grad_l1, 
      v_ret_w
    on conflict(work_no) do 
    update set
      learn_cnt = v_cur_no,
      loss_delta = v_grad_l1,
      ret_w = v_ret_w
    ;

    -- 循环游标 + 1
    v_cur_no := v_cur_no + 1;
  end loop;

  if v_grad_l1 >= i_learn_rate / (0.00001 :: float)    -- v_grad_l1 >= i_loss_delta_least_stop_threshold
  then
    raise notice 'uncompleted!';
  end if;
end
$$
language plpgsql;

-- -- create extension pg_variables;

-- select pgv_set('vars', 'this_work_no_02', nextval('seq_learn_work')::bigint);
-- -- truncate table sm_sc.tb_classify_task
-- insert into sm_sc.tb_classify_task(work_no, learn_cnt) 
-- select 
--   pgv_get('vars', 'this_work_no_02', NULL::bigint), 
--   0;

-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   work_no           ,
--   ord_no            ,
--   i_depdt_01               ,
--   i_indepdt_01    
-- )
-- select 
--   pgv_get('vars', 'this_work_no_02', NULL::bigint), 
--   a_idx,
--   sm_sc.fv_mx_ele_2d_2_1d
--   ((|^~| array[array[2.0, 4.0, 6.0]])[a_idx : a_idx][ : ]),
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       array
--       [ 
--         [1.0, 1.0]               ,
--         [1.0, 2.0]            ,
--         [1.0, 3.0]
--       ]
--     )[a_idx : a_idx][ : ]
--   )
-- from generate_series(1, 3) tb_a(a_idx);

-- call sm_sc.prc_linear_regression
-- (
--   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
--   0.05      ,
--   2500       -- ,
--   -- 20      ,
--   -- 0.01
-- );
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- -- 期望输出： |^~| array[array[0.0, 2.0]]

-- -----------------------------------------
-- select pgv_set('vars', 'this_work_no_03', nextval('seq_learn_work')::bigint);
-- -- truncate table sm_sc.tb_classify_task
-- insert into sm_sc.tb_classify_task(work_no, learn_cnt) 
-- select 
--   pgv_get('vars', 'this_work_no_03', NULL::bigint), 
--   2500;

-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   work_no             ,
--   ord_no              ,
--   i_depdt_01                 ,
--   i_indepdt_01    
-- )
-- select 
--   pgv_get('vars', 'this_work_no_03', NULL::bigint),
--   a_idx, 
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (|^~| (
--             array[[2.0 + 1.0, 4.0 + 1.0, 6.0 + 1.0, 8.0 + 1.0, 10.0 + 1.0, 12.0 + 1.0]
--                  ,[3.0 - 1.0, 6.0 - 1.0, 9.0 - 1.0, 12.0 - 1.0, 15.0 - 1.0, 18.0 - 1.0]] 
--             +` fv_new_randn(0, 0.01, array[2, 6])
--           )
--     )[a_idx : a_idx][ : ]
--   ), 
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       array
--       [ 
--         [1.0, 1.0]               ,
--         [1.0, 2.0]            ,
--         [1.0, 3.0]            ,
--         [1.0, 4.0]            ,
--         [1.0, 5.0]            ,
--         [1.0, 6.0]
--       ] +` fv_new_randn(0, 0.01, array[6, 1])
--     )[a_idx : a_idx][ : ]
--   )
-- from generate_series(1, 6) tb_a(a_idx);

-- call sm_sc.prc_linear_regression
-- (
--   pgv_get('vars', 'this_work_no_03', NULL::bigint)   ,
--   0.05      ,
--   2500       -- ,
--   -- 20      ,
--   -- 0.01
-- );
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_03', NULL::bigint)
-- -- 期望输出： |^~| array[array[1.0, 2.0], array[-1.0, 3.0]]

-- -----------------------------------------
-- select pgv_set('vars', 'this_work_no_01', nextval('seq_learn_work')::bigint);
-- insert into sm_sc.tb_classify_task(work_no, learn_cnt) 
-- select 
--   pgv_get('vars', 'this_work_no_01', NULL::bigint), 
--   2500;

-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   work_no          ,
--   ord_no           ,
--   i_depdt_01              ,
--   i_indepdt_01    
-- )
-- select 
--   pgv_get('vars', 'this_work_no_01', NULL::bigint), 
--   a_idx, 
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       array
--       [
--         array[22.1000 ,    12.2000     ],
--         array[-10.0000,     -7.6000 ],  
--         array[46.7000 ,    27.8000     ],
--         array[35.4000 ,    19.8000     ],
--         array[32.5000 ,    19.0000     ]
--       ]
--     )[a_idx : a_idx][ : ] 
--   ),
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       array
--       [ 
--         array[1.0, 1.1, 2.1, 0.1],
--         array[1.0, 1.2, 1.2, -3.2],
--         array[1.0, 0.7, 2.3, 3.3],
--         array[1.0, 1.4, 3.4, 0.4],
--         array[1.0, 0.5, 2.5, 1.5]
--       ]
--     )[a_idx : a_idx][ : ]
--   )
-- from generate_series(1, 5) tb_a(a_idx);

-- call sm_sc.prc_linear_regression
-- (
--   pgv_get('vars', 'this_work_no_01', NULL::bigint)   ,
--   0.05      ,
--   2500       -- ,
--   -- 20      ,
--   -- 0.01
-- );
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_01', NULL::bigint)
-- -- 期望输出： 
-- --   array
-- --   [
-- --     array[0.0, 0.0],
-- --     array[6.0, 3.0],
-- --     array[7.0, 4.0],
-- --     array[8.0, 5.0]
-- --   ]

-- -----------------------------------------
-- -- 以下用例量级相差悬殊，未做标准化，梯度溢出
-- select pgv_set('vars', 'this_work_no_01', nextval('seq_learn_work')::bigint);
-- insert into sm_sc.tb_classify_task(work_no, learn_cnt) 
-- select 
--   pgv_get('vars', 'this_work_no_01', NULL::bigint), 
--   2500;

-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   work_no             ,
--   ord_no              ,
--   i_depdt_01                 ,
--   i_indepdt_01    
-- )
-- select 
--   pgv_get('vars', 'this_work_no_01', NULL::bigint), 
--   a_idx, 
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       |^~| array[array[3222.83, 32203.73, 322012.73, 3220102.73, 32201002.73]]
--     )[a_idx : a_idx][ : ] 
--   ),
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     array
--     [ 
--       [1.1, 20.1, 300.1]               ,
--       [10.1, 200.1, 3000.1]            ,
--       [100.1, 2000.1, 30000.1]         ,
--       [1000.1, 20000.1, 300000.1]      ,
--       [10000.1, 200000.1, 3000000.1]
--     ]
--   )[a_idx : a_idx][ : ]
-- from generate_series(1, 5) tb_a(a_idx);

-- call sm_sc.prc_linear_regression
-- (
--   pgv_get('vars', 'this_work_no_01', NULL::bigint)   ,
--   0.05      ,
--   2500       -- ,
--   -- 20      ,
--   -- 0.01
-- );
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_01', NULL::bigint)
-- -- 期望输出： |^~| array[array[8.1], array[9.1], array[10.1]]

