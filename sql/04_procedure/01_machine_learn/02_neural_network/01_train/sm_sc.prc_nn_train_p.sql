-- 参看设计文档 《反向传播链式求导步骤编排》

-- 初始学习率：1e-4
-- https://www.zhihu.com/question/387050717

drop procedure if exists sm_sc.prc_nn_train_p(bigint, float, float, boolean, float, float, boolean);
create or replace procedure sm_sc.prc_nn_train_p
(
  i_work_no                          bigint                             -- 训练任务编号
-- , i_loss_fn_type                     varchar(32)[]                      -- 损失函数选取类型。1: 最小二乘法; 2: 交叉熵
, i_learn_rate                       float    default    0.0003         -- 学习率
, i_loss_delta_least_stop_threshold  float    default    0.0001         -- 触发收敛的损失函数梯度阈值
, i_is_adam                          boolean  default    false          -- 是否开启 adam 优化
, i_l1                               float    default    null           -- L1 正则化率，缺省不做 L1 正则化
, i_l2                               float    default    null           -- L2 正则化率，缺省不做 L2 正则化
, i_tensor_log                       boolean  default    false          -- 是否记录当轮次传播的中间张量
)
as
$$
declare -- here
  v_learn_cnt_init          int               := (select learn_cnt from sm_sc.tb_classify_task where work_no = i_work_no limit 1);   -- 训练次数序号初始值
  v_cur_learn_cnt           int               := v_learn_cnt_init;   -- 训练次数序号
  v_depdt_01                float[]  ; -- -- 训练集本轮采样之多模态 01
  v_depdt_02                float[]  ; -- -- 训练集本轮采样之多模态 02
  v_depdt_03                float[]  ; -- -- 训练集本轮采样之多模态 03
  v_depdt_04                float[]  ; -- -- 训练集本轮采样之多模态 04
  v_cur_node_nos            bigint[];  -- for debug
  v_cur_loss                float;     -- 损失函数值
  v_input_nodes             bigint[]          := 
    (
      select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input_01', 'input_02', 'input_03', 'input_04') -- limit 1
    );
  v_cur_nn_depth            int               := 0;   -- 深度层数游标
  v_nn_depth                int;                      -- 深度层数
  v_limit_train_times       int               := (select learn_cnt_fore from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_01' limit 1);
  v_beta_l1                 float    := 0.9;      -- Adam 梯度下降算法一阶矩等比衰减系数
  v_beta_l2                 float    := 0.999;    -- Adam 梯度下降算法二阶矩等比衰减系数
  
  -- 求导时，需要因变量的算子类型集合
  v_arr_fn_depdt_delta      varchar(64)[]   :=   (select array_agg(enum_key) from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta_method' and (substr(enum_value, 5, 1) = '1' or substr(enum_value, 6, 1) = '1'));
  v_loss_fn_type            varchar(32)     := (select loss_fn_type from sm_sc.tb_classify_task where work_no = i_work_no limit 1);   -- 训练次数序号初始值

  v_is_input_02             boolean         := (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_02');
  v_is_input_03             boolean         := (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_03');
  v_is_input_04             boolean         := (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_04');
  
  v_is_output_01            boolean         := 
    (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_01')
    and 
    (exists(select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and i_depdt_01 is not null))
  ;
  v_is_output_02            boolean         := 
    (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_02')
    and 
    (exists(select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and i_depdt_02 is not null))
  ;
  v_is_output_03            boolean         := 
    (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_03')
    and 
    (exists(select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and i_depdt_03 is not null))
  ;
  v_is_output_04            boolean         := 
    (select true from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_04')
    and 
    (exists(select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and i_depdt_04 is not null))
  ;
  v_model_code_6            char(6)         :=
    (select model_code_6 from sm_sc.tb_classify_task where work_no = i_work_no)
  ;
  v_null                    varchar(64)[];
begin
  set search_path to public;
  
  -- -- 强行关闭并行
  -- set max_parallel_workers = 0;
  
  -- -- -- -- 强制开启并行
  -- -- -- -- select * from pg_settings where name ~ 'paral' or name in ('max_worker_processes') limit 100
  -- -- -- -- show max_worker_processes
  -- set min_parallel_table_scan_size = 0;
  -- set min_parallel_index_scan_size = 0;
  -- set force_parallel_mode = 'off';
  -- set max_parallel_workers_per_gather = 64;
  -- set parallel_setup_cost = 0;
  -- set parallel_tuple_cost = 0.0;

  -- 清理旧有训练结果
  delete from sm_sc.__vt_nn_node
  where work_no = i_work_no
  ;
  commit;
  
  -- -- -- -- 每次训练前，调整抽样数量等策略
  -- -- -- call sm_sc.prc_nn_prepare_per_train(v_cur_learn_cnt, v_cur_loss, ...);

  -- 审计 训练是否已经满足损失函数最低阈值
  if exists (select  from sm_sc.tb_classify_task where work_no = i_work_no and loss_delta <= i_loss_delta_least_stop_threshold)
  then
    raise notice 'The loss_delta is adequately less than i_loss_delta_least_stop_threshold already!';
    return;
  end if;

  v_nn_depth := (select max(nn_depth_no) from sm_sc.tb_nn_node where work_no = i_work_no);

  raise notice 'Training begin; at %', date_trunc('milliseconds', now());

  -- 开始训练
  while 
  (
    i_loss_delta_least_stop_threshold <= v_cur_loss
    or v_cur_loss is null
  )
    and v_cur_learn_cnt < v_limit_train_times
  loop

-- -- -- debug
-- raise notice 'debug 001. step begin: v_cur_learn_cnt: %; at %;', v_cur_learn_cnt, date_trunc('milliseconds', now());

    -- 触发 dropout 机制，根据 dropout 概率，确定 dropout 节点清单
    update sm_sc.tb_nn_node
    set is_dropout = (dropout_ratio > random())
    where work_no = i_work_no
      and dropout_ratio > 0.0
    ;
    commit;
    
    -- 填充 dropout 节点的因变量
    update sm_sc.tb_nn_node
    set 
      p_node_depdt = 
        sm_sc.__fv_set_kv
        (
          array_fill(dropout_depdt_val, node_depdt_len)
        , v_model_code_6 || 
          '_' || work_no :: varchar ||
          '_' || node_no :: varchar ||
          '__d__'  -- 'depdt'
        )
    where work_no = i_work_no
      and is_dropout
    ;

    if exists
       (
         select  from sm_sc.tb_nn_node 
         where work_no = i_work_no 
           and node_fn_type = '00_buff_slice_rand_pick' 
           and node_type = 'input_01'
           limit 1
       )
    then
      -- 如果对训练集采用小批量随机采样，那么每轮初始化 input 值，以支持不同轮次更换训练集
      with
      cte_slice_rand_pick_agg as 
      (
        -- 要确保各模态的小批量随机采样序号集合一致。
        -- 规约：以 input_01 模态的 00_buff_slice_rand_pick 算子超参数配置为基准。而忽略其他模态的配置。
        select  
          array_agg
          (
            int4multirange
            (
              int4range
              (
                o_ord_no :: int
              , o_ord_no :: int + 1
              , '[)'
              )
            )
          )                                                                as a_pick_depdt_idx
        , array_agg(tb_a_idx.o_rand_pick_indepdt_01 order by o_ord_no)     as a_rand_pick_indepdt_01
        , case when v_is_input_02 then array_agg(coalesce(tb_a_idx.o_rand_pick_indepdt_02, array[null :: float]) order by o_ord_no) end     as a_rand_pick_indepdt_02
        , case when v_is_input_03 then array_agg(coalesce(tb_a_idx.o_rand_pick_indepdt_03, array[null :: float]) order by o_ord_no) end     as a_rand_pick_indepdt_03
        , case when v_is_input_04 then array_agg(coalesce(tb_a_idx.o_rand_pick_indepdt_04, array[null :: float]) order by o_ord_no) end     as a_rand_pick_indepdt_04
        from sm_sc.tb_nn_node tb_a_node,
          sm_sc.ft_nn_buff_slice_rand_pick
          (
            -- 参看 00_buff_slice_rand_pick 的 node_fn_asso_value 字典表
            i_work_no,
            (
              select 
                array_agg(int4range(tb_a_node.node_fn_asso_value[1][a_ord] :: int, tb_a_node.node_fn_asso_value[2][a_ord] :: int + 1, '[)') order by a_ord)
              from generate_series(1, array_length(tb_a_node.node_fn_asso_value, 2)) tb_a(a_ord)
            )
          , sm_sc.fv_mx_ele_2d_2_1d(tb_a_node.node_fn_asso_value[3 : 3][ : ]) :: int[]
          ) tb_a_idx(o_ord_no, o_rand_pick_indepdt_01, o_rand_pick_indepdt_02, o_rand_pick_indepdt_03, o_rand_pick_indepdt_04)
        where tb_a_node.work_no = i_work_no
          and tb_a_node.node_type = 'input_01'
          and tb_a_node.node_fn_type = '00_buff_slice_rand_pick'
      )
      update sm_sc.tb_nn_node tb_a_tar
      set 
        p_node_depdt = 
          sm_sc.__fv_set_kv
          (
            case 
              when tb_a_tar.node_type = 'input_01'
                then a_rand_pick_indepdt_01
              when tb_a_tar.node_type = 'input_02'
                then a_rand_pick_indepdt_02
              when tb_a_tar.node_type = 'input_03'
                then a_rand_pick_indepdt_03
              when tb_a_tar.node_type = 'input_04'
                then a_rand_pick_indepdt_04
            end
          , v_model_code_6 || 
            '_' || tb_a_tar.work_no :: varchar ||
            '_' || tb_a_tar.node_no :: varchar ||
            '__d' ||  -- 'depdt'
            '_' || ltrim(substr(tb_a_tar.node_type, 7), '0') ||
            '_'
          )
      , pick_depdt_idx = a_pick_depdt_idx
      from cte_slice_rand_pick_agg tb_a_sour
      where tb_a_tar.work_no = i_work_no   -- 2021082501
        and tb_a_tar.node_fn_type = '00_buff_slice_rand_pick' 
        and tb_a_tar.node_type in ('input_01', 'input_02', 'input_03', 'input_04')
      ;
      commit;
    elsif exists(select  from sm_sc.tb_nn_node where work_no = i_work_no and node_fn_type = '00_full_dataset' and node_type = 'input_01')
    then 
      -- 如果不做小批量随机采样，那么使用训练集全集
      with
      cte_slice_rand_pick as 
      (
        select 
          array_agg(i_indepdt_01)        as a_x_vals_01,
          array_agg(i_indepdt_02)        as a_x_vals_02,
          array_agg(i_indepdt_03)        as a_x_vals_03,
          array_agg(i_indepdt_04)        as a_x_vals_04,
          count(*) :: int       as a_x_cnt
        from sm_sc.tb_nn_train_input_buff
        where work_no = i_work_no
      )
      update sm_sc.tb_nn_node tb_a_tar
      set 
        p_node_depdt = 
          sm_sc.__fv_set_kv
          (
            case tb_a_tar.node_type 
              when 'input_01' 
                then a_x_vals_01 
              when 'input_02' 
                then a_x_vals_02 
              when 'input_03' 
                then a_x_vals_03 
              when 'input_04' 
                then a_x_vals_04 
            end  
          , v_model_code_6 || 
            '_' || tb_a_tar.work_no :: varchar ||
            '_' || tb_a_tar.node_no :: varchar ||
            '__d__'  -- 'depdt'
          )
      , pick_depdt_idx = array[int4multirange(int4range(1, a_x_cnt + 1, '[)'))]
      from cte_slice_rand_pick tb_a_sour
      where tb_a_tar.work_no = i_work_no   -- 2021082501
        and tb_a_tar.node_type in ('input_01', 'input_02', 'input_03', 'input_04')
      ;
      commit;
    end if;

    v_cur_nn_depth := 0;

    -- 前向传播

-- -- for debug
-- v_cur_node_nos := 
--   (
--     select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input_01', 'input_02', 'input_03', 'input_04') -- limit 1
--   );
      
    while v_cur_nn_depth < v_nn_depth
    loop
      v_cur_nn_depth := v_cur_nn_depth + 1;

-- -- -- debug
-- raise notice 'debug 002. step fore begin: v_cur_learn_cnt: %; v_cur_nn_depth: %; v_learn_cnt_init: %; at %;', v_cur_learn_cnt, v_cur_nn_depth, v_learn_cnt_init, date_trunc('milliseconds', now());

      -- 按照 nn_depth_no，逐层前向传播。初始节点只前向传播一次
      with 
      -- 参数准备，单目、双目（三目）算子
      cte_indepdt as
      (
        select 
          tb_a_fore.node_no
        , tb_a_fore.node_fn_type
        , sm_sc.fa_range_or(tb_a_back.pick_depdt_idx) as a_pick_depdt_idx
        , sm_sc.fa_coalesce(case when tb_a_path.path_ord_no = 1 then tb_a_back.p_node_depdt end) as a_bi_opr_input_1st_p
        , sm_sc.fa_coalesce(case when tb_a_path.path_ord_no = 2 then tb_a_back.p_node_depdt end) as a_bi_opr_input_2nd_p
        , sm_sc.fa_coalesce(case when tb_a_path.path_ord_no = 3 then tb_a_back.p_node_depdt end) as a_bi_opr_input_3rd_p
        , sm_sc.fa_mx_concat_y(case when tb_a_path.path_ord_no = 1 then tb_a_back.node_depdt_len end) as a_bi_opr_input_len_1st
        , sm_sc.fa_mx_concat_y(case when tb_a_path.path_ord_no = 2 then tb_a_back.node_depdt_len end) as a_bi_opr_input_len_2nd
     -- , sm_sc.fa_mx_concat_y(case when tb_a_path.path_ord_no = 3 then tb_a_back.node_depdt_len end) as a_bi_opr_input_len_3rd
        , (sm_sc.fa_mx_or(case when tb_a_path.path_ord_no = 1 then array[tb_a_back.is_back_node] else array[false] end))[1] as a_is_bi_opr_input_1st_back
        , (sm_sc.fa_mx_or(case when tb_a_path.path_ord_no = 2 then array[tb_a_back.is_back_node] else array[false] end))[1] as a_is_bi_opr_input_2nd_back
     -- , (sm_sc.fa_mx_or(case when tb_a_path.path_ord_no = 3 then array[tb_a_back.is_back_node] else array[false] end))[1] as a_is_bi_opr_input_3rd_back
        from sm_sc.tb_nn_node tb_a_fore
        inner join sm_sc.tb_nn_path tb_a_path
          on tb_a_path.work_no = i_work_no   -- 2021082501
            and tb_a_path.fore_node_no = tb_a_fore.node_no
        inner join sm_sc.tb_nn_node tb_a_back
          on tb_a_back.work_no = i_work_no   -- 2021082501
            and tb_a_back.node_no = tb_a_path.back_node_no
        -- 先处理单目、双目（三目）算子，聚合函数算子另行处理
        inner join sm_sc.tb_dic_enum tb_a_dic
          on tb_a_dic.enum_name = 'node_fn_type'
            and tb_a_dic.enum_key = tb_a_fore.node_fn_type
            and tb_a_dic.enum_group in ('1_p', '2_p', '3_p')
        where tb_a_fore.work_no = i_work_no   -- 2021082501
          and tb_a_fore.nn_depth_no = v_cur_nn_depth
          and (tb_a_fore.is_fore_node or v_cur_learn_cnt = v_learn_cnt_init)
          and tb_a_fore.is_dropout is not true
        group by tb_a_fore.node_no, tb_a_fore.node_fn_type
      )
      ,
      -- 前向传播
      cte_upd_fore_node_indepdt as 
      (
        update sm_sc.tb_nn_node tb_a_tar_depdt
        set 
          pick_depdt_idx =
            sm_sc.fv_nn_node_pick_depdt_idx
            (
              tb_a_indepdt_fore.node_fn_type
            , tb_a_indepdt_fore.a_pick_depdt_idx
            , tb_a_tar_depdt.node_fn_asso_value
            )
        , p_node_depdt = 
            sm_sc.__fv_set_kv 
            (
              sm_sc.__fv_get_kv 
              (
                sm_sc.fv_lambda_arr_p
                (
                  v_model_code_6
                , i_work_no
                , tb_a_indepdt_fore.node_no
                , null -- i_sess_id
                , tb_a_tar_depdt.node_fn_type
                , tb_a_indepdt_fore.a_bi_opr_input_1st_p
                , tb_a_indepdt_fore.a_bi_opr_input_2nd_p
                , tb_a_tar_depdt.node_fn_asso_value
                , tb_a_indepdt_fore.a_bi_opr_input_3rd_p
                )  
              )  
              -- dropout 缩放
              *` tb_a_tar_depdt.dropout_rescale
            , v_model_code_6 || 
              '_' || i_work_no :: varchar ||
              '_' || tb_a_indepdt_fore.node_no :: varchar ||
              '__d__'  -- 'depdt'
            )
        , learn_cnt_fore = v_cur_learn_cnt + 1  -- 强制对齐训练次数，避免路径跟踪混乱   -- tb_a_tar_depdt.learn_cnt_fore + 1
        from cte_indepdt tb_a_indepdt_fore
        where tb_a_tar_depdt.work_no = i_work_no   -- 2021082501
          and tb_a_indepdt_fore.node_no = tb_a_tar_depdt.node_no
        returning 
          tb_a_tar_depdt.node_no as a_cur_node_no
          -- 寄存、传递若干算子的因变量，对 p_ddepdt_dindepdt 是必要的。
        , case when tb_a_tar_depdt.node_fn_type = any(v_arr_fn_depdt_delta) then tb_a_tar_depdt.p_node_depdt end as a_p_node_depdt
      )
--       ,
      -- 前向传播同步求导 p_ddepdt_dindepdt

-- -- for debug
-- cte_upd_path as 
-- (

        update sm_sc.tb_nn_path tb_a_tar_path
        set 
          p_ddepdt_dindepdt =
            sm_sc.fv_lambda_arr_ddepdt_dindepdt_p
            (
              v_model_code_6
            , i_work_no
            , tb_a_indepdt_fore.node_no
            , tb_a_tar_path.back_node_no
            , tb_a_depdt.node_fn_type
            , case 
                when tb_a_tar_path.path_ord_no = 1 and substr(tb_a_dic.enum_value, 1, 1) = '1'
                  then tb_a_indepdt_fore.a_bi_opr_input_1st_p 
                when tb_a_tar_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 2, 1) = '1'
                  then tb_a_indepdt_fore.a_bi_opr_input_2nd_p
             -- when tb_a_tar_path.path_ord_no = 3 
             --   then tb_a_indepdt_fore.a_bi_opr_input_3rd_p
              end 
            , tb_a_tar_path.path_ord_no
            , case 
                when tb_a_tar_path.path_ord_no = 1 and substr(tb_a_dic.enum_value, 3, 1) = '1'
                  then tb_a_indepdt_fore.a_bi_opr_input_2nd_p 
                when tb_a_tar_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 4, 1) = '1'
                  then tb_a_indepdt_fore.a_bi_opr_input_1st_p
              end 
            , tb_a_depdt.node_fn_asso_value 
            , case 
                when tb_a_tar_path.path_ord_no = 1 and substr(tb_a_dic.enum_value, 5, 1) = '1'
                  or tb_a_tar_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 6, 1) = '1'
                  then tb_a_depdt_val.a_p_node_depdt
              end 
            , case 
                when tb_a_tar_path.path_ord_no = 1 and substr(tb_a_dic.enum_value, 7, 1) = '1'
                  then tb_a_indepdt_fore.a_bi_opr_input_len_1st
                when tb_a_tar_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 8, 1) = '1'
                  then tb_a_indepdt_fore.a_bi_opr_input_len_2nd
             -- when tb_a_tar_path.path_ord_no = 3 
             --   then tb_a_indepdt_fore.a_bi_opr_input_len_3rd
              end 
            )
        from cte_indepdt tb_a_indepdt_fore
          , cte_upd_fore_node_indepdt tb_a_depdt_val
          , sm_sc.tb_nn_node tb_a_depdt
          , sm_sc.tb_dic_enum tb_a_dic
        where tb_a_depdt.work_no = i_work_no   -- 2021082501
          and tb_a_depdt.node_no = tb_a_indepdt_fore.node_no
          and tb_a_tar_path.work_no = i_work_no   -- 2021082501
          and tb_a_tar_path.fore_node_no = tb_a_indepdt_fore.node_no
          -- 求导时机 = '前向传播同步'
          and tb_a_dic.enum_name = 'node_fn_type_delta_method'
          and tb_a_dic.enum_group = '0'
          and tb_a_dic.enum_key = tb_a_depdt.node_fn_type
          and tb_a_depdt_val.a_cur_node_no = tb_a_tar_path.fore_node_no
          and (tb_a_indepdt_fore.a_is_bi_opr_input_1st_back and tb_a_tar_path.path_ord_no = 1
               or tb_a_indepdt_fore.a_is_bi_opr_input_2nd_back and tb_a_tar_path.path_ord_no = 2
            -- or tb_a_indepdt_fore.a_is_bi_opr_input_3rd_back and tb_a_tar_path.path_ord_no = 3
              )
              
-- -- for debug
-- )
-- select 
--   array_agg(a_cur_node_no) -- || v_cur_node_nos
--     into v_cur_node_nos
-- from cte_upd_fore_node_indepdt

      ;      
      commit;
      -- --------------------------------------------------
      with 
      -- 参数准备，聚合算子
      cte_indepdt as
      (
        -- 聚合后的入参归并结果当作单目运算唯一参数
        -- 另一个同类型的限制是，一个CASE无法阻止其所包含的聚集表达式 的计算...取而代之的是，可以使用 一个WHERE或FILTER子句来首先阻止有问题的输入行到达 一个聚集函数。
        -- 采用 filter 过滤掉不必要的聚合输入，达到减少聚合计算以及入参宽高一致性保证等安全问题
        select 
          tb_a_fore.node_no
        , tb_a_fore.node_fn_type
        , case 
            when tb_a_fore.node_fn_type = '06_aggr_mx_concat_y'
              then sm_sc.fa_mx_concat_y(tb_a_back.pick_depdt_idx order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_y')
             -- 假定：如果 node_fn_type <>  '06_aggr_mx_concat_y'，那么来路的 pick_depdt_idx 要么为空，要么统一一致
            else sm_sc.fa_range_or(tb_a_back.pick_depdt_idx) filter(where tb_a_fore.node_fn_type <>  '06_aggr_mx_concat_y')
          end
          as a_pick_depdt_idx
        , sm_sc.__fv_set_kv
          (
            case 
              when tb_a_fore.node_fn_type = '06_aggr_mx_sum'
                then sm_sc.fa_mx_sum(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_sum')
              when tb_a_fore.node_fn_type = '06_aggr_mx_prod'
                then sm_sc.fa_mx_prod(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_prod')
              when tb_a_fore.node_fn_type = '06_aggr_mx_avg'
                then sm_sc.fa_mx_avg(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_avg')
              when tb_a_fore.node_fn_type = '06_aggr_mx_max'
                then sm_sc.fa_mx_max(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_max')
              when tb_a_fore.node_fn_type = '06_aggr_mx_min'
                then sm_sc.fa_mx_min(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_min')
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_y'
                then sm_sc.fa_mx_concat_y(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt) order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_y')
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_x'
                then sm_sc.fa_mx_concat_x(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt) order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x')
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_x3'
                then sm_sc.fa_mx_concat_x3(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt) order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x3')
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_x4'
                then sm_sc.fa_mx_concat_x4(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt) order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x4')
            end
          , v_model_code_6 || 
            '_' || i_work_no :: varchar   ||
            '_' || tb_a_fore.node_no :: varchar ||
            '__d_aggr_'
          )
          as a_opr_depdt_p
        , sm_sc.fa_mx_max(tb_a_back.node_depdt_len) as a_opr_depdt_len
        , (sm_sc.fa_mx_or(array[tb_a_back.is_back_node]))[1] as a_is_opr_input_back
        from sm_sc.tb_nn_node tb_a_fore
        inner join sm_sc.tb_nn_path tb_a_path
          on tb_a_path.work_no = i_work_no   -- 2021082501
            and tb_a_path.fore_node_no = tb_a_fore.node_no
        inner join sm_sc.tb_nn_node tb_a_back
          on tb_a_back.work_no = i_work_no   -- 2021082501
            and tb_a_back.node_no = tb_a_path.back_node_no
        -- 先处理单目、双目（三目）算子，聚合函数算子另行处理
        inner join sm_sc.tb_dic_enum tb_a_dic
          on tb_a_dic.enum_name = 'node_fn_type'
            and tb_a_dic.enum_key = tb_a_fore.node_fn_type
            and tb_a_dic.enum_group = 'n_p'
        where tb_a_fore.work_no = i_work_no   -- 2021082501
          and tb_a_fore.nn_depth_no = v_cur_nn_depth
          and (tb_a_fore.is_fore_node or v_cur_learn_cnt = v_learn_cnt_init)
        group by tb_a_fore.node_no, tb_a_fore.node_fn_type
      )
      ,
      -- 前向传播
      cte_upd_fore_node_indepdt as 
      (
        update sm_sc.tb_nn_node tb_a_tar_depdt
        set 
          pick_depdt_idx     = tb_a_indepdt_fore.a_pick_depdt_idx
        , p_node_depdt    = tb_a_indepdt_fore.a_opr_depdt_p
        , learn_cnt_fore     = v_cur_learn_cnt + 1  -- 强制对齐训练次数，避免路径跟踪混乱   -- tb_a_tar_depdt.learn_cnt_fore + 1
        from cte_indepdt tb_a_indepdt_fore
        where tb_a_tar_depdt.work_no = i_work_no   -- 2021082501
          and tb_a_indepdt_fore.node_no = tb_a_tar_depdt.node_no
        returning 
          tb_a_tar_depdt.node_no as a_cur_node_no
      )
--       ,
      -- 前向传播同步求导 p_ddepdt_dindepdt
      
-- -- for debug
-- cte_upd_path as 
-- (

        update sm_sc.tb_nn_path tb_a_tar_path
        set 
          p_ddepdt_dindepdt =
            case tb_a_fore.node_fn_type
              when '06_aggr_mx_sum'
                then 
                  sm_sc.__fv_set_kv
                  (
                    sm_sc.fv_d_mx_sum(tb_a_indepdt_fore.a_opr_depdt_len)
                  , v_model_code_6 || 
                    '_' || tb_a_tar_path.work_no :: varchar        ||
                    '_' || tb_a_tar_path.fore_node_no :: varchar ||
                    '_' || tb_a_tar_path.back_node_no :: varchar || 
                    '_dddi__'  -- 'd_depdt_d_indepdt'
                  )
              when '06_aggr_mx_prod'
                then 
                  sm_sc.__fv_set_kv
                  (
                    sm_sc.fv_d_mx_prod(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt), sm_sc.__fv_get_kv(tb_a_fore.p_node_depdt))
                  , v_model_code_6 || 
                    '_' || tb_a_tar_path.work_no :: varchar        ||
                    '_' || tb_a_tar_path.fore_node_no :: varchar || 
                    '_' || tb_a_tar_path.back_node_no :: varchar || 
                    '_dddi__'  -- 'd_depdt_d_indepdt'
                  )
              when '06_aggr_mx_avg'
                then 
                  sm_sc.__fv_set_kv
                  (
                    sm_sc.fv_d_mx_avg(tb_a_fore.node_fn_asso_value[1] :: int, tb_a_indepdt_fore.a_opr_depdt_len)
                  , v_model_code_6 || 
                    '_' || tb_a_tar_path.work_no :: varchar      ||
                    '_' || tb_a_tar_path.fore_node_no :: varchar || 
                    '_' || tb_a_tar_path.back_node_no :: varchar || 
                    '_dddi__'  -- 'd_depdt_d_indepdt'
                  )
              when '06_aggr_mx_max'
                then 
                  sm_sc.__fv_set_kv
                  (
                    sm_sc.fv_d_mx_max(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt), sm_sc.__fv_get_kv(tb_a_fore.p_node_depdt))
                  , v_model_code_6 || 
                    '_' || tb_a_tar_path.work_no :: varchar        ||
                    '_' || tb_a_tar_path.fore_node_no :: varchar || 
                    '_' || tb_a_tar_path.back_node_no :: varchar || 
                    '_dddi__'  -- 'd_depdt_d_indepdt'
                  )
              when '06_aggr_mx_min'
                then 
                  sm_sc.__fv_set_kv
                  (
                    sm_sc.fv_d_mx_min(sm_sc.__fv_get_kv(tb_a_back.p_node_depdt), sm_sc.__fv_get_kv(tb_a_fore.p_node_depdt))
                  , v_model_code_6 || 
                    '_' || tb_a_tar_path.work_no :: varchar        ||
                    '_' || tb_a_tar_path.fore_node_no :: varchar ||
                    '_' || tb_a_tar_path.back_node_no :: varchar ||
                    '_dddi__'  -- 'd_depdt_d_indepdt'
                  )
            end
        from cte_indepdt tb_a_indepdt_fore
          , sm_sc.tb_nn_node tb_a_fore
          , sm_sc.tb_nn_node tb_a_back
          , sm_sc.tb_dic_enum tb_a_dic
        where tb_a_fore.work_no = i_work_no   -- 2021082501
          and tb_a_fore.node_no = tb_a_indepdt_fore.node_no
          and tb_a_tar_path.work_no = i_work_no   -- 2021082501
          and tb_a_tar_path.fore_node_no = tb_a_indepdt_fore.node_no
          and tb_a_back.work_no = i_work_no   -- 2021082501
          and tb_a_back.node_no = tb_a_tar_path.back_node_no
          -- 求导时机 = '前向传播同步'
          and tb_a_dic.enum_name = 'node_fn_type_delta_method'
          and tb_a_dic.enum_group = '0'
          and tb_a_dic.enum_key = tb_a_fore.node_fn_type
          and tb_a_indepdt_fore.a_is_opr_input_back
          
-- -- for debug
-- )
-- select 
--   array_agg(a_cur_node_no) || v_cur_node_nos
--     into v_cur_node_nos
-- from cte_upd_fore_node_indepdt

      ;      
      commit;

      if not i_tensor_log
      then
        -- 清理当前层前向传播后的无用张量 kv
        -- 清理 depdt
        with 
        cte_clear_kv_list as 
        (
          select
            tb_a_back_node.node_no
          , max(tb_a_back_node.p_node_depdt) as p_node_depdt
          from sm_sc.tb_nn_node tb_a_main_fore_node
          inner join sm_sc.tb_nn_path tb_a_main_path
            on tb_a_main_path.fore_node_no = tb_a_main_fore_node.node_no 
              and tb_a_main_path.work_no = i_work_no
          inner join sm_sc.tb_nn_node tb_a_back_node
            on tb_a_back_node.node_no = tb_a_main_path.back_node_no
              and tb_a_back_node.work_no = i_work_no
          inner join sm_sc.tb_dic_enum tb_a_back_dic 
            on tb_a_back_dic.enum_name = 'node_fn_type_delta_method'
              and tb_a_back_dic.enum_key = tb_a_back_node.node_fn_type
              and substr(tb_a_back_dic.enum_value, 5, 2) = '00'  -- 第一/二目求导不需要因变量
          inner join sm_sc.tb_nn_path tb_a_path
            on tb_a_path.work_no = i_work_no
              and tb_a_path.back_node_no = tb_a_back_node.node_no
          inner join sm_sc.tb_nn_node tb_a_fore_node
            on tb_a_fore_node.work_no = i_work_no
              and tb_a_fore_node.node_no = tb_a_path.fore_node_no
          left join sm_sc.tb_dic_enum tb_a_fore_dic 
            on tb_a_fore_dic.enum_name = 'node_fn_type_delta_method'
              and tb_a_fore_dic.enum_key = tb_a_fore_node.node_fn_type
          left join sm_sc.tb_nn_path tb_a_asso_path
            on tb_a_asso_path.work_no = i_work_no 
              and tb_a_asso_path.fore_node_no = tb_a_fore_node.node_no
              and tb_a_fore_node.is_back_node
          left join sm_sc.tb_nn_node tb_a_asso_back_node 
            on tb_a_asso_back_node.work_no = i_work_no
              and tb_a_asso_back_node.node_no = tb_a_asso_path.back_node_no
              and tb_a_asso_path.path_ord_no <> tb_a_path.path_ord_no
              and tb_a_asso_back_node.is_back_node
          where tb_a_main_fore_node.work_no = i_work_no
            and tb_a_main_fore_node.nn_depth_no = v_cur_nn_depth
          group by tb_a_back_node.node_no 
          having max(tb_a_fore_node.nn_depth_no) <= v_cur_nn_depth
            and   -- 不是反向传播求导所需要的自变量，才可以被清理。否则，反向传播求导会用到，也不能被清理。
              max
              (
                -- fore_node 第一目求导是否用到该 back 变量
                case 
                  when tb_a_path.path_ord_no = 1 
                    then substr(tb_a_fore_dic.enum_value, 1, 1) 
                  when tb_a_path.path_ord_no = 2 and tb_a_asso_back_node.node_no is not null
                    then substr(tb_a_fore_dic.enum_value, 3, 1) 
                  when tb_a_path.path_ord_no = 3 
                    then '0'
                  else '0'
                end
                ||
                -- fore_node 第二目求导是否用到该 back 变量
                case 
                  when tb_a_path.path_ord_no = 2 
                    then substr(tb_a_fore_dic.enum_value, 2, 1) 
                  when tb_a_path.path_ord_no = 1 and tb_a_asso_back_node.node_no is not null
                    then substr(tb_a_fore_dic.enum_value, 4, 1) 
                  when tb_a_path.path_ord_no = 3 
                    then '0'
                  else '0'
                end
              )
              = '00'
        ),
        cte_upd_node_k_2_null as 
        (
          update sm_sc.tb_nn_node tb_a_back_node
          set 
            p_node_depdt        = null
          from cte_clear_kv_list tb_a_key_list
          where tb_a_back_node.node_no = tb_a_key_list.node_no
            and tb_a_back_node.work_no = i_work_no
        )
        select  --  perform 暂不支持 cte，所以采用 select  into null 暂时代替。
          -- 同一 dml/dql 中，要尽量避免多次调用 sm_sc.__fv_delete_kv，所以将待清理 arr_key 集中在一处 __fv_delete_kv，放在最外层，
          sm_sc.__fv_delete_kv
          (
            (select array_agg(p_node_depdt) from cte_clear_kv_list)
          ) into v_null
        ;
      
-- -- debug
-- raise notice 'debug 002.9. v_null: %', v_null;
        v_null := null;
      end if;
-- -- -- debug
-- raise notice 'debug 003. step fore end: v_cur_learn_cnt: %; v_cur_node_nos: %; v_cur_nn_depth: %; at %;', v_cur_learn_cnt, v_cur_node_nos, v_cur_nn_depth, date_trunc('milliseconds', now());

    end loop;
-- -----------------------------------------------------------------------
    -- 对 i_depdt_01 小批量抽样，获得本轮 v_depdt
    if v_is_output_01
    then 
      select 
        array_agg(tb_a_buff.i_depdt_01 order by tb_a_idx.a_idx, tb_a_buff.ord_no)
      into 
        v_depdt_01
      from sm_sc.tb_nn_node tb_a_sour
      inner join generate_series(1, array_length(tb_a_sour.pick_depdt_idx, 1)) tb_a_idx(a_idx)
        on tb_a_sour.node_type = 'output_01'
      inner join sm_sc.tb_nn_train_input_buff tb_a_buff
        on tb_a_buff.ord_no <@ (tb_a_sour.pick_depdt_idx[tb_a_idx.a_idx])
      where tb_a_sour.work_no = i_work_no
        and tb_a_buff.work_no = i_work_no
      ;
    end if;
    
-- -- debug
-- raise notice 'debug 003.1. v_depdt_01: %', array_dims(v_depdt_01);
   
    if v_is_output_02
    then 
       select 
         array_agg(tb_a_buff.i_depdt_02 order by tb_a_idx.a_idx, tb_a_buff.ord_no)
       into 
         v_depdt_02
       from sm_sc.tb_nn_node tb_a_sour
       inner join generate_series(1, array_length(tb_a_sour.pick_depdt_idx, 1)) tb_a_idx(a_idx)
         on tb_a_sour.node_type = 'output_02'
       inner join sm_sc.tb_nn_train_input_buff tb_a_buff
         on tb_a_buff.ord_no <@ (tb_a_sour.pick_depdt_idx[tb_a_idx.a_idx])
       where tb_a_sour.work_no = i_work_no
         and tb_a_buff.work_no = i_work_no
       ;
    end if;
    
    if v_is_output_03
    then
      select 
        array_agg(tb_a_buff.i_depdt_03 order by tb_a_idx.a_idx, tb_a_buff.ord_no)
      into 
        v_depdt_03
      from sm_sc.tb_nn_node tb_a_sour
      inner join generate_series(1, array_length(tb_a_sour.pick_depdt_idx, 1)) tb_a_idx(a_idx)
        on tb_a_sour.node_type = 'output_03'
      inner join sm_sc.tb_nn_train_input_buff tb_a_buff
        on tb_a_buff.ord_no <@ (tb_a_sour.pick_depdt_idx[tb_a_idx.a_idx])
      where tb_a_sour.work_no = i_work_no
        and tb_a_buff.work_no = i_work_no
      ;
    end if;
    
    if v_is_output_04
    then 
      select 
        array_agg(tb_a_buff.i_depdt_04 order by tb_a_idx.a_idx, tb_a_buff.ord_no)
      into 
        v_depdt_04
      from sm_sc.tb_nn_node tb_a_sour
      inner join generate_series(1, array_length(tb_a_sour.pick_depdt_idx, 1)) tb_a_idx(a_idx)
        on tb_a_sour.node_type = 'output_04'
      inner join sm_sc.tb_nn_train_input_buff tb_a_buff
        on tb_a_buff.ord_no <@ (tb_a_sour.pick_depdt_idx[tb_a_idx.a_idx])
      where tb_a_sour.work_no = i_work_no
        and tb_a_buff.work_no = i_work_no
      ;
    end if;

    -- 损失函数
    v_cur_loss = 
      sm_sc.fv_lambda_loss
      (
        v_loss_fn_type :: varchar(32)
      , (select sm_sc.__fv_get_kv(p_node_depdt) from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_01')
      , v_depdt_01
      , (select sm_sc.__fv_get_kv(p_node_depdt) from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_02')
      , v_depdt_02
      , (select sm_sc.__fv_get_kv(p_node_depdt) from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_03')
      , v_depdt_03
      , (select sm_sc.__fv_get_kv(p_node_depdt) from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output_04')
      , v_depdt_04
      ) 
    ;

-- -- -- debug
-- raise notice 'debug 004. step fore end: len of v_depdt: %; v_cur_loss: %; at %;', array_dims(v_depdt_01), v_cur_loss, date_trunc('milliseconds', now());

-- -----------------------------------------------------------------------
    -- 反向传播
    -- 反向传播起点：全局损失函数对输出 z 求导(均方差、最小二乘法)
    -- 规约：node_type in ('output_01', 'output_02', 'output_03', 'output_04') 各只有一个
    update sm_sc.tb_nn_node t_a_tar
    set 
      p_node_dloss_ddepdt = 
        sm_sc.__fv_set_kv 
        (
          sm_sc.fv_lambda_dloss_dz
          (
            v_loss_fn_type
          , sm_sc.__fv_get_kv(t_a_tar.p_node_depdt)
          , case node_type when 'output_01' then v_depdt_01 when 'output_02' then v_depdt_02 when 'output_03' then v_depdt_03 when 'output_04' then v_depdt_04 end
          , node_type
          )
        , v_model_code_6 || 
          '_' || i_work_no :: varchar   ||
          '__' || node_no :: varchar ||     -- back_node_no
          '_dldi__'   -- 'd_loss_d_indepdt'
        )
    , learn_cnt_back = v_cur_learn_cnt + 1 -- 强制对齐训练次数，避免路径计算混乱    -- t_tar.learn_cnt_back + 1
    where node_type in ('output_01', 'output_02', 'output_03', 'output_04')
      and work_no = i_work_no   -- 2021082501
    ;
    commit;

-- -- -- debug
-- raise notice 'debug 005. step fore end: v_cur_learn_cnt: %; at %;', v_cur_learn_cnt, date_trunc('milliseconds', now());

    v_cur_nn_depth := v_nn_depth;
    
-- -- for debug
-- v_cur_node_nos := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('output_01', 'output_02', 'output_03', 'output_04') limit 1);

    while 
      exists 
      (
        select  from sm_sc.tb_nn_node tb_a_back
        where tb_a_back.work_no = i_work_no    -- 2021082501
          and tb_a_back.learn_cnt_back <= v_cur_learn_cnt
          and tb_a_back.is_back_node is true
        limit 1
      )
      and v_cur_nn_depth > 0
    loop

-- -- -- debug
-- raise notice 'debug 006. step back begin: v_cur_learn_cnt: %; v_cur_node_nos: %; v_cur_nn_depth: %; at %;', v_cur_learn_cnt, v_cur_node_nos, v_cur_nn_depth, date_trunc('milliseconds', now());

      with 
      cte_dloss_dindepdt as
      (
        select 
          tb_a_back.node_no,
          sm_sc.fa_mx_sum
          (
            sm_sc.__fv_get_kv
            (
              sm_sc.fv_lambda_arr_dloss_dindepdt_p
              (
                v_model_code_6
              , i_work_no
              , tb_a_fore.node_no
              , tb_a_path.back_node_no
              , tb_a_fore.node_fn_type
              -- 以下入参是否传入，由 字典表 enum_name = 'node_fn_type_delta_method' 控制
              -- 对于聚合算子的所有自变量，无论顺序，统一以 path_ord_no = 1 配置该控制
              , case 
                  when (tb_a_path.path_ord_no = 1 or tb_a_fore.node_fn_type like '06_aggr_%')
                       and substr(tb_a_dic.enum_value, 1, 1) = '1'
                    or tb_a_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 2, 1) = '1'
                    then tb_a_back.p_node_depdt 
                end
              , tb_a_path.path_ord_no 
              , case 
                  when (tb_a_path.path_ord_no = 1 or tb_a_fore.node_fn_type like '06_aggr_%')
                       and substr(tb_a_dic.enum_value, 3, 1) = '1'
                    or tb_a_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 4, 1) = '1'
                    then tb_a_back_co.p_node_depdt
                end
              , tb_a_fore.node_fn_asso_value
              , case 
                  when (tb_a_path.path_ord_no = 1 or tb_a_fore.node_fn_type like '06_aggr_%')
                       and substr(tb_a_dic.enum_value, 5, 1) = '1'
                    or tb_a_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 6, 1) = '1'
                    then tb_a_fore.p_node_depdt
                end
              , tb_a_fore.p_node_dloss_ddepdt
              , case 
                  when (tb_a_path.path_ord_no = 1 or tb_a_fore.node_fn_type like '06_aggr_%')
                       and substr(tb_a_dic.enum_value, 7, 1) = '1'
                    or tb_a_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 8, 1) = '1'
                    or tb_a_path.path_ord_no = 3 -- 当前仅 05_conv_2d, 05_tunnel_conv 支持第三目运算符，且求导需要自变量规格
                    then tb_a_back.node_depdt_len
                end
              , tb_a_path.p_ddepdt_dindepdt
              )
            , true
            )
          ) as a_dloss_dindepdt
        from sm_sc.tb_nn_node tb_a_back
        inner join sm_sc.tb_nn_path tb_a_path
          on tb_a_path.back_node_no = tb_a_back.node_no
      	  and tb_a_path.work_no = i_work_no   -- 2021082501
        inner join sm_sc.tb_nn_node tb_a_fore
          on tb_a_fore.node_no = tb_a_path.fore_node_no
          and tb_a_fore.work_no = i_work_no   -- 2021082501
        left join sm_sc.tb_dic_enum tb_a_dic
          on tb_a_dic.enum_name = 'node_fn_type_delta_method'
          -- and tb_a_dic.enum_group = '1'
          and tb_a_dic.enum_key = tb_a_fore.node_fn_type
        left join sm_sc.tb_nn_path tb_a_path_co
          on tb_a_path_co.fore_node_no = tb_a_fore.node_no
      	  and tb_a_path_co.work_no = i_work_no   -- 2021082501
          and (tb_a_path.path_ord_no = 1 and tb_a_path_co.path_ord_no = 2
               or tb_a_path.path_ord_no = 2 and tb_a_path_co.path_ord_no = 1)
        left join sm_sc.tb_nn_node tb_a_back_co
          on tb_a_back_co.node_no = tb_a_path_co.back_node_no
          and tb_a_back_co.work_no = i_work_no   -- 2021082501
        where tb_a_back.work_no = i_work_no   -- 2021082501
          and tb_a_back.nn_depth_no = v_cur_nn_depth - 1
          and tb_a_back.is_back_node
        group by tb_a_back.node_no
      )
      
-- -- for debug v_cur_node_nos
-- ,
-- cte_upd_node as
-- (

      update sm_sc.tb_nn_node t_tar
      set 
        p_node_dloss_ddepdt = 
          sm_sc.__fv_set_kv 
          (
            t_sour.a_dloss_dindepdt
          , v_model_code_6 || 
            '_' || i_work_no :: varchar   ||
            '_' || t_tar.node_no :: varchar ||
            '__dldi__'  -- 'd_loss_d_indepdt'
          )
      , learn_cnt_back = v_cur_learn_cnt + 1 -- 强制对齐训练次数，避免路径计算混乱    -- t_tar.learn_cnt_back + 1
      from cte_dloss_dindepdt t_sour
      where t_sour.node_no = t_tar.node_no

-- -- for debug v_cur_node_nos
--   returning t_tar.node_no as a_cur_node_no
-- )
-- select 
--   array_agg(a_cur_node_no) into v_cur_node_nos
-- from cte_upd_node

      ;
      commit;
      
      -- de_broadcast, dloss_ddepdt 的广播逆运算
      update sm_sc.tb_nn_node t_tar
      set 
        p_node_dloss_ddepdt = 
          sm_sc.__fv_set_kv
          (
            sm_sc.fv_aggr_chunk_sum(sm_sc.__fv_get_kv(p_node_dloss_ddepdt), node_depdt_len)
          , v_model_code_6 || 
            '_' || t_tar.work_no :: varchar ||
            '_' || t_tar.node_no :: varchar ||
            '__dldi__'  -- 'd_loss_d_indepdt'
          )
      where work_no = i_work_no   -- 2021082501
        and nn_depth_no = v_cur_nn_depth - 1
        and cardinality(sm_sc.__fv_get_kv(p_node_dloss_ddepdt)) / cardinality(sm_sc.__fv_get_kv(p_node_depdt)) > 1
        and cardinality(sm_sc.__fv_get_kv(p_node_dloss_ddepdt)) % cardinality(sm_sc.__fv_get_kv(p_node_depdt)) = 0
      ; 
      commit;

-- -- -- debug
-- raise notice 'debug 007. step back end: v_cur_learn_cnt: %; v_cur_node_nos: %; v_cur_nn_depth: %; at: %;', v_cur_learn_cnt, v_cur_node_nos, v_cur_nn_depth, date_trunc('milliseconds', now());

      if not i_tensor_log
      then
        -- 清理当前层反向传播后的无用张量 kv
        -- 清理 dloss_ddepdt, depdt
        with 
        -- 情形一: 不被比 v_cur_nn_depth 更小 depth 的节点，当求导协参(另一个自变量)
        cte_clear_kv_list_covalue as 
        (
          select
            tb_a_main_back_node.node_no
          , max(tb_a_main_back_node.p_node_depdt) as p_node_depdt
          , array_agg(distinct tb_a_path.p_ddepdt_dindepdt) filter(where tb_a_path.p_ddepdt_dindepdt is not null) as p_ddepdt_dindepdt_s
          from sm_sc.tb_nn_node tb_a_main_back_node
          inner join sm_sc.tb_nn_path tb_a_main_path
            on tb_a_main_path.back_node_no = tb_a_main_back_node.node_no
              and tb_a_main_path.work_no = i_work_no
          inner join sm_sc.tb_nn_node tb_a_fore_node
            on tb_a_fore_node.node_no = tb_a_main_path.fore_node_no
              and tb_a_fore_node.work_no = i_work_no
          inner join sm_sc.tb_dic_enum tb_a_dic 
            on tb_a_dic.enum_name = 'node_fn_type_delta_method'
              and tb_a_dic.enum_key = tb_a_fore_node.node_fn_type
          inner join sm_sc.tb_nn_path tb_a_path
            on tb_a_path.work_no = i_work_no
            and tb_a_path.fore_node_no = tb_a_fore_node.node_no
          left join sm_sc.tb_nn_node tb_a_back_node
            on tb_a_back_node.work_no = i_work_no
            and tb_a_back_node.node_no = tb_a_path.back_node_no
            and tb_a_back_node.is_back_node
            -- 双目求导需要协参，目位置分别判断
            and 
            (
              tb_a_main_path.path_ord_no = 1 and substr(tb_a_dic.enum_value, 4, 1) = '1' 
              or 
              tb_a_main_path.path_ord_no = 2 and substr(tb_a_dic.enum_value, 3, 1) = '1'
            )             
          where tb_a_main_back_node.work_no = i_work_no
            and tb_a_main_back_node.nn_depth_no = v_cur_nn_depth
            -- and tb_a_main_back_node.p_node_dloss_ddepdt is not null
            and tb_a_main_back_node.node_type <> 'weight'
            and tb_a_main_back_node.node_fn_type <> '00_const'
          group by tb_a_main_back_node.node_no 
          having min(tb_a_back_node.nn_depth_no) >= v_cur_nn_depth
            or count(tb_a_back_node.nn_depth_no) = 0
        ),
        cte_upd_node_k_2_null as 
        (
          update sm_sc.tb_nn_node tb_a_fore_node
          set 
            p_node_depdt        = null
          from cte_clear_kv_list_covalue tb_a_key_list
          where tb_a_fore_node.node_no = tb_a_key_list.node_no
            and tb_a_fore_node.work_no = i_work_no
        )
        select   --  perform 暂不支持 cte，所以采用 select  into null 暂时代替。
          sm_sc.__fv_delete_kv
          (
            (
              select 
                array_agg(p_node_depdt) 
              from cte_clear_kv_list_covalue
            )
          ) into v_null
        ;
        commit;
        
        -- 情形二: 不被比 v_cur_nn_depth - 1 更小 depth 的节点，当做因变量
        with
        cte_clear_kv_list_dloss as 
        (
          select 
            tb_a_fore_node.node_no
          , max(tb_a_fore_node.p_node_dloss_ddepdt) as p_node_dloss_ddepdt
          , array_agg(distinct tb_a_path.p_ddepdt_dindepdt) filter(where tb_a_path.p_ddepdt_dindepdt is not null) as p_ddepdt_dindepdt_s
          from sm_sc.tb_nn_node tb_a_main_back_node
          inner join sm_sc.tb_nn_path tb_a_main_path
            on tb_a_main_path.back_node_no = tb_a_main_back_node.node_no
              and tb_a_main_path.work_no = i_work_no
          inner join sm_sc.tb_nn_node tb_a_fore_node
            on tb_a_fore_node.node_no = tb_a_main_path.fore_node_no
              and tb_a_fore_node.work_no = i_work_no
          inner join sm_sc.tb_nn_path tb_a_path
            on tb_a_path.work_no = i_work_no
            and tb_a_path.fore_node_no = tb_a_fore_node.node_no
          left join sm_sc.tb_nn_node tb_a_back_node
            on tb_a_back_node.work_no = i_work_no
            and tb_a_back_node.node_no = tb_a_path.back_node_no
            and tb_a_back_node.is_back_node
          where tb_a_main_back_node.work_no = i_work_no
            and tb_a_main_back_node.nn_depth_no = v_cur_nn_depth - 1
            and tb_a_fore_node.p_node_dloss_ddepdt is not null
            and tb_a_fore_node.node_type <> 'weight'
            and tb_a_fore_node.node_fn_type <> '00_const'
          group by tb_a_fore_node.node_no
          having min(tb_a_back_node.nn_depth_no) >= v_cur_nn_depth - 1
            or count(tb_a_back_node.nn_depth_no) = 0
        ),
        cte_upd_node_k_2_null as 
        (
          update sm_sc.tb_nn_node tb_a_fore_node
          set 
            p_node_dloss_ddepdt = null
          from cte_clear_kv_list_dloss tb_a_key_list
          where tb_a_fore_node.node_no = tb_a_key_list.node_no
            and tb_a_fore_node.work_no = i_work_no
        ),
        cte_upd_path_k_2_null as 
        (
          update sm_sc.tb_nn_path tb_a_fore_path
          set 
            p_ddepdt_dindepdt = null
          from (select node_no, a_p_ddepdt_dindepdt from cte_clear_kv_list_dloss, unnest(p_ddepdt_dindepdt_s) a_p_ddepdt_dindepdt) tb_a_key_list
          where tb_a_fore_path.fore_node_no = tb_a_key_list.node_no
            and tb_a_fore_path.p_ddepdt_dindepdt = tb_a_key_list.a_p_ddepdt_dindepdt
            and tb_a_fore_path.work_no = i_work_no
        )
        select   --  perform 暂不支持 cte，所以采用 select  into null 暂时代替。
          sm_sc.__fv_delete_kv
          (
            (
              select 
                array_agg(p_node_dloss_ddepdt) 
                || 
                sm_sc.fa_array_concat(p_ddepdt_dindepdt_s) 
              from cte_clear_kv_list_dloss
            )
          ) into v_null
        ;
        
        commit;
-- -- debug
-- raise notice 'debug 007.1. v_null: %', v_null;
        v_null := null;
      end if;
      
      v_cur_nn_depth := v_cur_nn_depth - 1;

    end loop;
    
    -- L1 正则化
    if i_l1 is not null 
    then  
      -- update sm_sc.tb_nn_node tar
      -- set 
      --   p_node_depdt = tar.p_node_depdt -` i_l1
      -- where work_no = i_work_no   -- 2021082501
      --   and node_type = 'weight'
      -- ;
      -- commit;
      
      perform
        sm_sc.__fv_set_kvs
        (
          array_agg 
          (
            (
              sm_sc.__fv_get_kv(tar.p_node_depdt) -` i_l1
            ) :: sm_sc.__typ_array_ex
            order by node_no
          )
        , array_agg(p_node_depdt order by node_no)
        )
      from sm_sc.tb_nn_node tar
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
        and p_node_depdt is not null
      ;
      commit;
    end if;
    
    -- L2 正则化
    if i_l2 is not null 
    then  
      -- update sm_sc.tb_nn_node tar
      -- set 
      --   p_node_depdt = tar.p_node_depdt *` (1.0 - i_l2)
      -- where work_no = i_work_no   -- 2021082501
      --   and node_type = 'weight'
      -- ;
      -- commit;
      
      perform
        sm_sc.__fv_set_kvs
        (
          array_agg 
          (
            (
              sm_sc.__fv_get_kv(tar.p_node_depdt) *` (1.0 - i_l2)
            ) :: sm_sc.__typ_array_ex
            order by node_no
          )
        , array_agg(p_node_depdt order by node_no)
        )
      from sm_sc.tb_nn_node tar
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
        and p_node_depdt is not null
      ;
      commit;
    end if;

    -- 更新 w 参数，一次训练完成
    if not i_is_adam or i_is_adam is null
    then 
      -- update sm_sc.tb_nn_node tar
      -- set 
      --   -- p_node_depdt = tar.p_node_depdt -` (i_learn_rate *` tar.p_node_dloss_ddepdt)
      --   p_node_depdt = 
      --     tar.p_node_depdt 
      --     -` 
      --     (
      --       i_learn_rate 
      --       *` 
      --       -- 梯度截断，绝对值不超过 1000
      --       (
      --         100.0 :: float 
      --         *` 
      --         sm_sc.fv_tanh_py
      --         (
      --           tar.p_node_dloss_ddepdt 
      --           /` 
      --           100.0 :: float
      --         )
      --       )
      --       -- -- 如下梯度截断和差异更平缓一些
      --       -- (
      --       --   100.0 :: float 
      --       --   *` 
      --       --   (
      --       --     sm_sc.fv_tanh_py
      --       --     (
      --       --       (
      --       --         (@|` tar.p_node_dloss_ddepdt)
      --       --         /` 
      --       --         100.0 :: float
      --       --       )
      --       --       ^` 
      --       --       0.5 :: float
      --       --     )
      --       --     ^`
      --       --     2.0 :: float
      --       --   )
      --       --   *` 
      --       --   ((<>` tar.p_node_dloss_ddepdt) :: float[])
      --       -- )
      --     )
      -- where work_no = i_work_no   -- 2021082501
      --   and node_type = 'weight'
      -- ;
      -- commit;
      
      perform
        sm_sc.__fv_set_kvs
        (
          array_agg 
          (
            (
              sm_sc.__fv_get_kv(p_node_depdt)
              -` 
              (
                i_learn_rate 
                *` 
                -- 梯度截断，绝对值不超过 1000
                (
                  100.0 :: float 
                  *` 
                  sm_sc.fv_tanh_py
                  (
                    sm_sc.__fv_get_kv(p_node_dloss_ddepdt)
                    /` 
                    100.0 :: float
                  )
                )
              )
            ) :: sm_sc.__typ_array_ex
          order by node_no
          )
        , array_agg(p_node_depdt order by node_no)
        )
      from sm_sc.tb_nn_node
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
        and p_node_dloss_ddepdt is not null
      ;

    else
      -- 采用 Adam 梯度下降算法
      update sm_sc.tb_nn_node tar
      set 
        -- p_node_depdt = tar.p_node_depdt -` (i_learn_rate *` tar.p_node_dloss_ddepdt)
        cost_delta_l1 = (v_beta_l1 *` coalesce(case when array_length(cost_delta_l1, 1) = array_length(sm_sc.__fv_get_kv(tar.p_node_dloss_ddepdt), 1) then cost_delta_l1 else null end, sm_sc.__fv_get_kv(tar.p_node_dloss_ddepdt))) +` ((1.0 :: float - v_beta_l1) *` sm_sc.__fv_get_kv(tar.p_node_dloss_ddepdt)),
        cost_delta_l2 = (v_beta_l2 *` coalesce(case when array_length(cost_delta_l2, 1) = array_length(sm_sc.__fv_get_kv(tar.p_node_dloss_ddepdt), 1) then cost_delta_l2 else null end, (sm_sc.__fv_get_kv(tar.p_node_dloss_ddepdt) ^` 2.0 :: float))) +` ((1.0 :: float - v_beta_l2) *` (sm_sc.__fv_get_kv(tar.p_node_dloss_ddepdt) ^` 2.0 :: float))
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
      ;
      commit;
      
      -- update sm_sc.tb_nn_node tar
      -- set 
      --   p_node_depdt =
      --     tar.p_node_depdt 
      --     -`
      --     (
      --       (
      --         cost_delta_l1 *`
      --         (i_learn_rate / (1.0 :: float - (v_beta_l1 ^ (least(v_cur_learn_cnt, 7070) + 1))))      -- v_cur_learn_cnt 大于 7072 之后，exp 精度不够，等同于 7071
      --       ) /`
      --       (
      --         sm_sc.fv_ele_replace
      --         (
      --           (
      --             cost_delta_l2 /` (1.0 :: float - (v_beta_l2 ^ (least(v_cur_learn_cnt, 7070) + 1)))  -- v_cur_learn_cnt 大于 7072 之后，exp 精度不够，等同于 7071
      --           ) ^` 0.5 :: float
      --           , array[0.0 :: float]
      --           , 1e-128 :: float   -- 1e-128 :: float        
      --         )
      --       )
      --     )
      -- where work_no = i_work_no   -- 2021082501
      --   and node_type = 'weight'
      -- ;
      -- commit;
      
      perform
        sm_sc.__fv_set_kvs
        (
          array_agg
          (
            (
              sm_sc.__fv_get_kv(p_node_depdt)
              -` 
              (
                i_learn_rate 
                -`
                (
                  (
                    cost_delta_l1 *`
                    (i_learn_rate / (1.0 :: float - (v_beta_l1 ^ (least(v_cur_learn_cnt, 7070) + 1))))      -- v_cur_learn_cnt 大于 7072 之后，exp 精度不够，等同于 7071
                  ) /`
                  (
                    sm_sc.fv_ele_replace
                    (
                      (
                        cost_delta_l2 /` (1.0 :: float - (v_beta_l2 ^ (least(v_cur_learn_cnt, 7070) + 1)))  -- v_cur_learn_cnt 大于 7072 之后，exp 精度不够，等同于 7071
                      ) ^` 0.5 :: float
                      , array[0.0 :: float]
                      , 1e-128 :: float   -- 1e-128 :: float        
                    )
                  )
                )
              )
            ) :: sm_sc.__typ_array_ex
            order by node_no
          )
        , array_agg(p_node_depdt order by node_no)
        )
      from sm_sc.tb_nn_node
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
        and p_node_depdt is not null
      ;
    end if;

    v_cur_learn_cnt := v_cur_learn_cnt + 1;

    -- 寄存至 sm_sc.tb_classify_task
    if v_cur_learn_cnt % 1 = 0     -- 或者 100 次， 1000 次， 10000次。。。
      or v_cur_learn_cnt >= v_limit_train_times
      or v_cur_loss < i_loss_delta_least_stop_threshold
    then 
      insert into sm_sc.tb_classify_task
      (
        work_no
      , learn_cnt
      , loss_delta
      )
      select 
        i_work_no
      , v_cur_learn_cnt
      , v_cur_loss
      on conflict(work_no) do 
      update set
        learn_cnt = v_cur_learn_cnt
      , loss_delta = v_cur_loss
      ;
    
      insert into sm_sc.__vt_nn_node
      (
        work_no                      ,
        node_no                      ,        
        node_type                    ,
        node_fn_type                 ,
        node_fn_asso_value           ,
        nn_depth_no                  ,
        node_depdt_vals              ,
        p_node_depdt                  
      )
      select 
        tb_a_sour.work_no                      ,
        tb_a_sour.node_no                      ,        
        tb_a_sour.node_type                    ,
        tb_a_sour.node_fn_type                 ,
        tb_a_sour.node_fn_asso_value           ,
        tb_a_sour.nn_depth_no                  ,
        sm_sc.__fv_get_kv(tb_a_sour.p_node_depdt),
        case 
          when tb_a_sour.node_type = 'weight' 
            or tb_a_sour.node_fn_type = '00_const' 
          then 
            sm_sc.__fv_set_kv
            (
              sm_sc.__fv_get_kv(tb_a_sour.p_node_depdt)
            , -- v_model_code_6 || 
              '_' || i_work_no :: varchar   ||
              '_' || tb_a_sour.node_no :: varchar ||
              '____'  -- 'depdt'
            )
        end as p_node_depdt                 
      from sm_sc.tb_nn_node tb_a_sour
      where tb_a_sour.work_no = i_work_no
      on conflict(work_no, node_no) do 
      update set
        node_type                 = EXCLUDED.node_type                    ,
        node_fn_type              = EXCLUDED.node_fn_type                 ,
        node_fn_asso_value        = EXCLUDED.node_fn_asso_value           ,
        nn_depth_no               = EXCLUDED.nn_depth_no                  ,
        node_depdt_vals           = sm_sc.__fv_get_kv(EXCLUDED.p_node_depdt),
        p_node_depdt              
          = case 
              when EXCLUDED.node_type = 'weight' or EXCLUDED.node_fn_type = '00_const' 
              then
                sm_sc.__fv_set_kv
                (
                  sm_sc.__fv_get_kv(EXCLUDED.p_node_depdt)
                , -- v_model_code_6 || 
                  '_' || i_work_no :: varchar   ||
                  '_' || EXCLUDED.node_no :: varchar ||
                  '____'  -- 'depdt'
                ) 
            end
      ;    
      commit;

      -- 以下 upsert 是为了尽量支持训练时也能验证 sess_id = 0 的推理，
      -- 训练全部结束后也会彻底 delete_insert 一份。
      insert into sm_sc.__vt_tmp_nn_node
      (
        sess_id              
      , work_no              
      , node_no              
      , node_type            
      , node_fn_type         
      , node_fn_asso_value   
      , nn_depth_no          
      , p_node_depdt      
      )
      select 
        0                    
      , work_no              
      , node_no              
      , node_type            
      , coalesce(nullif(node_fn_type, '00_buff_slice_rand_pick'), '00_const')  
      , case node_fn_type when '00_buff_slice_rand_pick' then null else node_fn_asso_value end         
      , nn_depth_no                     
      , case 
          -- -- -- when 'prod_input' 
          -- -- --   then i_in
          -- when node_type = 'input_01' 
          --   then i_indepdt_01
          -- when node_type = 'input_02' 
          --   then i_indepdt_02
          -- when node_type = 'input_03' 
          --   then i_indepdt_03
          -- when node_type = 'input_04' 
          --   then i_indepdt_04
          -- -- when 'offset'
          -- --   then array[array[1]]
          when node_type = 'weight' or node_fn_type = '00_const'
            then p_node_depdt -- || '__0'
          else null
        end             
      from sm_sc.__vt_nn_node
      where work_no = i_work_no
      on conflict(sess_id, work_no, node_no) do 
      update set
        node_type                 = EXCLUDED.node_type                    ,
        node_fn_type              = EXCLUDED.node_fn_type                 ,
        node_fn_asso_value        = EXCLUDED.node_fn_asso_value           ,
        nn_depth_no               = EXCLUDED.nn_depth_no                  ,
        p_node_depdt              = EXCLUDED.p_node_depdt
      ;    
      commit;

    end if;
    
    if not i_tensor_log
    then 
      -- 清理 kv 张量: dloss_ddepdt, depdt, ddepdt_dindepdt
      perform 
        sm_sc.__fv_delete_kv
        (
          array_agg(p_node_dloss_ddepdt) || array_agg(p_node_depdt)
        )
      from sm_sc.tb_nn_node 
      where work_no = i_work_no
        and node_type is distinct from 'weight' 
        and node_fn_type is distinct from '00_const'
      ;
      update sm_sc.tb_nn_node
      set 
        p_node_depdt        = null
      , p_node_dloss_ddepdt = null
      where work_no = i_work_no
        and node_type is distinct from 'weight' 
        and node_fn_type is distinct from '00_const'
      ;
      
      perform 
        sm_sc.__fv_delete_kv
        (
          array_agg(p_ddepdt_dindepdt)
        )
      from sm_sc.tb_nn_path 
      where work_no = i_work_no
      ;
      update sm_sc.tb_nn_path 
      set p_ddepdt_dindepdt = null
      where work_no = i_work_no
      ;
      
      -- -- 清理本轮训练该模型有关的所有非 weight 张量 kv
      -- -- 该清理是不必要的，而且也跳过了 get/set 接口，调用了 __vt_array_kv，入侵了 kv 存储，改写会很繁琐
      -- perform 
      --   sm_sc.__fv_delete_kv
      --   (
      --     array_agg(arr_key)
      --   )
      -- from sm_sc.__vt_array_kv tb_a_kv
      -- left join sm_sc.tb_nn_node tb_a_node
      --   on tb_a_node.p_node_depdt = tb_a_kv.arr_key 
      --     and tb_a_node.work_no = i_work_no
      -- where arr_key like (v_model_code_6 || '_' || i_work_no :: varchar || '_%')
      --   and tb_a_node.node_type is distinct from 'weight' 
      --   and tb_a_node.node_fn_type is distinct from '00_const'
      -- ;
    end if;
    
    raise notice 'Training task end report: v_cur_learn_cnt: %; v_cur_loss: %; at %;', v_cur_learn_cnt, v_cur_loss, date_trunc('milliseconds', now());

  end loop;
      
-- debug
raise notice 'Training No. % end; v_cur_loss: %; at %;', v_cur_learn_cnt, v_cur_loss, date_trunc('milliseconds', now());
  
  -- 更新 0 号 sess 部署。规约: 0 号 session 为每轮训练后，默认部署。
  delete from sm_sc.__vt_tmp_nn_node
  where work_no = i_work_no
    and sess_id = 0
  ;
  
  insert into sm_sc.__vt_tmp_nn_node
  (
    sess_id              
  , work_no              
  , node_no              
  , node_type            
  , node_fn_type         
  , node_fn_asso_value   
  , nn_depth_no          
  , p_node_depdt      
  )
  select 
    0                    
  , work_no              
  , node_no              
  , node_type            
  , coalesce(nullif(node_fn_type, '00_buff_slice_rand_pick'), '00_const')  
  , case node_fn_type when '00_buff_slice_rand_pick' then null else node_fn_asso_value end         
  , nn_depth_no                     
  , case 
      -- -- -- when 'prod_input' 
      -- -- --   then i_in
      -- when node_type = 'input_01' 
      --   then i_indepdt_01
      -- when node_type = 'input_02' 
      --   then i_indepdt_02
      -- when node_type = 'input_03' 
      --   then i_indepdt_03
      -- when node_type = 'input_04' 
      --   then i_indepdt_04
      -- -- when 'offset'
      -- --   then array[array[1]]
      when node_type = 'weight' or node_fn_type = '00_const'
        then p_node_depdt -- || '__0'
      else null
    end             
  from sm_sc.__vt_nn_node
  where work_no = i_work_no
  -- on conflict(work_no, node_no) do 
  -- update set
  --   node_type                 = EXCLUDED.node_type                    ,
  --   node_fn_type              = EXCLUDED.node_fn_type                 ,
  --   node_fn_asso_value        = EXCLUDED.node_fn_asso_value           ,
  --   nn_depth_no               = EXCLUDED.nn_depth_no                  ,
  --   p_node_depdt              = EXCLUDED.p_node_depdt
  ;    
  commit;
  
end
$$
language plpgsql;

-- -- 用例 1, 二分类
-- -- -- 执行准备和检查
-- -- call sm_sc.prc_nn_prepare
-- -- (
-- --   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
-- --   2500      -- ,
-- --   -- 200
-- -- );


-- -- 开始训练
-- call sm_sc.prc_nn_train_p
-- (
--   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
--   1        ,
--   0.9      ,
--   0.1
-- );

-- -- -- 观察输出
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- select node_no, node_fn_type, learn_cnt_fore, learn_cnt_back, tb_a.p_node_depdt, (tb_a.reg_w).m_vals  from sm_sc.tb_nn_node tb_a where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- select 
--   sm_sc.ft_nn_in_out
--   (
--     pgv_get('vars', 'this_work_no_02', NULL::bigint), 
--     array[array[0.0, 0.0], array[0.0, 1.0], array[1.0, 0.0], array[1.0, 1.0]] 
--       +` sm_sc.fv_new_randn(0.0, 0.1, array[4, 2])
--   )

-- -- -- 期望用例举例：
-- -- -- select sigmoid(w31 * sigmoid(w11 + w12 * x1 + w13 * x2) + w32 * sigmoid(w21 + w22 * x1 + w23 * x2))
-- -- select sm_sc.fv_sigmoid((-10.0) + (-20.0) * sm_sc.fv_sigmoid((-30.0) + 20.0 * 0 + 20.0 * 0) + 20.0 * sm_sc.fv_sigmoid((-10.0) + 20.0 * 0 + 20.0 * 0)) union all   -- 期望输出，0
-- -- select sm_sc.fv_sigmoid((-10.0) + (-20.0) * sm_sc.fv_sigmoid((-30.0) + 20.0 * 0 + 20.0 * 1) + 20.0 * sm_sc.fv_sigmoid((-10.0) + 20.0 * 0 + 20.0 * 1)) union all   -- 期望输出，1
-- -- select sm_sc.fv_sigmoid((-10.0) + (-20.0) * sm_sc.fv_sigmoid((-30.0) + 20.0 * 1 + 20.0 * 0) + 20.0 * sm_sc.fv_sigmoid((-10.0) + 20.0 * 1 + 20.0 * 0)) union all   -- 期望输出，1
-- -- select sm_sc.fv_sigmoid((-10.0) + (-20.0) * sm_sc.fv_sigmoid((-30.0) + 20.0 * 1 + 20.0 * 1) + 20.0 * sm_sc.fv_sigmoid((-10.0) + 20.0 * 1 + 20.0 * 1))             -- 期望输出，0

-- -- -----------------------------------------------------------------------------
-- -- 用例 2, 多分类
-- -- -- 执行准备和检查
-- -- call sm_sc.prc_nn_prepare
-- -- (
-- --   2021121701   ,
-- --   5000      -- ,
-- --   -- 200
-- -- );
-- 
-- 
-- -- 开始训练
-- call sm_sc.prc_nn_train_p
-- (
--   2021121701   ,
--   2        ,
--   0.8      ,
--   0.1
-- );
-- 
-- -- -- 观察输出
-- select 
--   sm_sc.ft_nn_in_out
--   (
--     2021121701, 
--     array[array[0.0, 0.0, 0.0], array[0.0, 1.0, 0.0], array[1.0, 0.0, 0.0], array[1.0, 1.0, 0.0]
--           , array[0.0, 0.0, 1.0], array[0.0, 1.0, 1.0], array[1.0, 0.0, 1.0], array[1.0, 1.0, 1.0]] 
--       +` sm_sc.fv_new_randn(0.0, 0.1, array[8, 3])
--   )
