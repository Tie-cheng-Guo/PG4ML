-- 参看设计文档 《反向传播链式求导步骤编排》

-- 初始学习率：1e-4
-- https://www.zhihu.com/question/387050717

drop procedure if exists sm_sc.prc_nn_train(bigint, int, float, float, boolean);
create or replace procedure sm_sc.prc_nn_train
(
  i_work_no                          bigint                                   ,      -- 训练任务编号
  i_loss_fn_type                     int                                      ,      -- 损失函数选取类型。1: 最小二乘法; 2: 交叉熵
  i_learn_rate                       float    default    0.0003      ,      -- 学习率
  -- i_grad_descent_batch_cnt           int               default    10000       ,   -- 建议大一些，远远超过 v_i_x, v_i_y 的各维度长度，尽量防止因小批量梯度下降引起的鞍点训练终止 -- 小批量梯度下降，每批记录数
  i_loss_delta_least_stop_threshold  float    default    0.0001      ,      -- 触发收敛的损失函数梯度阈值
  i_is_adam                          boolean           default    false              -- 是否开启 adam 优化
)
as
$$
declare -- here
  v_learn_cnt_init          int               := (select learn_cnt from sm_sc.tb_classify_task where work_no = i_work_no limit 1);   -- 训练次数序号初始值
  v_cur_learn_cnt           int               := v_learn_cnt_init;   -- 训练次数序号
  v_y                       float[]  ; -- -- 训练集本轮采样
  -- -- v_y_train                 float[]  := (select i_y from sm_sc.tb_classify_task where work_no = i_work_no limit 1);  -- -- 训练集全集       -- 2021082501
  -- v_len_x1                  int               := (select array_length(i_x, 1) from sm_sc.tb_classify_task where work_no = i_work_no limit 1);         -- 2021082501
  -- v_len_x2                  int               := (select array_length(i_x, 2) from sm_sc.tb_classify_task where work_no = i_work_no limit 1) + 1;         -- 2021082501
  -- v_len_x1_rand_samp        int               := least(greatest(floor(v_len_x1 / 10), 10000), v_len_x1, 10000);             -- 小批量采样：10000 或 实际样本数量  -- -- --  
  v_cur_node_nos            bigint[];
  v_cur_loss                float;   -- 损失函数值
  v_input_nodes             bigint[]             := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input', 'offset') limit 1);
  v_cur_nn_depth            int               := 0;   -- 深度层数游标
  v_nn_depth                int;                      -- 深度层数
  v_limit_train_times       int               := (select learn_cnt_fore from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input' limit 1);
  v_beta_l1                 float    := 0.9;      -- Adam 梯度下降算法一阶矩等比衰减系数
  v_beta_l2                 float    := 0.999;    -- Adam 梯度下降算法二阶矩等比衰减系数
  
  -- 以下用于将开销大的运算从 cte update 中剥离，做并行改造
  v_cte_x_agg               sm_sc.__typ_cte_x[];
  v_cte_dloss_dx_fore_agg   sm_sc.__typ_cte_dloss_dx_fore[];

begin
  set search_path to public;
  
  -- -- -- 强制开启并行
  -- -- -- select * from pg_settings where name ~ 'paral' or name in ('max_worker_processes') limit 100
  -- -- -- show max_worker_processes
  set min_parallel_table_scan_size = 0;
  set min_parallel_index_scan_size = 0;
  set force_parallel_mode = 'off';
  set max_parallel_workers_per_gather = 64;
  set parallel_setup_cost = 0;
  set parallel_tuple_cost = 0.0;

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

  raise notice 'Training begin; at %', now();

  -- 开始训练
  while 
  (
    v_cur_loss >= i_loss_delta_least_stop_threshold
    or v_cur_loss is null
  )
    and v_cur_learn_cnt < v_limit_train_times
  loop

-- -- -- debug
-- raise notice 'debug 001. step begin: v_cur_learn_cnt: %', v_cur_learn_cnt;

    if exists(select  from sm_sc.tb_nn_node where work_no = i_work_no and node_fn_type = 'buff_slice_rand_pick' and node_type = 'input')
    then
      -- 如果对训练集采用小批量随机采样，那么每轮初始化 input 值，以支持不同轮次更换训练集
      with
      cte_slice_rand_pick as 
      (
        select 
          tb_a_idx.o_ord_no            as a_ord_no            ,
          tb_a_idx.o_slice_rand_pick   as a_slice_rand_pick
        from sm_sc.tb_nn_node tb_a_node,
          sm_sc.ft_nn_buff_slice_rand_pick
          (
            -- 参看 buff_slice_rand_pick 的 node_fn_asso_value 字典表
            i_work_no,
            (
              select 
                array_agg(int4range(tb_a_node.node_fn_asso_value[1][a_ord] :: int, tb_a_node.node_fn_asso_value[2][a_ord] :: int, '[]') order by a_ord)
              from generate_series(1, array_length(tb_a_node.node_fn_asso_value, 2)) tb_a(a_ord)
            ),
            sm_sc.fv_mx_ele_2d_2_1d(tb_a_node.node_fn_asso_value[3 : 3][ : ] :: int[])
          ) tb_a_idx(o_ord_no, o_slice_rand_pick)
        where tb_a_node.work_no = i_work_no
          and tb_a_node.node_type = 'input'
          and tb_a_node.node_fn_type = 'buff_slice_rand_pick'
      ),
      cte_slice_rand_pick_agg as 
      (
        select 
          array_agg(a_ord_no order by a_ord_no)           as a_ord_no,
          array_agg(a_slice_rand_pick order by a_ord_no)  as a_slice_rand_pick
        from cte_slice_rand_pick
      )
      update sm_sc.tb_nn_node tb_a_tar
      set 
        node_y_vals = tb_a_sour.a_slice_rand_pick,   
        pick_y_idx = (select array_agg(int4range(tb_a_sour.a_ord_no[a_ord] :: int, tb_a_sour.a_ord_no[a_ord] :: int, '[]')) from generate_series(1, array_length(tb_a_sour.a_slice_rand_pick, 1)) tb_a(a_ord))
      from cte_slice_rand_pick_agg tb_a_sour
      where tb_a_tar.work_no = i_work_no   -- 2021082501
        and tb_a_tar.node_type = 'input'
        and tb_a_tar.node_fn_type = 'buff_slice_rand_pick'
      ;
      commit;
    elsif exists(select  from sm_sc.tb_nn_node where work_no = i_work_no and node_fn_type = 'const')
    then 
      -- 如果不做小批量随机采样，那么使用训练集全集
      with
      cte_slice_rand_pick as 
      (
        select 
          array_agg(i_x)        as a_x_vals,
          count(*) :: int       as a_x_cnt
        from sm_sc.tb_nn_train_input_buff
        where work_no = i_work_no
      )
      update sm_sc.tb_nn_node tb_a_tar
      set 
        node_y_vals = a_x_vals,   
        pick_y_idx = array[int4range(1, a_x_cnt, '[]')]
      from cte_slice_rand_pick tb_a_sour
      where tb_a_tar.work_no = i_work_no   -- 2021082501
        and tb_a_tar.node_type = 'input'
      ;
      commit;
    end if;

    v_cur_nn_depth := 0;

    -- 前向传播
    v_cur_node_nos := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input', 'offset') limit 1);
    while v_cur_nn_depth <= v_nn_depth
    loop
      v_cur_nn_depth := v_cur_nn_depth + 1;

-- -- -- debug
-- raise notice 'debug 002. step fore begin: v_cur_learn_cnt: %; v_cur_nn_depth: %; v_learn_cnt_init: %;', v_cur_learn_cnt, v_cur_nn_depth, v_learn_cnt_init;


      -- 按照 nn_depth_no，逐层前向传播。初始节点只前向传播一次
      with 
      cte_x as
      (
        select 
          (
            tb_a_fore.node_no, 
            tb_a_fore.node_fn_type,
            case 
              when tb_a_fore.node_fn_type = 'agg_concat_y' 
                then sm_sc.fa_array_concat(tb_a_back.pick_y_idx order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = 'agg_concat_y')
              when tb_a_fore.node_fn_type = 'agg_concat_x' 
                then sm_sc.fa_array_concat(distinct tb_a_back.pick_y_idx) filter(where tb_a_fore.node_fn_type = 'agg_concat_x')
              -- -- -- 几个输出矩阵高宽规格改变的特殊 fn, 规约按照第一目作为输入数据集高度规格
              -- -- when tb_a_fore.node_fn_type in ('conv_2d', 'prod_mx')
              else sm_sc.fa_array_concat(case when tb_a_path.path_ord_no = 1 then tb_a_back.pick_y_idx end) filter(where tb_a_fore.node_fn_type not in ('agg_concat_y', 'agg_concat_x'))
            end, -- -- as pick_y_idx,
            count(tb_a_path.back_node_no), -- -- as fore_cnt,   -- 用于后续单双目判断
            
            -- 聚合后的入参归并结果当作单目运算唯一参数
            -- 另一个同类型的限制是，一个CASE无法阻止其所包含的聚集表达式 的计算...取而代之的是，可以使用 一个WHERE或FILTER子句来首先阻止有问题的输入行到达 一个聚集函数。
            --   http://postgres.cn/docs/12/sql-expressions.html
            -- 对于以下 bi_opr_input_1st, bi_opr_input_2nd, 采用 filter 过滤掉必要的聚合输入，达到减少聚合计算以及入参宽高一致性保证等安全问题
            case 
              when tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new')
                then 
                  sm_sc.fv_lambda_arr
                  (
                    tb_a_fore.node_no, -- --
                    tb_a_fore.node_fn_type,
                    sm_sc.fa_mx_concat_y(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new')),
                    null,
                    sm_sc.fa_mx_concat_y(tb_a_fore.node_fn_asso_value[1 : 1]) filter(where tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new'))
                  )
              when tb_a_fore.node_fn_type = 'agg_concat_y'
                then sm_sc.fa_mx_concat_y(tb_a_back.node_y_vals order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = 'agg_concat_y')
              when tb_a_fore.node_fn_type = 'agg_concat_x'
                then sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type = 'agg_concat_x')
              when tb_a_fore.node_fn_type = 'agg_sum'  -- 求导时，只需要自变量高宽
                then sm_sc.fa_mx_sum(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type = 'agg_sum')
              when tb_a_fore.node_fn_type = 'agg_avg'  -- 求导时，只需要自变量高宽
                then sm_sc.fa_mx_avg(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type = 'agg_avg')
              when tb_a_fore.node_fn_type = 'agg_max'
                then sm_sc.fa_mx_max(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type = 'agg_max') -- -- -- 记录最值所在 path_no 矩阵到协参，可设计 sm_sc.fa_mx_max_ex 的输出为 sm_sc.fa_mx_max_ex 的输出 concat 其位置矩阵
              when tb_a_fore.node_fn_type = 'agg_min'
                then sm_sc.fa_mx_min(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type = 'agg_min') -- -- -- 记录最值所在 path_no 矩阵到协参，可设计 sm_sc.fa_mx_min_ex 的输出为 sm_sc.fa_mx_min_ex 的输出 concat 其位置矩阵
              when tb_a_fore.node_fn_type = 'agg_prod'
                then sm_sc.fa_mx_prod(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type = 'agg_prod')
              when tb_a_fore.node_fn_type not like 'agg_%' and tb_a_fore.node_fn_type not in ('rand_pick_y', 'rand_pick_x', 'new')
                then sm_sc.fa_mx_concat_y(case when tb_a_path.path_ord_no = 1 then tb_a_back.node_y_vals end) filter(where tb_a_fore.node_fn_type not like 'agg_%')
            end -- -- as bi_opr_input_1st
            ,
            case 
              when tb_a_fore.node_fn_type not like 'agg_%' and count(tb_a_path.back_node_no) = 2
                then sm_sc.fa_mx_concat_y(case when tb_a_path.path_ord_no = 2 then tb_a_back.node_y_vals end) filter(where tb_a_fore.node_fn_type not like 'agg_%' and tb_a_fore.node_fn_type not in ('add', 'sub'))
            end -- -- as bi_opr_input_2nd
            ,
            case
              when tb_a_fore.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub')
                then array[array[max(tb_a_fore.node_o_len[1]) filter(where tb_a_fore.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub')), max(tb_a_fore.node_o_len[2]) filter(where tb_a_fore.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub'))]]
              when tb_a_fore.node_fn_type in ('agg_concat_x', 'agg_concat_y')
                then array_agg(tb_a_back.node_o_len order by tb_a_path.path_ord_no) filter(where tb_a_fore.node_fn_type in ('agg_concat_x', 'agg_concat_y'))
              when tb_a_fore.node_fn_type = 'slice_x'   -- 暂不支持多区间切片
                then array[array[max(tb_a_back.node_o_len[1]) filter(where tb_a_fore.node_fn_type = 'slice_x'), max(tb_a_back.node_o_len[2]) filter(where tb_a_fore.node_fn_type = 'slice_x')]]
              when tb_a_fore.node_fn_type = 'slice_y'   -- 暂不支持多区间切片
                then array[array[max(tb_a_back.node_o_len[1]) filter(where tb_a_fore.node_fn_type = 'slice_y'), max(tb_a_back.node_o_len[2]) filter(where tb_a_fore.node_fn_type = 'slice_y')]]
            end -- -- as back_node_os_len
            ,
            -- 审计算子第一入参是否有必要求导，如果其反向节点不参与反向传播，那么不必要
            case 
              when tb_a_fore.node_fn_type not like 'agg_%'
                then (sm_sc.fa_mx_or(case when tb_a_path.path_ord_no = 1 then array[tb_a_back.is_back_node] else array[false] end))[1]
              else true
            end -- -- as is_bi_opr_input_1st_back
            ,
            -- 审计算子第二入参是否有必要求导，如果其反向节点不参与反向传播，那么不必要
            case 
              when tb_a_fore.node_fn_type not like 'agg_%'
                then (sm_sc.fa_mx_or(case when tb_a_path.path_ord_no = 2 then array[tb_a_back.is_back_node] else array[false] end))[1]
              else true
            end -- -- as is_bi_opr_input_2nd_back
            ,
            -- 将开销大的 prod_mx, conv_2d 集中在本 query, 便于并行与分布式改造
            case tb_a_fore.node_fn_type
              -- -- when tb_a_fore.node_fn_type in ('prod_mx', 'conv_2d')
              when 'prod_mx'
                then 
                  sm_sc.fv_lambda_arr
                  (
                    tb_a_fore.node_no,  -- -- 
                    tb_a_fore.node_fn_type,
                    sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 1 and tb_a_fore.node_fn_type = 'prod_mx'),
                    sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 2 and tb_a_fore.node_fn_type = 'prod_mx')
                  )  
                  -- sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 1 and tb_a_fore.node_fn_type = 'prod_mx')
                  -- |**| sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 2 and tb_a_fore.node_fn_type = 'prod_mx')
              when 'conv_2d'
                then 
                  sm_sc.fv_lambda_arr
                  (
                    tb_a_fore.node_no,  -- -- 
                    tb_a_fore.node_fn_type,
                    sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 1 and tb_a_fore.node_fn_type = 'conv_2d'),
                    sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 2 and tb_a_fore.node_fn_type = 'conv_2d'),
                    sm_sc.fa_mx_coalesce(tb_a_fore.node_fn_asso_value)
                  )  
                  -- -- sm_sc.fv_conv_2d_grp_x
                  -- -- (
                  -- --   sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 1 and tb_a_fore.node_fn_type = 'conv_2d'),   
                  -- --   (sm_sc.fa_mx_coalesce(tb_a_fore.node_fn_asso_value))[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
                  -- --   sm_sc.fa_mx_concat_x(tb_a_back.node_y_vals) filter(where tb_a_path.path_ord_no = 2 and tb_a_fore.node_fn_type = 'conv_2d'),   
                  -- --   (sm_sc.fa_mx_coalesce(tb_a_fore.node_fn_asso_value))[3] :: int                                              ,   -- 规约：存放 i_window_len_x 
                  -- --   coalesce((sm_sc.fa_mx_coalesce(tb_a_fore.node_fn_asso_value))[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
                  -- --   coalesce((sm_sc.fa_mx_coalesce(tb_a_fore.node_fn_asso_value))[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
                  -- --   coalesce((sm_sc.fa_mx_coalesce(tb_a_fore.node_fn_asso_value))[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
                  -- -- )
            end -- -- as heavy_cost_lambda
          ) :: sm_sc.__typ_cte_x as a_cte_x
        from sm_sc.tb_nn_node tb_a_fore
        inner join sm_sc.tb_nn_path tb_a_path
          on tb_a_path.work_no = i_work_no   -- 2021082501
            and tb_a_path.fore_node_no = tb_a_fore.node_no
        inner join sm_sc.tb_nn_node tb_a_back
          on tb_a_back.work_no = i_work_no   -- 2021082501
            and tb_a_back.node_no = tb_a_path.back_node_no
        where tb_a_fore.work_no = i_work_no   -- 2021082501
          and tb_a_fore.nn_depth_no = v_cur_nn_depth
          and (tb_a_fore.is_fore_node is true or v_cur_learn_cnt = v_learn_cnt_init)
        group by tb_a_fore.node_no, tb_a_fore.node_fn_type
      )
      select array_agg(a_cte_x) into v_cte_x_agg from cte_x;   -- 把 聚合 cte 分隔出来，用 v_cte_x_agg 寄存，仅为了后续 cte 可以并行
      
      -- -- ,
      -- 前向传播推进一层，算出 yn, dy(n)/dy(n-1), 其中 y(n-1) 即 x
      with 
      cte_x_unnest as 
      (
        select 
          v_cte_x_agg[a_no].m_node_no                    as node_no                       ,
          v_cte_x_agg[a_no].m_node_fn_type               as node_fn_type                  ,
          v_cte_x_agg[a_no].m_pick_y_idx                 as pick_y_idx                    ,
          v_cte_x_agg[a_no].m_fore_cnt                   as fore_cnt                      ,
          v_cte_x_agg[a_no].m_bi_opr_input_1st           as bi_opr_input_1st              ,
          v_cte_x_agg[a_no].m_bi_opr_input_2nd           as bi_opr_input_2nd              ,
          v_cte_x_agg[a_no].m_back_node_os_len           as back_node_os_len              ,
          v_cte_x_agg[a_no].m_is_bi_opr_input_1st_back   as is_bi_opr_input_1st_back      ,
          v_cte_x_agg[a_no].m_is_bi_opr_input_2nd_back   as is_bi_opr_input_2nd_back      ,
          v_cte_x_agg[a_no].m_heavy_cost_lambda          as heavy_cost_lambda
        from generate_series(1, array_length(v_cte_x_agg, 1)) tb_a(a_no)
      )
      ,
      cte_upd_fore_node_y as 
      (
        update sm_sc.tb_nn_node tb_a_tar_y
        set 
          pick_y_idx =
            case tb_a_x_fore.node_fn_type
              when 'slice_y'
                then 
                  sm_sc.fv_idx_samp_by_samp
                  (
                    tb_a_x_fore.pick_y_idx, 
                    array[int4range(tb_a_tar_y.node_fn_asso_value[1] :: int, coalesce(tb_a_tar_y.node_fn_asso_value[2], tb_a_tar_y.node_fn_asso_value[1]) :: int, '[]')]
                  )
              when 'rand_pick_y'
                then 
                  sm_sc.fv_idx_samp_by_samp
                  (
                    tb_a_x_fore.pick_y_idx, 
                    (
                      select array_agg(int4range(a_ele :: int, a_ele :: int, '[]')) 
                      from unnest(tb_a_x_fore.bi_opr_input_1st[ : ][array_length(tb_a_x_fore.bi_opr_input_1st, 2) : ]) tb_a_ele(a_ele)   -- 规约在 fv_lambda_arr 中， rand_pick_y, rand_pick_x 算子的最后一列/行，为 rand 到的切片序号
                    )
                  )
              when 'new'
                then 
                  sm_sc.fv_new(tb_a_x_fore.pick_y_idx, tb_a_tar_y.node_fn_asso_value[1 : 1] :: int[])
              -- -- when 'agg_concat_y'  -- 已经在 cte_x 中聚合处理
              -- --   then tb_a_x_fore.pick_y_idx
              else tb_a_x_fore.pick_y_idx
            end,
          node_y_vals = 
            case        
              -- 聚合已经在 cte_x 中，计算出来
              when tb_a_x_fore.node_fn_type = 'rand_pick_y'
                then tb_a_x_fore.bi_opr_input_1st[ : ][ : array_length(tb_a_x_fore.bi_opr_input_1st, 2) - 1]
              when tb_a_x_fore.node_fn_type = 'rand_pick_x'
                then tb_a_x_fore.bi_opr_input_1st[ : array_length(tb_a_x_fore.bi_opr_input_1st, 1) - 1][ : ]
              -- -- when tb_a_x_fore.node_fn_type = 'new'
              -- --   then ...
              -- -- when tb_a_x_fore.fore_cnt = 2 and tb_a_tar_y.node_fn_type = 'prod_mx'
              -- --   -- -- -- 鉴于 x 来自海量数据样本，会是个高表，所以采用 x ** w 形式计算，而不是 w转置 ** x转置 的转置
              -- --   then tb_a_x_fore.bi_opr_input_1st |**| tb_a_x_fore.bi_opr_input_2nd
              when tb_a_x_fore.node_fn_type like 'agg_%'
                then tb_a_x_fore.bi_opr_input_1st
              -- 其他单目、双目运算，则调用 lambda
              when tb_a_x_fore.node_fn_type in ('prod_mx', 'conv_2d')
                then tb_a_x_fore.heavy_cost_lambda
              else 
                sm_sc.fv_lambda_arr
                (
                  tb_a_x_fore.node_no,  -- -- 
                  tb_a_tar_y.node_fn_type,
                  tb_a_x_fore.bi_opr_input_1st,
                  tb_a_x_fore.bi_opr_input_2nd,
                  tb_a_tar_y.node_fn_asso_value
                )  
            end
          ,
          node_fn_asso_value = 
            -- 参看 node_fn_asso_value 字典表
            case 
              when tb_a_tar_y.node_fn_type in ('agg_concat_x', 'agg_concat_y')
                then tb_a_x_fore.back_node_os_len
              when tb_a_tar_y.node_fn_type = 'rand_pick_y'
                then tb_a_tar_y.node_fn_asso_value[1 : 1] || sm_sc.fv_mx_ele_2d_2_1d(tb_a_x_fore.bi_opr_input_1st[ : ][array_length(tb_a_x_fore.bi_opr_input_1st, 2) : ])
              when tb_a_tar_y.node_fn_type = 'rand_pick_x'
                then tb_a_tar_y.node_fn_asso_value[1 : 1] || sm_sc.fv_mx_ele_2d_2_1d(tb_a_x_fore.bi_opr_input_1st[array_length(tb_a_x_fore.bi_opr_input_1st, 1) : ][ : ])
              else tb_a_tar_y.node_fn_asso_value
            end
          ,
          learn_cnt_fore = v_cur_learn_cnt + 1  -- 强制对齐训练次数，避免路径跟踪混乱   -- tb_a_tar_y.learn_cnt_fore + 1
        from cte_x_unnest tb_a_x_fore -- -- cte_x tb_a_x_fore
        where tb_a_tar_y.work_no = i_work_no   -- 2021082501
          and tb_a_x_fore.node_no = tb_a_tar_y.node_no
        returning tb_a_tar_y.node_no as a_cur_node_no
      )
      ,
      cte_upd_path as 
      (
        update sm_sc.tb_nn_path tb_a_tar_path
        set 
          dy_dx =
            -- 矩阵乘法，jacobian 矩阵  https://baike.baidu.com/item/%E9%9B%85%E5%8F%AF%E6%AF%94%E7%9F%A9%E9%98%B5/10753754?fr=aladdin
            -- https://zhuanlan.zhihu.com/p/24709748
            -- https://zhuanlan.zhihu.com/p/24863977
            -- -- 反向传播四个基本公式
            -- https://www.cnblogs.com/softlin/p/11228883.html
            -- https://zhuanlan.zhihu.com/p/37916911
            case 
              when is_bi_opr_input_1st_back and tb_a_tar_path.path_ord_no = 1  -- -- tb_a_tar_y.is_back_node is true
                then 
                  case
                    -- -- -- 注释掉矩阵乘法的 dy_dx where path_ord_no = 1, 减少落盘IO开销，追求低复制。
                    when tb_a_y.node_fn_type = 'prod_mx'
                      -- 矩阵乘法求导 http://blog.sina.com.cn/s/blog_51c4baac0100xuww.html
                      then tb_a_x_fore.bi_opr_input_2nd
                    when tb_a_y.node_fn_type in ('conv_2d')
                      then tb_a_x_fore.bi_opr_input_2nd   -- 此时非真实 node_o.m_dy_d1st, 仅是寄存 bi_opr_input_2nd, 对自变量，因变量都敏感的两个算子的第二个
                    -- 以下几类算子，在下一个 commit 中利用输出的 y 值计算，降低开销，包括：'sigmoid', 'exp', 'tanh', 'pow', 'log'；而 'softmax_x', 'zscore_x' 的梯度依赖于真实值；, 'agg_concat_x', 'agg_concat_y', 'rand_pick_x', 'rand_pick_y', 'new' 依赖于序号，在反向传播才能计算
                    when tb_a_y.node_fn_type in ('sigmoid', 'exp', 'tanh', 'pool_avg', 'softmax_x', 'zscore_x', 'agg_concat_x', 'agg_concat_y', 'rand_pick_x', 'rand_pick_y', 'new')
                      then null
                    when tb_a_y.node_fn_type in ('pow', 'log', 'pool_max', 'agg_max', 'agg_min', 'agg_prod')
                      then tb_a_x_fore.bi_opr_input_1st   -- 此时非真实 dy_dx where path_ord_no = 1, 仅是寄存 bi_opr_input_1st
                    when tb_a_y.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub', 'slice_x', 'slice_y')
                      then 
                        sm_sc.fv_lambda_arr_delta
                        (
                          tb_a_x_fore.node_no,  -- -- 
                          tb_a_y.node_fn_type         ,
                          null    ,
                          1                             ,
                          null    ,
                          tb_a_y.node_fn_asso_value ,   -- null
                          null,
                          -- null,
                          array[back_node_os_len[1][1], back_node_os_len[1][2]]
                        )
                    else
                      sm_sc.fv_lambda_arr_delta
                      (
                        tb_a_x_fore.node_no,  -- -- 
                        tb_a_y.node_fn_type         ,
                        tb_a_x_fore.bi_opr_input_1st    ,
                        1                             ,
                        tb_a_x_fore.bi_opr_input_2nd    ,
                        tb_a_y.node_fn_asso_value 
                      )
                  end
              when is_bi_opr_input_2nd_back  and tb_a_tar_path.path_ord_no = 2
                then 
                  case 
                    when tb_a_y.node_fn_type = 'prod_mx'   -- tb_a_y.initial_label <> 1
                      -- 矩阵乘法求导 http://blog.sina.com.cn/s/blog_51c4baac0100xuww.html
                      -- -- then 
                      -- --   sm_sc.fv_lambda_arr_delta
                      -- --   (
                      -- --     tb_a_x_fore.node_no,  -- -- 
                      -- --     tb_a_y.node_fn_type           ,
                      -- --     null                          ,
                      -- --     2                             ,
                      -- --     tb_a_x_fore.bi_opr_input_1st
                      -- --   )
                      then |^~| tb_a_x_fore.bi_opr_input_1st
                    when tb_a_y.node_fn_type = 'conv_2d'
                      then tb_a_x_fore.bi_opr_input_1st   -- 此时非真实 dy_dx where path_ord_no = 1, 仅是寄存 bi_opr_input_1st, 对自变量，因变量都敏感的两个算子的第二个
                    when tb_a_y.node_fn_type in ('pow', 'log')   -- tb_a_y.initial_label <> 1
                      then tb_a_x_fore.bi_opr_input_2nd   -- 此时非真实 dy_dx where path_ord_no = 2, 仅是寄存 bi_opr_input_2nd, 对自变量，因变量都敏感的两个算子的第二个：pow, log
                    when tb_a_y.node_fn_type in ('add', 'sub')
                      then 
                        sm_sc.fv_lambda_arr_delta
                        (
                          tb_a_x_fore.node_no,  -- -- 
                          tb_a_y.node_fn_type         ,
                          null    ,
                          2                             ,
                          null    ,
                          tb_a_y.node_fn_asso_value ,   -- null
                          null,
                          -- null,
                          array[back_node_os_len[1][1], back_node_os_len[1][2]]
                        )
                    when tb_a_y.node_fn_type not like 'agg_%' and fore_cnt = 2 and tb_a_y.node_fn_type not in ('pow', 'log', 'conv_2d', 'prod_mx', 'add', 'sub')   -- tb_a_y.initial_label <> 1
                      then 
                        sm_sc.fv_lambda_arr_delta
                        (
                          tb_a_x_fore.node_no,  -- -- 
                          tb_a_y.node_fn_type                   ,
                          tb_a_x_fore.bi_opr_input_2nd              ,
                          2                                       ,
                          tb_a_x_fore.bi_opr_input_1st              
                        )
                    else null
                  end
            end
        from cte_x_unnest tb_a_x_fore -- -- cte_x tb_a_x_fore
          , sm_sc.tb_nn_node tb_a_y
        where tb_a_y.work_no = i_work_no   -- 2021082501
          and tb_a_y.node_no = tb_a_x_fore.node_no
          and tb_a_tar_path.work_no = i_work_no   -- 2021082501
          and tb_a_tar_path.fore_node_no = tb_a_x_fore.node_no
      )
      select 
        array_agg(a_cur_node_no) into v_cur_node_nos
      from cte_upd_fore_node_y
      ;      
      commit;

      -- 前向传播之后计算中间导数
      update sm_sc.tb_nn_path tb_a_path_tar
      set 
        dy_dx =
          case 
            when node_fn_type in ('agg_max', 'agg_min', 'agg_prod')
              then 
                sm_sc.fv_lambda_arr_delta
                (
                  tb_a_y.work_no, -- -- 
                  tb_a_y.node_fn_type                     ,
                  tb_a_path_tar.dy_dx                , -- -- (tb_a_y.node_o).m_dy_d1st[ : ][1 : 1]
                  1                                       ,
                  null                                    , -- -- (tb_a_y.node_o).m_dy_d1st[ : ][2 : 2] ,
                  null                                    ,
                  tb_a_y.node_y_vals
                )
            when node_fn_type in ('sigmoid', 'exp', 'tanh') -- and tb_a_path_tar.path_ord_no = 1
              then 
                sm_sc.fv_lambda_arr_delta
                (
                  tb_a_y.work_no, -- -- 
                  tb_a_y.node_fn_type            ,
                  null                          ,   -- -- tb_a_x_fore.bi_opr_input_1st          ,
                  null                          ,
                  null                          ,
                  null                          ,
                  tb_a_y.node_y_vals
                )
          end
      from sm_sc.tb_nn_node tb_a_y
      where tb_a_y.work_no = i_work_no   -- 2021082501
        and tb_a_y.node_no = any(v_cur_node_nos)
        and tb_a_y.node_fn_type in ('sigmoid', 'exp', 'tanh', 'agg_max', 'agg_min', 'agg_prod')
        and tb_a_y.is_back_node is true
        and tb_a_path_tar.work_no = i_work_no
        and tb_a_path_tar.fore_node_no = tb_a_y.node_no
      ;
      commit;

      update sm_sc.tb_nn_path tb_a_path_tar
      set 
        dy_dx =
          case 
            when tb_a_path_tar.path_ord_no = 1 -- and node_fn_type in ('pow', 'log')
              then 
                sm_sc.fv_lambda_arr_delta
                (
                  tb_a_y.work_no, -- -- 
                  tb_a_y.node_fn_type                     ,
                  tb_a_path_tar.dy_dx                     , -- -- (tb_a_y.node_o).m_dy_d1st[ : ][1 : 1]
                  tb_a_path_tar.path_ord_no               ,
                  null                                    , -- -- (tb_a_y.node_o).m_dy_d1st[ : ][2 : 2] ,
                  null                                    ,
                  tb_a_y.node_y_vals
                )
            when node_fn_type = 'pow' and tb_a_path_tar.path_ord_no = 2
              then 
                sm_sc.fv_lambda_arr_delta
                (
                  tb_a_y.work_no, -- -- 
                  tb_a_y.node_fn_type                     ,
                  tb_a_path_tar.dy_dx                     ,
                  tb_a_path_tar.path_ord_no               ,
                  tb_a_path_asso.dy_dx                    ,
                  null                                    ,
                  tb_a_y.node_y_vals
                )
            when node_fn_type = 'log' and tb_a_path_tar.path_ord_no = 2
              then 
                sm_sc.fv_lambda_arr_delta
                (
                  tb_a_y.work_no                          ,
                  tb_a_y.node_fn_type                     ,
                  tb_a_path_tar.dy_dx                     ,
                  tb_a_path_tar.path_ord_no               ,
                  tb_a_path_asso.dy_dx 
                )
          end
      from sm_sc.tb_nn_node tb_a_y, sm_sc.tb_nn_path tb_a_path_asso
      where tb_a_y.work_no = i_work_no   -- 2021082501
        and tb_a_y.node_no = any(v_cur_node_nos)
        and tb_a_y.node_fn_type in ('pow', 'log')
        and tb_a_y.is_back_node is true    -- tb_a_y.initial_label <> 1
        and tb_a_path_tar.work_no = i_work_no
        and tb_a_path_tar.fore_node_no = tb_a_y.node_no
        and tb_a_path_asso.work_no = i_work_no
        and tb_a_path_asso.fore_node_no = tb_a_y.node_no
        and tb_a_path_asso.path_ord_no = case tb_a_path_tar.path_ord_no when 1 then 2 when 2 then 1 end
      ;
      commit;

-- -- -- debug
-- raise notice 'debug 003. step fore end: v_cur_learn_cnt: %; v_cur_node_nos: %; v_cur_nn_depth: %', v_cur_learn_cnt, v_cur_node_nos, v_cur_nn_depth;

    end loop;

    -- 对 i_y 小批量抽样，获得本轮 v_y
    v_y := 
      (
        select 
          array_agg(tb_a_buff.i_y order by tb_a_idx.a_idx, tb_a_buff.ord_no)
        from sm_sc.tb_nn_node tb_a_sour
        cross join generate_series(1, array_length(tb_a_sour.pick_y_idx, 1)) tb_a_idx(a_idx)
        inner join sm_sc.tb_nn_train_input_buff tb_a_buff
          on tb_a_buff.ord_no <@ (tb_a_sour.pick_y_idx[tb_a_idx.a_idx])
        where tb_a_sour.work_no = i_work_no
          and tb_a_sour.node_type = 'output'
          and tb_a_buff.work_no = i_work_no
      )
    ;

    -- 损失函数
    select 
      sm_sc.fv_loss(i_loss_fn_type, t_a_tar.node_y_vals, v_y) into v_cur_loss
    from sm_sc.tb_nn_node t_a_tar 
    where node_type = 'output'    -- 规约：每个 work_no 全局的 input, output 节点各只有一个
      and work_no = i_work_no     -- 2021082501
    ;

-- -- -- debug
-- raise notice 'debug 004. step fore end: len of v_y: %; v_cur_loss: %;', array[array_length(v_y, 1), array_length(v_y, 2)], v_cur_loss;

    -- 反向传播
    -- 反向传播起点：全局损失函数对输出 z 求导(均方差、最小二乘法)
    -- 规约：node_type = 'output' 只有一个
    update sm_sc.tb_nn_node t_a_tar
    set 
      node_dloss_dy = sm_sc.fv_dloss_dz(i_loss_fn_type, t_a_tar.node_y_vals, v_y),
      learn_cnt_back = v_cur_learn_cnt + 1 -- 强制对齐训练次数，避免路径计算混乱    -- t_tar.learn_cnt_back + 1
    where node_type = 'output'
      and work_no = i_work_no   -- 2021082501
    ;
    commit;

-- -- -- debug
-- raise notice 'debug 005. step fore end: v_cur_learn_cnt: %;', v_cur_learn_cnt;

    v_cur_nn_depth := v_nn_depth;
    v_cur_node_nos := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output' limit 1);
    while 
      exists 
      (
        select         
        from sm_sc.tb_nn_node tb_a_back
        where tb_a_back.work_no = i_work_no    -- 2021082501
          and tb_a_back.learn_cnt_back <= v_cur_learn_cnt
          and tb_a_back.is_back_node is true
        limit 1
      )
      and v_cur_nn_depth >= 1
    loop

-- -- -- debug
-- raise notice 'debug 006. step back begin: v_cur_learn_cnt: %; v_cur_node_nos: %; v_cur_nn_depth: %;', v_cur_learn_cnt, v_cur_node_nos, v_cur_nn_depth;

      -- m_dloss_d1st, m_dloss_d2nd 计算存放的是，loss 对给节点所有输入汇总出来的 1_p 或 2_p 的导数。传递给反向节点时，要根据算子性质、path_ord_no，对 m_dloss_d1st 做分发。
      -- 对于 conv_2d, pool_max, pool_avg, softmax, zscore，函数 sm_sc.fv_lambda_arr_delta 求取 dloss/dindepdt, 而不是求取 ddepdt/dindepdt
      with 
      cte_dloss_dx_fore as
      (      
        select 
          (
            tb_a_fore.node_no,
            tb_a_fore.node_fn_type,
            -- 链式求导
            case 
              when tb_a_fore.node_fn_type in ('agg_max', 'agg_min', 'agg_prod', 'softmax_x', 'zscore_x', 'agg_concat_x', 'agg_concat_y')
                then tb_a_fore.node_dloss_dy
              when tb_a_fore.node_fn_type = 'prod_mx' and tb_a_back_p1.is_back_node
                then -- tb_a_fore.node_dloss_dy |**| (|^~| tb_a_path_p1.dy_dx)
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                ,
                    null                                ,   -- tb_a_x_fore.bi_opr_input_1st    ,
                    1                                   ,
                    null          ,
                    null           ,
                    null                                ,   -- tb_a_fore.node_y_vals              ,
                    tb_a_fore.node_dloss_dy     ,
                    tb_a_path_p1.dy_dx          
                  )    
              when tb_a_fore.node_fn_type = 'conv_2d' and tb_a_back_p1.is_back_node
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                ,
                    null                                ,   -- tb_a_x_fore.bi_opr_input_1st    ,
                    1                                   ,
                    null          ,
                    tb_a_fore.node_fn_asso_value     ,
                    null                                ,   -- tb_a_fore.node_y_vals              ,
                    tb_a_fore.node_dloss_dy     ,
                    tb_a_path_p1.dy_dx          
                  )            
              when tb_a_fore.node_fn_type = 'pool_max' and tb_a_back_p1.is_back_node
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                     ,
                    tb_a_path_p1.dy_dx               , -- 此时非真实 tb_a_path_p1.dy_dx, 仅是寄存 bi_opr_input_1st
                    1                                        ,
                    null                                     , 
                    tb_a_fore.node_fn_asso_value          ,
                    tb_a_fore.node_y_vals                  ,
                    tb_a_fore.node_dloss_dy
                  )
              when tb_a_fore.node_fn_type = 'pool_avg' and tb_a_back_p1.is_back_node
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                     ,
                    null                                     ,
                    1                                        ,
                    null                                     , 
                    tb_a_fore.node_fn_asso_value          ,
                    tb_a_fore.node_y_vals                  ,
                    tb_a_fore.node_dloss_dy
                  )
              when tb_a_fore.node_fn_type = 'agg_avg' and tb_a_back_p1.is_back_node
                then 
                  sm_sc.fv_lambda_arr_delta
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type            ,
                    tb_a_path_p1.dy_dx       ,-- 此时非真实 tb_a_path_p1.dy_dx, 仅是寄存 bi_opr_input_1st
                    1                             ,
                    null                          ,
                    array[tb_a_fore.node_o_len :: float[]] -- -- tb_a_fore.node_fn_asso_value 
                  )
              when tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new') and tb_a_back_p1.is_back_node
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                     ,
                    null                                     ,
                    1                                        ,
                    null                                     ,
                    tb_a_fore.node_fn_asso_value          ,
                    null                                     ,
                    tb_a_fore.node_dloss_dy
                  )
              else case when tb_a_back_p1.is_back_node then tb_a_fore.node_dloss_dy *` tb_a_path_p1.dy_dx else null end
            end
              , -- -- as a_dloss_dx_fore_1st,
            case
              when tb_a_fore.node_fn_type = 'prod_mx' and tb_a_back_p2.is_back_node
                then -- tb_a_path_p2.dy_dx |**| tb_a_fore.node_dloss_dy
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                ,
                    null                                ,
                    2                                   ,
                    null           ,
                    null           ,
                    null                                ,
                    tb_a_fore.node_dloss_dy      ,
                    tb_a_path_p2.dy_dx         
                  )
              when tb_a_fore.node_fn_type = 'conv_2d' and tb_a_back_p2.is_back_node
                then
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type                ,
                    null                                ,
                    2                                   ,
                    null           ,
                    tb_a_fore.node_fn_asso_value     ,
                    null                                ,
                    tb_a_fore.node_dloss_dy      ,
                    tb_a_path_p2.dy_dx         
                  )
              when tb_a_fore.node_fn_type in ('agg_concat_y', 'agg_concat_x', 'rand_pick_y', 'rand_pick_x', 'new')
                then null  -- 临时置空，下一个 cte 计算
              else case when tb_a_back_p2.is_back_node then tb_a_fore.node_dloss_dy *` tb_a_path_p2.dy_dx else null end
            end
              ,-- -- as a_dloss_dx_fore_2nd,
            tb_a_fore.node_fn_asso_value,
            case when tb_a_fore.node_fn_type in ('agg_max', 'agg_min', 'agg_prod', 'zscore_x', 'softmax_x') then tb_a_fore.node_y_vals end -- -- as node_o_m_vals
          ) :: sm_sc.__typ_cte_dloss_dx_fore as a_cte_dloss_dx_fore
        from sm_sc.tb_nn_node tb_a_fore
        left join sm_sc.tb_nn_path tb_a_path_p1
          on tb_a_path_p1.fore_node_no = tb_a_fore.node_no 
            and tb_a_path_p1.path_ord_no = 1
            and tb_a_path_p1.work_no = i_work_no   -- 2021082501
        left join sm_sc.tb_nn_node tb_a_back_p1
          on tb_a_back_p1.node_no = tb_a_path_p1.back_node_no
            and tb_a_back_p1.work_no = i_work_no   -- 2021082501
        left join sm_sc.tb_nn_path tb_a_path_p2
          on tb_a_path_p2.fore_node_no = tb_a_fore.node_no 
            and tb_a_path_p2.path_ord_no = 2
            and tb_a_path_p2.work_no = i_work_no   -- 2021082501
        left join sm_sc.tb_nn_node tb_a_back_p2
          on tb_a_back_p2.node_no = tb_a_path_p2.back_node_no
            and tb_a_back_p2.work_no = i_work_no   -- 2021082501
        where tb_a_fore.work_no = i_work_no   -- 2021082501
          and tb_a_fore.nn_depth_no = v_cur_nn_depth
          and tb_a_fore.is_back_node
      )
      select array_agg(a_cte_dloss_dx_fore) into v_cte_dloss_dx_fore_agg from cte_dloss_dx_fore
      ;
      -- -- ,
      -- 用多步 cte 改造 aggr，后续步骤再实现矩阵乘法，避免矩阵乘法重复执行
      with 
      cte_dloss_dx_fore_unnest as 
      (
        select 
          v_cte_dloss_dx_fore_agg[a_no].m_node_no                   as node_no                   ,
          v_cte_dloss_dx_fore_agg[a_no].m_node_fn_type              as node_fn_type              ,
          v_cte_dloss_dx_fore_agg[a_no].m_a_dloss_dx_fore_1st       as a_dloss_dx_fore_1st       ,
          v_cte_dloss_dx_fore_agg[a_no].m_a_dloss_dx_fore_2nd       as a_dloss_dx_fore_2nd       ,
          v_cte_dloss_dx_fore_agg[a_no].m_node_fn_asso_value   as node_fn_asso_value   ,
          v_cte_dloss_dx_fore_agg[a_no].m_node_o_m_vals             as node_o_m_vals 
        from generate_series(1, array_length(v_cte_dloss_dx_fore_agg, 1)) tb_a(a_no)
      )
      ,
      cte_dloss_dx as
      (
        select 
          tb_a_back.node_no,
          -- sm_sc.fa_mx_sum(tb_a_fore.a_dloss_dx_fore_1st[ : ][tb_a_path.path_ord_no : tb_a_path.path_ord_no]) as a_dloss_dx
          sm_sc.fa_mx_sum
          (
            case 
              when tb_a_fore.node_fn_type = 'softmax_x'
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type, 
                    null, 
                    null, 
                    null, 
                    null, 
                    tb_a_fore.node_o_m_vals, 
                    tb_a_fore.a_dloss_dx_fore_1st
                  )
              when tb_a_fore.node_fn_type = 'zscore_x'
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type, 
                    tb_a_back.node_y_vals, 
                    null, 
                    null, 
                    null, 
                    tb_a_fore.node_o_m_vals, 
                    tb_a_fore.a_dloss_dx_fore_1st
                  )
              when tb_a_fore.node_fn_type in ('agg_concat_x', 'agg_concat_y') 
                then 
                  sm_sc.fv_lambda_arr_dloss_dindepdt
                  (
                    tb_a_fore.node_no,   -- -- 
                    tb_a_fore.node_fn_type, 
                    null,
                    tb_a_path.path_ord_no,
                    null,
                    tb_a_fore.node_fn_asso_value,    --  寄存 indepdt_var_len
                    null,
                    tb_a_fore.a_dloss_dx_fore_1st
                  )
              when tb_a_fore.node_fn_type in ('agg_sum', 'agg_avg')
                then tb_a_fore.a_dloss_dx_fore_1st
              -- 聚合 max, min 的梯度不稳定，可能不是凸函数，慎用
              when tb_a_fore.node_fn_type in ('agg_prod', 'agg_max', 'agg_min')
                then 
                  tb_a_fore.a_dloss_dx_fore_1st 
                  *` sm_sc.fv_lambda_arr_delta
                     (
                       tb_a_fore.node_no,   -- -- 
                       tb_a_fore.node_fn_type, 
                       tb_a_back.node_y_vals, 
                       null, 
                       null, 
                       null, 
                       tb_a_fore.node_o_m_vals
                     )
              else 
                case tb_a_path.path_ord_no 
                  when 1 
                    then tb_a_fore.a_dloss_dx_fore_1st 
                  when 2 
                    then tb_a_fore.a_dloss_dx_fore_2nd 
                end
            end
          ) as a_dloss_dx
        from sm_sc.tb_nn_node tb_a_back
        inner join sm_sc.tb_nn_path tb_a_path
          on tb_a_path.back_node_no = tb_a_back.node_no
      	  and tb_a_path.work_no = i_work_no   -- 2021082501
        inner join cte_dloss_dx_fore_unnest tb_a_fore  -- -- cte_dloss_dx_fore tb_a_fore
          on tb_a_fore.node_no = tb_a_path.fore_node_no
        where tb_a_back.work_no = i_work_no   -- 2021082501
          and tb_a_back.nn_depth_no = v_cur_nn_depth - 1
          and tb_a_back.is_back_node
        group by tb_a_back.node_no
      ),
      cte_upd_node as
      (
        update sm_sc.tb_nn_node t_tar
        set 
          node_dloss_dy = t_sour.a_dloss_dx,
          learn_cnt_back = v_cur_learn_cnt + 1 -- 强制对齐训练次数，避免路径计算混乱    -- t_tar.learn_cnt_back + 1
        from cte_dloss_dx t_sour
        where t_sour.node_no = t_tar.node_no
        returning t_tar.node_no as a_cur_node_no
      )
      select 
        array_agg(a_cur_node_no) into v_cur_node_nos
      from cte_upd_node
      ;
      commit;

      v_cur_nn_depth := v_cur_nn_depth - 1;

-- -- -- debug
-- raise notice 'debug 007. step back end: v_cur_learn_cnt: %; v_cur_node_nos: %; v_cur_nn_depth: %;', v_cur_learn_cnt, v_cur_node_nos, v_cur_nn_depth;

    end loop;

    -- 更新 w 参数，一次训练完成
    if not i_is_adam
    then 
      update sm_sc.tb_nn_node tar
      set 
        node_y_vals = tar.node_y_vals -` (i_learn_rate *` tar.node_dloss_dy)
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
      ;
      commit;

    else
      -- 采用 Adam 梯度下降算法
      update sm_sc.tb_nn_node tar
      set 
        -- node_y_vals = tar.node_y_vals -` (i_learn_rate *` tar.node_dloss_dy)
        cost_delta_l1 = (v_beta_l1 *` coalesce(case when array_length(cost_delta_l1, 1) = array_length(tar.node_dloss_dy, 1) then cost_delta_l1 else null end, tar.node_dloss_dy)) +` ((1.0 :: float - v_beta_l1) *` tar.node_dloss_dy),
        cost_delta_l2 = (v_beta_l2 *` coalesce(case when array_length(cost_delta_l2, 1) = array_length(tar.node_dloss_dy, 1) then cost_delta_l2 else null end, (tar.node_dloss_dy ^` 2.0 :: float))) +` ((1.0 :: float - v_beta_l2) *` (tar.node_dloss_dy ^` 2.0 :: float))
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
      ;
      commit;
      
      update sm_sc.tb_nn_node tar
      set 
        node_y_vals =
          tar.node_y_vals -`
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
                , 1e-128 :: float   -- 1e-128 :: float        -- -- -- 全局 eps = 1e-128 :: float
              )
            )
          )
      where work_no = i_work_no   -- 2021082501
        and node_type = 'weight'
      ;
      commit;
    end if;

    v_cur_learn_cnt := v_cur_learn_cnt + 1;

    -- 寄存至 sm_sc.tb_classify_task
    if v_cur_learn_cnt % 1 = 0     -- 或者 100 次， 1000 次， 10000次。。。
      or v_cur_learn_cnt >= v_limit_train_times
      or v_cur_loss < i_loss_delta_least_stop_threshold
    then 
      insert into sm_sc.tb_classify_task
      (
        work_no, 
        learn_cnt , 
        loss_delta
      )
      select 
        i_work_no, 
        v_cur_learn_cnt, 
        v_cur_loss
      on conflict(work_no) do 
      update set
        learn_cnt = v_cur_learn_cnt,
        loss_delta = v_cur_loss
      ;

      insert into sm_sc.__vt_nn_node
      (
        work_no                      ,
        node_no                  ,        
        node_type                    ,
        node_fn_type                 ,
        node_fn_asso_value      ,
        nn_depth_no                  ,
        node_y_vals                  
      )
      select 
        tb_a_sour.work_no                      ,
        tb_a_sour.node_no                  ,        
        tb_a_sour.node_type                    ,
        tb_a_sour.node_fn_type                 ,
        tb_a_sour.node_fn_asso_value      ,
        tb_a_sour.nn_depth_no                  ,
        case when tb_a_sour.node_type = 'weight' then tb_a_sour.node_y_vals end as node_y_vals                 
      from sm_sc.tb_nn_node tb_a_sour
      where tb_a_sour.work_no = i_work_no
      on conflict(work_no, node_no) do 
      update set
        node_type                 = EXCLUDED.node_type                   ,
        node_fn_type              = EXCLUDED.node_fn_type                ,
        node_fn_asso_value        = EXCLUDED.node_fn_asso_value          ,
        nn_depth_no               = EXCLUDED.nn_depth_no                 ,
        node_y_vals                 = case when EXCLUDED.node_type = 'weight' then EXCLUDED.node_y_vals end
      ;    
      commit;
      
      -- -- 谨慎开启 vacuum。如果可能有其他训练任务同时进行，那么会被 vacuum 阻塞
      -- vacuum full sm_sc.tb_nn_node;
      -- vacuum full sm_sc.tb_nn_path;
      -- vacuum full sm_sc.__vt_nn_node;

-- debug
raise notice 'debug 008. step end: v_cur_learn_cnt: %; v_cur_loss: %; at %;', v_cur_learn_cnt, v_cur_loss, now();

    end if;
  end loop;

  raise notice 'Training end report: v_cur_learn_cnt: %; v_cur_loss: %; at %;', v_cur_learn_cnt, v_cur_loss, now();

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
-- call sm_sc.prc_nn_train
-- (
--   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
--   1        ,
--   0.9      ,
--   0.1
-- );

-- -- -- 观察输出
-- select * from sm_sc.tb_classify_task where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- select node_no, node_fn_type, learn_cnt_fore, learn_cnt_back, tb_a.node_y_vals, (tb_a.reg_w).m_vals  from sm_sc.tb_nn_node tb_a where work_no = pgv_get('vars', 'this_work_no_02', NULL::bigint)
-- select 
--   sm_sc.fv_nn_in_out
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
-- call sm_sc.prc_nn_train
-- (
--   2021121701   ,
--   2        ,
--   0.8      ,
--   0.1
-- );
-- 
-- -- -- 观察输出
-- select 
--   sm_sc.fv_nn_in_out
--   (
--     2021121701, 
--     array[array[0.0, 0.0, 0.0], array[0.0, 1.0, 0.0], array[1.0, 0.0, 0.0], array[1.0, 1.0, 0.0]
--           , array[0.0, 0.0, 1.0], array[0.0, 1.0, 1.0], array[1.0, 0.0, 1.0], array[1.0, 1.0, 1.0]] 
--       +` sm_sc.fv_new_randn(0.0, 0.1, array[8, 3])
--   )
