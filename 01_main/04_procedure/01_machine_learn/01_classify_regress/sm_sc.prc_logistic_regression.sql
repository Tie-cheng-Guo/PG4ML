-- 参考 https://blog.csdn.net/zhq9695/article/details/82814197
--      https://blog.csdn.net/weixin_39797176/article/details/99488766   该文中有误，似然函数和梯度取负，才收敛

-- 初始学习率：1e-4
-- https://www.zhihu.com/question/387050717

drop procedure if exists sm_sc.prc_logistic_regression;
create or replace procedure sm_sc.prc_logistic_regression
(
  i_work_no                          bigint                                   ,                                                                                                -- 训练任务编号，用于任务暂停和接续、数据回显
  -- i_x                                float[][]                       ,      -- [v_len_x1_y1][v_len_x2_w1]                                                         -- 对象的已知参数矩阵
  -- i_y                                float[][]                       ,      -- [v_len_x1_y1][v_len_w2_y2]                                                         -- 分类结果，要求类似onehot编码形式，0.0 <=` v_i_y <=` 1.0
  i_learn_rate                       float    default    0.0001        ,                                                                                                -- 学习率
  i_limit_train_times                int               default    10000       ,                                                                                                -- 最大训练次数，然后未完成中止
  -- i_grad_descent_batch_cnt           int               default    10000       ,   -- 建议大一些，远远超过 v_i_x, v_i_y 的各维度长度，尽量防止因小批量梯度下降引起的鞍点训练终止 -- 小批量梯度下降，每批记录数
  i_loss_delta_least_stop_threshold  float    default    0.0001                                                                                                       -- 触发收敛的损失函数梯度阈值
)
as
$$
declare -- here
-- -- 数学原理：已知矩阵 v_i_x, v_i_y, 且 sigmoid(v_i_x |**| v_ret_w) == (v_i_y), 求 v_ret_w
  v_i_x                       float[][]:= (select array_agg(i_x order by ord_no) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
  v_i_y                       float[][]:= (select array_agg(i_y order by ord_no) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
  v_len_x1_y1                 int               := array_length(v_i_x, 1); 
  v_len_x2_w1                 int               := array_length(v_i_x, 2) + 1;
  v_x                         float[][]:= sm_sc.fv_new(1.0, array[v_len_x1_y1, 1]) |||| v_i_x;
  v_len_x1_y1_samp            int               := least(greatest(floor(v_len_x1_y1 / 10), 10000), v_len_x1_y1, 10000);       -- least(i_grad_descent_batch_cnt, v_len_x1_y1); -- 小批量梯度下降，每批记录数
  v_len_w2_y2                 int               := array_length(v_i_y, 2);
  v_ret_w                     float[];           -- [v_len_x2_w1][v_len_w2_y2]   
  v_x_rand_samp               float[];           -- [v_len_x1_y1_samp][v_len_x2_w1];
  v_i_y_rand_samp             float[];           -- [v_len_x1_y1][v_len_w2_y2]
  v_cur_loss_delta            float[];           -- [v_len_x2_w1][v_len_w2_y2]
  -- -- v_cur_loss_delta_last       float[];           -- [v_len_x2_w1][v_len_w2_y2]
  v_cur_no                    int               := 1;
  v_cur_loss_delta_l1_sum     float[];            -- [v_len_x2_w1][v_len_w2_y2]
  v_cur_loss_delta_l2_sum     float[];            -- [v_len_x2_w1][v_len_w2_y2] 
  v_beta_l1                   float    := 0.9;
  v_beta_l2                   float    := 0.999;
  v_grad_l1                   float;             -- 寄存梯度本次变化的一阶矩，优化重复计算


begin
  set search_path to public;
  -- 审计 array_length(v_i_y, 1) == v_len_x1_y1
  if array_length(v_i_y, 1) <> v_len_x1_y1
  then
    raise exception 'error length of v_i_y';
  end if;

  -- 新建任务或者提取既有任务寄存信息
  if exists (select  from sm_sc.tb_classify_task where work_no = i_work_no)
  then
    select 
      -- work_no,
      coalesce(learn_cnt + 1, v_cur_no),
      -- loss_delta,
      coalesce(ret_w, sm_sc.fv_new_randn(0.0, 0.5, array[v_len_x2_w1, v_len_w2_y2]))
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
      coalesce(ret_w, sm_sc.fv_new_randn(0.0, 0.5, array[v_len_x2_w1, v_len_w2_y2]))
    ;
  end if;

raise notice 'step 00, @` v_cur_loss_delta: %;', @` v_cur_loss_delta ~=` 4;

  while 
    (
      v_cur_loss_delta is null
      or v_grad_l1 >= i_loss_delta_least_stop_threshold
    )
    and v_cur_no <= i_limit_train_times
  loop

raise notice 'step 0, loop: %;', v_cur_no;
    -- -- v_cur_loss_delta_last = v_cur_loss_delta;

raise notice 'step 1 begin: v_x_rand_samp: %', v_x_rand_samp ~=` 4;
raise notice 'step 1 begin: v_i_y_rand_samp: %', v_i_y_rand_samp ~=` 4;

    -- 小批量随机梯度下降
    -- -- 小批量取样，降低复杂度和计算量
    select 
      array_agg(array(select unnest(v_x[a_y_no : a_y_no][:]))),
      array_agg(array(select unnest(v_i_y[a_y_no : a_y_no][:])))
    into 
      v_x_rand_samp, 
      v_i_y_rand_samp 
    from (select a_y_no from generate_series(1, v_len_x1_y1) tb_a(a_y_no) order by random() limit v_len_x1_y1_samp) tb_a_ex
    ;

raise notice 'step 1 end: v_x_rand_samp: %', v_x_rand_samp ~=` 4;
raise notice 'step 1 end: v_i_y_rand_samp: %', v_i_y_rand_samp ~=` 4;
raise notice 'step 2 begin: v_cur_loss_delta: %', v_cur_loss_delta ~=` 4;

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
              sm_sc.fv_activate_sigmoid
              (
                sm_sc.fv_aggr_y_sum
                (
                  v_x_rand_samp[a_cur_x1_y1 : a_cur_x1_y1][:] 
                  |**| v_ret_w[:][a_cur_w2_y2 : a_cur_w2_y2]
                )
              )
              -` v_i_y_rand_samp[a_cur_x1_y1 : a_cur_x1_y1][a_cur_w2_y2 : a_cur_w2_y2]
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
      select sm_sc.fa_mx_concat_x(a_cur_loss_delta_w2_y2 order by a_cur_w2_y2) /` v_len_x1_y1_samp :: float from cte_cur_cost_w2_y2
    );

raise notice 'step 2 end: v_cur_loss_delta: %', v_cur_loss_delta ~=` 4;
raise notice 'step 3 begin: v_ret_w: %', v_ret_w ~=` 4;

    v_grad_l1 = sm_sc.fv_aggr_slice_sum(@` v_cur_loss_delta);

    -- -- -- -- 梯度加入惯性（混入历史梯度成分），协助摆脱局部最优
    -- -- -- 下面已经实现了Adam，本质是带动量的RMSProp
    -- -- v_cur_loss_delta := coalesce((v_cur_loss_delta +` (0.618 *` v_cur_loss_delta_last)) /` 1.618, v_cur_loss_delta);  -- 裴波那契等比衰减系数

    -- -- 梯度下降优化 https://blog.csdn.net/jiaoyangwm/article/details/81457623
    -- -- 自适应学习率 Adam
    -- 一阶矩等比衰减系数 0.9
    v_cur_loss_delta_l1_sum = (v_beta_l1 *` coalesce(v_cur_loss_delta_l1_sum, v_cur_loss_delta)) +` ((1.0 - v_beta_l1) *` v_cur_loss_delta);
    -- 二阶矩等比衰减系数 0.999
    v_cur_loss_delta_l2_sum = (v_beta_l2 *` coalesce(v_cur_loss_delta_l2_sum, (v_cur_loss_delta ^` 2.0))) +` ((1.0 - v_beta_l2) *` (v_cur_loss_delta ^` 2.0));

    -- -- -- 梯度下降一次，迭代一次 v_ret_w   -- 原始的梯度下降算法
    -- v_ret_w := v_ret_w -` (i_learn_rate *` v_cur_loss_delta);
    -- -- -- 梯度下降一次，迭代一次 v_ret_w   -- adam 梯度下降算法，以及一阶矩、二阶矩无偏估计
    v_ret_w := 
      v_ret_w -` 
      (
        (
          v_cur_loss_delta_l1_sum *` 
          (i_learn_rate / (1.0 - (v_beta_l1 ^ v_cur_no)))
        ) /` 
        (
          sm_sc.fv_ele_replace
          (
            (
              v_cur_loss_delta_l2_sum /` (1.0 - (v_beta_l2 ^ v_cur_no))
            ) ^` 0.5
            , array[0.0]
            , 0.00000001        -- -- -- 全局 eps = 0.00000001
          )
        )
      );


raise notice 'step 3 end: v_ret_w: %', v_ret_w ~=` 4;
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

  if v_grad_l1 >= i_learn_rate / 0.00001    -- v_grad_l1 >= i_loss_delta_least_stop_threshold
  then
    raise notice 'uncompleted!';
  end if;
end
$$
language plpgsql;

-- -- create extension pg_variables;

-- -- 二分类
-- select pgv_set('vars', 'this_work_no_02', nextval('seq_learn_work')::bigint);
-- -- truncate table sm_sc.tb_classify_task
-- insert into sm_sc.tb_classify_task(work_no, learn_cnt) 
-- select 
--   pgv_get('vars', 'this_work_no_02', NULL::bigint), 
--   0;
-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   work_no     ,
--   ord_no      ,
--   i_y         ,
--   i_x    
-- )
-- select 
--   pgv_get('vars', 'this_work_no_02', NULL::bigint),
--   a_idx, 
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (sm_sc.fn_onehot(|^~| array[array['a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b']]))[a_idx : a_idx][ : ]
--   ),
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       array
--       [ 
--        [2.0, 0.0]            ,
--        [2.5, 0.5]            ,
--        [3.0, 1.0]            ,
--        [3.5, 1.5]            ,
--        [4.0, 2.0]            ,
--        [0.0, 2.0]            ,
--        [0.5, 2.5]            ,
--        [1.0, 3.0]            ,
--        [1.5, 3.5]            ,
--        [2.0, 4.0]            
--       ]
--     )[a_idx : a_idx][ : ]
--   )
-- from generate_series(1, 10) tb_a(a_idx);

-- call sm_sc.prc_logistic_regression
-- (
--   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
--   0.5      ,
--   1200       -- ,
--   -- 20      ,
--   -- 0.01
-- );
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- -- 期望输出： array[[-0.9243,-0.9243],[4.2689,-3.7785],[-3.7785,4.2689]]
-- -- 验证：select sm_sc.fv_activate_sigmoid(array[array[1.0, 3.1, 0.9]] |**| array[[-0.9243,-0.9243],[4.2689,-3.7785],[-3.7785,4.2689]])
-- --       其中 3.1, 0.9 为新对象属性入参，出参分别为类别 'a', 'b' 的概率

-- -----------------------------------------
-- -- 多分类
-- select pgv_set('vars', 'this_work_no_02', nextval('seq_learn_work')::bigint);
-- -- truncate table sm_sc.tb_classify_task
-- insert into sm_sc.tb_classify_task(work_no, learn_cnt) 
-- select 
--   pgv_get('vars', 'this_work_no_02', NULL::bigint), 
--   0;

-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   work_no    ,
--   ord_no     ,
--   i_y        ,
--   i_x    
-- )
-- select 
--   pgv_get('vars', 'this_work_no_02', NULL::bigint),
--   a_idx, 
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (sm_sc.fv_onehot(|^~| array[array['a', 'a', 'a', 'c', 'c', 'c', 'b', 'b', 'b', 'd', 'd', 'd']]))[a_idx : a_idx][ : ]
--   ),
--   sm_sc.fv_mx_ele_2d_2_1d
--   (
--     (
--       array
--       [ 
--         [1.0, 1.0]            ,
--         [1.0, 1.0]            ,
--         [1.0, 1.0]            ,
--         [-1.0, 1.0]            ,
--         [-1.0, 1.0]            ,
--         [-1.0, 1.0]            ,
--         [1.0, -1.0]            ,
--         [1.0, -1.0]            ,
--         [1.0, -1.0]            ,
--         [-1.0, -1.0]            ,
--         [-1.0, -1.0]            ,
--         [-1.0, -1.0]            
--       ] +` sm_sc.fv_new_randn(0.0, 0.1, array[12, 2])
--     )[a_idx : a_idx][ : ]
--   )
-- from generate_series(1, 12) tb_a(a_idx);

-- call sm_sc.prc_logistic_regression
-- (
--   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
--   0.05      ,
--   1500       -- ,
--   -- 20      ,
--   -- 0.01
-- );
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- -- 期望输出： array[[-8.1805,-6.7478,-7.8229,-6.4841],[8.3520,7.6351,-8.0533,-6.5274],[7.3270,-7.2030,7.7274,-6.0817]] 的正负一致
-- -- 验证：select sm_sc.fv_activate_sigmoid(array[array[1.0, 0.9, -1.1]] |**| array[[-8.1805,-6.7478,-7.8229,-6.4841],[8.3520,7.6351,-8.0533,-6.5274],[7.3270,-7.2030,7.7274,-6.0817]])
-- --       其中 0.9, -1.1 为新对象属性入参，出参分别为类别 'a', 'b', 'c', 'd' 的概率，本例 'b' (y[2]) 概率较大
