drop procedure if exists sm_sc.prc_nn_prepare(bigint, int, int[], int4range[]);
create or replace procedure sm_sc.prc_nn_prepare
(
  i_work_no                          bigint                      -- 训练任务编号
, i_limit_train_times                int                         -- 规划的训练总次数
, i_batch_amt_per_range              int[]       default null    -- 每次训练在每个训练集区间选取小批量的数量。
                                                                 -- 要么 array_length(i_batch_amt_per_range, 1) = array_length(i_batch_range, 1), 要么 array_length(i_batch_amt_per_range, 1) = 1
                                                                 -- 如果 array_length(i_batch_amt_per_range, 1) = 1，那么所有区间选取数量相同，当次训练选取训练集数据总数量:  i_batch_amt * array_length(i_batch_range, 1)
                                                                 -- 如果 i_batch_amt_per_range, i_batch_range 都是 null，那么继承 00_buff_slice_rand_pick 既有的配置。
, i_batch_range                      int4range[] default null    -- 训练集选取区间策略
)
as
$$
declare -- here
  v_cur_learn_cnt          bigint               := (select learn_cnt from sm_sc.tb_classify_task where work_no = i_work_no limit 1);   -- 训练次数序号，当 v_cur_learn_cnt = 0 认作为新建的训练任务。
  v_input_asso_value       int[]   ;
  v_cur_node_nos           bigint[];
  v_cur_node_nos_last      bigint[];
  v_input_nodes            bigint[]             := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and (node_type in ('input_01', 'input_02', 'input_03', 'input_04', 'weight') or node_fn_type = '00_const') limit 1);
  v_cur_nn_depth           int                  := 0;   -- 深度层数游标
  v_max_nn_depth           int;

begin
  set search_path to public;
  
  -- ------------------------------- 配置小批量随机训练集数量 -----------------------------------------------
  -- 刚开始训练的准备阶段，则必须制定随机批量数量。后续接续训练，则可以空下来
  if v_cur_learn_cnt = 0 
    and i_batch_amt_per_range is null
  then 
    raise exception 'should configure i_batch_amt_per_range($3) at the beginning of new training task';
  -- 审计 i_batch_amt_per_range，i_batch_range 两个配置维长要对齐。
  elsif array_length(i_batch_amt_per_range, 1) <> array_length(i_batch_range, 1)
    and array_length(i_batch_amt_per_range, 1) <> 1
  then 
    raise exception 'should array_length(i_batch_amt_per_range, 1) = array_length(i_batch_range, 1) or array_length(i_batch_amt_per_range, 1) = 1';
  -- 审计随机批量配置是否超出训练集序号范围。
  elsif exists 
    (
      select  
      from unnest(i_batch_range) tb_a_range(a_range) 
      where 
        not
        (
          a_range 
          <@ 
          (select int4range(min(ord_no), max(ord_no),'[]') from sm_sc.tb_nn_train_input_buff where work_no = i_work_no)
        )
    )
  then 
    raise exception 'outof range of train dataset in sm_sc.tb_nn_train_input_buff.ord_no where work_no = i_work_no';
  -- i_batch_amt_per_range 不为空，则配置到 00_buff_slice_rand_pick 算子。
  elsif array_length(i_batch_amt_per_range, 1) = 1 and i_batch_range is not null
  then 
    i_batch_amt_per_range := sm_sc.fv_new(i_batch_amt_per_range, array[coalesce(array_length(i_batch_range, 1), 1)]);
  end if;
    
  if i_batch_range is null 
  then 
    update sm_sc.tb_nn_node tb_node
    set 
      node_fn_asso_value = 
        case
          when i_batch_amt_per_range is not null 
            then (select array[array[min(ord_no)], array[max(ord_no)], i_batch_amt_per_range] from sm_sc.tb_nn_train_input_buff where work_no = i_work_no)
          else 
            tb_node.node_fn_asso_value
        end
    where node_fn_type = '00_buff_slice_rand_pick'
      and node_type = 'input_01'
      and work_no = i_work_no
    returning node_fn_asso_value :: int[] into v_input_asso_value
    ;
    commit;
  else
    update sm_sc.tb_nn_node tb_node
    set 
      node_fn_asso_value = 
        array
        [
          a_lowers,
          a_uppers,
          i_batch_amt_per_range
        ]
    from 
    (
      select
        array_agg(lower(i_batch_range[a_range_no]) order by a_range_no) as a_lowers
      , array_agg(upper(i_batch_range[a_range_no]) - 1 order by a_range_no) as a_uppers
      from generate_series(1, array_length(i_batch_range, 1)) tb_a_range_no(a_range_no)
    ) tb_a_ranges(a_lowers, a_uppers)
    where node_fn_type = '00_buff_slice_rand_pick'
      and node_type = 'input_01'
      and work_no = i_work_no
    returning node_fn_asso_value :: int[] into v_input_asso_value
    ;
    commit;
  end if;
  
-- -- -- debug 
-- -- raise notice 'input_01 v_input_asso_value: %', array_dims(v_input_asso_value);
  
  -- ------------------------------- 审计部分 -----------------------------------------------
  -- 审计 训练任务是否存在
  if not exists(select  from sm_sc.tb_classify_task where work_no = i_work_no)
  then
    raise exception 'no such work NO. = %!', i_work_no;

  -- 审计 输入节点是否在有效范围内
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input_01', 'input_02', 'input_03', 'input_04') group by node_type having count(*) > 1)
  then
    raise exception 'more than 1 input node, or expect one-hot i_indepdt_*!';
    
  -- -- -- 审计 测试与验证的输入节点是否只有一个
  -- -- elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'prod_input' having count(*) > 1)
  -- -- then
  -- --   raise exception 'more than 1 prod_input node, or expect one-hot i_indepdt_*!';
  -- -- 
  -- 审计 输出节点是否在有效范围内
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('output_01', 'output_02', 'output_03', 'output_04') group by node_type having count(*) > 1)
  then
    raise exception 'more than 1 output node, or expect one-hot i_depdt_*!';
    
  -- 审计 训练集同一输入节点每条数据的规格同一
  elsif exists 
    (
      select  from sm_sc.tb_nn_train_input_buff 
      where work_no = i_work_no 
      group by work_no 
      having (count(distinct array_dims(i_indepdt_01)) > 1
              or count(distinct array_dims(i_indepdt_02)) > 1
              or count(distinct array_dims(i_indepdt_03)) > 1
              or count(distinct array_dims(i_indepdt_04)) > 1
             )
    )
  then
    raise exception 'there should not be different array_dims(i_indepdt_*).';
    
  -- 审计 训练集同一输出节点每条数据的规格同一
  elsif exists 
    (
      select  from sm_sc.tb_nn_train_input_buff 
      where work_no = i_work_no 
      group by work_no 
      having count(distinct array_dims(i_depdt_01)) > 1
        or count(distinct array_dims(i_depdt_02)) > 1
        or count(distinct array_dims(i_depdt_03)) > 1
        or count(distinct array_dims(i_depdt_04)) > 1
    )
  then
    raise exception 'there should not be different arrray_length(i_depdt_*, 2).';
    
  -- 审计 训练集不存在 null 之元素
  elsif exists 
    (
      select  from sm_sc.tb_nn_train_input_buff 
      where work_no = i_work_no 
      and sm_sc.fv_aggr_slice_is_exists_null(i_indepdt_01)
      and sm_sc.fv_aggr_slice_is_exists_null(i_indepdt_02)
      and sm_sc.fv_aggr_slice_is_exists_null(i_indepdt_03)
      and sm_sc.fv_aggr_slice_is_exists_null(i_indepdt_04)
    )
  then 
    raise exception 'there are some null element in input i_indepdt_*.';
    
  -- 审计 训练集判断结果不存在 null 之元素
  elsif exists 
    (
      select  from sm_sc.tb_nn_train_input_buff 
      where work_no = i_work_no 
        and sm_sc.fv_aggr_slice_is_exists_null(i_depdt_01)
        and sm_sc.fv_aggr_slice_is_exists_null(i_depdt_02)
        and sm_sc.fv_aggr_slice_is_exists_null(i_depdt_03)
        and sm_sc.fv_aggr_slice_is_exists_null(i_depdt_04)
    )
  then 
    raise warning 'there are some null element in input i_depdt_*.';

  -- 审计 小批量随机的训练集记录数目是否符合要求
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_01' and node_fn_type = '00_buff_slice_rand_pick')
    -- and v_input_cnt < sm_sc.fv_aggr_slice_max(v_input_asso_value[2 : 2][ : ])
    and exists (select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no group by work_no having count(*) < sm_sc.fv_aggr_slice_max(v_input_asso_value[2 : 2][ : ]))
  then 
    raise exception 'count of training data should not be less than slices'' uppers of input node.';
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_01' and node_fn_type = '00_buff_slice_rand_pick')
    and true = any(v_input_asso_value[3 : 3][ : ] >` (v_input_asso_value[2 : 2][ : ] -` v_input_asso_value[1 : 1][ : ] +` 1))
  then 
    raise exception 'there should be not any 00_buff_slice_rand_pick more than its slice range.';
    
  -- 00_const 节点的算子超参数审计工作
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_fn_type = '00_const' and node_fn_asso_value is null)
  then 
    raise exception 'there should be not any null node_fn_asso_value at 00_const.';
    
  -- 非 weight 的 00_const 节点的 node_depdt_vals 初始化审计工作
  elsif exists 
    (
      select  
      from sm_sc.tb_nn_node 
      where work_no = i_work_no 
        and node_fn_type = '00_const' 
        and node_type is distinct from 'weight'
        and 
        (
          node_depdt_vals is null
          -- -- -- 以下注释代码的数组规格审查，阻碍了点算的广播特性
          -- -- or array_length(node_depdt_vals, 1) <> (node_fn_asso_value[1] :: int) 
          -- -- or array_length(node_depdt_vals, 2) <> (node_fn_asso_value[2] :: int)
          -- -- or array_length(node_depdt_vals, 3) <> (node_fn_asso_value[3] :: int)
          -- -- or array_length(node_depdt_vals, 4) <> (node_fn_asso_value[4] :: int)
        )
    )
  then 
    raise exception 'there should be not any null node_depdt_vals or unmatch length configured by node_fn_asso_value at 00_const.';

  -- 审计 算子入参数量
  --     审计三目
  --     尽管当前标准算子只有 05_conv_2d, 05_tunnel_conv，自变量数量为 2p 或 3p；
  --     为兼容可只输入一个自变量的 3p 算子，对 3p 算子的审计放宽至 1, 2, 3
  elsif exists 
  (
    select 
    from sm_sc.tb_dic_enum tb_a_enum
    inner join sm_sc.tb_nn_node tb_a_node 
      on tb_a_node.node_fn_type = tb_a_enum.enum_key
        and tb_a_node.work_no = i_work_no
    inner join sm_sc.tb_nn_path tb_a_path 
      on tb_a_path.fore_node_no = tb_a_node.node_no
        and tb_a_path.work_no = i_work_no
    where tb_a_enum.enum_name = 'node_fn_type'
      and tb_a_enum.enum_group = '3_p'
    group by tb_a_path.fore_node_no
    having count(tb_a_path.path_ord_no) > 3
  )
  then
    raise exception 'too many or too few pathes point to an fn with 3_p.';
    
  --     审计双目
  elsif exists 
  (
    select 
    from sm_sc.tb_dic_enum tb_a_enum
    inner join sm_sc.tb_nn_node tb_a_node 
      on tb_a_node.node_fn_type = tb_a_enum.enum_key
        and tb_a_node.work_no = i_work_no
    inner join sm_sc.tb_nn_path tb_a_path 
      on tb_a_path.fore_node_no = tb_a_node.node_no
        and tb_a_path.work_no = i_work_no
    where tb_a_enum.enum_name = 'node_fn_type'
      and tb_a_enum.enum_group = '2_p'
    group by tb_a_path.fore_node_no
    having count(tb_a_path.path_ord_no) <> 2
  )
  then
    raise exception 'too many or too few pathes point to an fn with 2_p.';
  
  --     审计单目
  elsif exists
  (
    select 
    from sm_sc.tb_dic_enum tb_a_enum
    inner join sm_sc.tb_nn_node tb_a_node 
      on tb_a_node.node_fn_type = tb_a_enum.enum_key
        and tb_a_node.work_no = i_work_no
    inner join sm_sc.tb_nn_path tb_a_path 
      on tb_a_path.fore_node_no = tb_a_node.node_no
        and tb_a_path.work_no = i_work_no
    where tb_a_enum.enum_name = 'node_fn_type'
      and tb_a_enum.enum_group = '1_p'
    group by tb_a_path.fore_node_no
    having count(tb_a_path.path_ord_no) > 1
  )
  then 
    raise exception 'too many pathes point to an fn with 1_p.';

  -- 审计 是否存在孤岛网络
  elsif exists 
  (
    with recursive
    cte_main_nodes as
    (
      select 
        node_no
      from sm_sc.tb_nn_node
      where work_no = i_work_no
        and node_type in ('output_01', 'output_02', 'output_03', 'output_04')
      union
      select 
        tb_a_incre.node_no
      from cte_main_nodes tb_a_main
      inner join sm_sc.tb_nn_path tb_a_path
        on tb_a_path.fore_node_no = tb_a_main.node_no
      inner join sm_sc.tb_nn_node tb_a_incre
        on tb_a_incre.node_no = tb_a_path.back_node_no
          and tb_a_incre.work_no = i_work_no
    )
    select 
    from cte_main_nodes
    having count(node_no) < (select count(node_no) from sm_sc.tb_nn_node where work_no = i_work_no)
  )
  then
    raise exception 'there should not be alone nodes.';

  -- 审计通过，新的任务的初始化工作(learn_cnt = 0)
  elsif v_cur_learn_cnt = 0
  then
    
-- -- -- debug
-- raise notice 'L298. begin: v_cur_node_nos: %;', v_cur_node_nos;
  
    update sm_sc.tb_nn_node tb_a_tar
    set 
      -- -- node_depdt_len   = 
      -- --   array 
      -- --   [
      -- --     case tb_a_tar.node_fn_type 
      -- --       when '00_full_dataset' 
      -- --         then (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no) 
      -- --       when '00_buff_slice_rand_pick' 
      -- --         then sm_sc.fv_aggr_slice_sum(node_fn_asso_value[3 : 3][ : ] :: int[]) 
      -- --     end,
      -- --     v_input_len_x
      -- --   ]
      -- -- ,                        -- -- array[array_length(tb_a_sour.i_indepdt_01, 1), array_length(tb_a_sour.i_indepdt_01, 2)],
      is_fore_node = 
        case tb_a_tar.node_fn_type 
          when '00_full_dataset' 
            then false 
          when '00_buff_slice_rand_pick' 
            then true 
        end
    where tb_a_tar.work_no = i_work_no   -- 2021082501
      and tb_a_tar.node_type = 'input_01'
    ;
    commit;
    
    update sm_sc.tb_nn_node tb_a_tar
    set 
      is_fore_node = (select is_fore_node from sm_sc.tb_nn_node where work_no = i_work_no and tb_a_tar.node_type = 'input_01')
    where tb_a_tar.work_no = i_work_no   -- 2021082501
      and tb_a_tar.node_type in ('input_02', 'input_03', 'input_04')
    ;
    commit;
    
    -- 00_const 节点的准备工作
    update sm_sc.tb_nn_node
    set 
      is_fore_node = false
    , is_back_node = false
    where work_no = i_work_no   -- 2021082501
    and node_fn_type = '00_const'
    ;
    commit;
    
-- -- -- debug
-- raise notice 'L226. begin: node_depdt_len of input: %;', (select node_depdt_len from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input_01');
  
    -- 标记前向传播节点
    -- 缺省 true. 从神经网络的初始起点（包括）开始审计，至 01_prod_mx, 05_conv_2d_grp_x, rand 类算子为止（不包括），沿途皆为 false    
    -- 更新 is_fore_node
    v_cur_node_nos := 
      (
        select array_agg(node_no) from sm_sc.tb_nn_node 
        where work_no = i_work_no 
          and 
          (
            node_type in ('input_01', 'input_02', 'input_03', 'input_04')
            or node_fn_type = '00_const' and node_type <> 'weight'
          )
      );     -- -- v_input_nodes
    while array_length(v_cur_node_nos, 1) > 0
    loop 
      -- pg 暂不支持 recursive cte 使用 aggr, 先只能用循环
      with
      cte_fore_nodes as 
      (
        select 
          tb_a_fore.node_no,
          max(tb_a_fore.node_fn_type) as node_fn_type
        from sm_sc.tb_nn_path tb_a_fore_path
        inner join sm_sc.tb_nn_node tb_a_fore
          on tb_a_fore.node_no = tb_a_fore_path.fore_node_no
            and tb_a_fore.work_no = i_work_no   -- 2021082501
        inner join sm_sc.tb_nn_path tb_a_back_path
          on tb_a_back_path.fore_node_no = tb_a_fore.node_no
            and tb_a_back_path.work_no = i_work_no   -- 2021082501
        inner join sm_sc.tb_nn_node tb_a_back
          on tb_a_back.node_no = tb_a_back_path.back_node_no
            and tb_a_back.work_no = i_work_no   -- 2021082501
        where tb_a_fore_path.back_node_no = any(v_cur_node_nos)
          and tb_a_fore.node_fn_type not in ('01_prod_mx', '05_conv_2d_grp_x', '05_conv', '04_rand_pick_y', '04_rand_pick_x', '04_rand_pick_x3', '04_rand_pick_x4', '04_new')
          and tb_a_fore_path.work_no = i_work_no   -- 2021082501
        group by tb_a_fore.node_no
        having count(distinct tb_a_back.node_no) =
                 count(distinct tb_a_back.node_no) 
                   filter 
                   (
                     where tb_a_back.is_fore_node is false
                   )
      ),
      cte_upd as
      (
        update sm_sc.tb_nn_node tb_a_tar
        set 
          is_fore_node = false
        from cte_fore_nodes tb_a_sour
        where tb_a_sour.node_no = tb_a_tar.node_no
          and tb_a_tar.work_no = i_work_no   -- 2021082501
      )
      select 
        array_agg(distinct node_no) into v_cur_node_nos 
      from cte_fore_nodes
      where node_fn_type not in ('01_prod_mx', '05_conv_2d_grp_x', '05_conv', '04_rand_pick_y', '04_rand_pick_x', '04_rand_pick_x3', '04_rand_pick_x4', '04_new')
      ;
      commit;
  
-- -- -- debug
-- raise notice 'L345.: v_cur_node_nos: %;', v_cur_node_nos;
  
    end loop;
    
    -- 标记反向传播节点
    -- 缺省 false. 从 weight 算子（包括）开始传染，至神经网络的终点（包括），沿途皆为 true

    update sm_sc.tb_nn_node
    set 
      is_back_node = true
    where work_no = i_work_no   -- 2021082501
      -- and node_no = any(v_init_nodes)
      and node_type = 'weight'
    ;
    commit;

    with recursive
    cte_back_nodes as
    (
      select 
        tb_a_main.node_no
      from sm_sc.tb_nn_node tb_a_main
      where tb_a_main.work_no = i_work_no   -- 2021082501
        and tb_a_main.is_back_node is true
      union
      select
        tb_a_path.fore_node_no
      from cte_back_nodes tb_a_back
      inner join sm_sc.tb_nn_path tb_a_path
        on tb_a_path.back_node_no = tb_a_back.node_no 
      where tb_a_path.work_no = i_work_no   -- 2021082501
    )
    update sm_sc.tb_nn_node tb_a_tar
    set
      is_back_node = true
    from cte_back_nodes tb_a_sour
    where tb_a_sour.node_no = tb_a_tar.node_no
      and tb_a_tar.work_no = i_work_no   -- 2021082501
      -- and tb_a_tar.node_type <> 'output_01'
    ;
    commit;   
  end if;
  
  -- 每次启动训练，都重新计算 node_depdt_len，用于适配动态调整随机小批量的每个类别抽样数量
  update sm_sc.tb_nn_node tb_a_tar
  set 
    node_depdt_len   = 
      array 
      [
        case tb_a_tar.node_fn_type 
          when '00_full_dataset' 
            then (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no) 
          when '00_buff_slice_rand_pick' 
            then sm_sc.fv_aggr_slice_sum(node_fn_asso_value[3 : 3][ : ] :: int[]) 
        end
      ]
      || 
      (
        select 
          array_agg(array_length(i_indepdt_01, a_cur) order by a_cur)
        from (select i_indepdt_01 from sm_sc.tb_nn_train_input_buff where work_no = i_work_no limit 1) tb_a_buff(i_indepdt_01)
          , generate_series(1, array_ndims(tb_a_buff.i_indepdt_01)) tb_a_cur(a_cur)
      )
  where tb_a_tar.work_no = i_work_no   -- 2021082501
    and tb_a_tar.node_type = 'input_01'
  ;
  commit;
  
  -- 初始化其他模态输入节点的规格
  update sm_sc.tb_nn_node tb_a_tar
  set 
    node_depdt_len = 
      array 
      [
        case tb_a_tar.node_fn_type 
          when '00_full_dataset' 
            then (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no) 
          when '00_buff_slice_rand_pick' 
            then sm_sc.fv_aggr_slice_sum(node_fn_asso_value[3 : 3][ : ] :: int[]) 
        end
      ]
      || 
      (
        select 
          array_agg(array_length(i_indepdt_ex, a_cur) order by a_cur)
        from 
          (select 
             case tb_a_tar.node_type 
               when 'input_02'
                 then i_indepdt_02
               when 'input_03'
                 then i_indepdt_03
               when 'input_04'
                 then i_indepdt_04
             end                    
             as i_indepdt_ex 
           from sm_sc.tb_nn_train_input_buff where work_no = i_work_no limit 1
          ) tb_a_buff(i_indepdt_ex)
        , generate_series(1, array_ndims(tb_a_buff.i_indepdt_ex)) tb_a_cur(a_cur)
      )
  where tb_a_tar.work_no = i_work_no   -- 2021082501
    and tb_a_tar.node_type in ('input_02', 'input_03', 'input_04')
  ;
  commit;

  -- 对齐训练次数；训练过程中，输入、偏移量系数节点不参与传播
  update sm_sc.tb_nn_node
  set 
    learn_cnt_fore = case when node_type in ('input_01', 'input_02', 'input_03', 'input_04', 'weight') or node_fn_type = '00_const' then i_limit_train_times else v_cur_learn_cnt end,
    learn_cnt_back = case when node_type in ('input_01', 'input_02', 'input_03', 'input_04') or (node_fn_type = '00_const' and node_type is distinct from 'weight') then i_limit_train_times else v_cur_learn_cnt end
  where work_no = i_work_no   -- 2021082501
  ;
  commit;

-- -- -- debug
-- raise notice 'L102. begin: v_cur_learn_cnt: %', v_cur_learn_cnt;

  -- 传播规划
  -- 先做个 learn_cnt_.. 的负标记
  update sm_sc.tb_nn_node
  set 
    learn_cnt_fore = - 1,
    learn_cnt_back = - 1
  where work_no = i_work_no
    and ((node_type not in ('input_01', 'input_02', 'input_03', 'input_04', 'weight') or node_type is null) and node_fn_type <> '00_const')
  ;
  commit;
  -- 前向打标
  v_cur_node_nos := v_input_nodes;
  v_cur_nn_depth := 0;

-- -- -- debug
-- raise notice 'L224. begin: v_cur_node_nos: %; v_input_nodes: %; v_cur_nn_depth: %;', v_cur_node_nos, v_input_nodes, v_cur_nn_depth;

  update sm_sc.tb_nn_node 
  set nn_depth_no = 0 
  where work_no = i_work_no 
    and (node_type in ('input_01', 'input_02', 'input_03', 'input_04') or (node_fn_type = '00_const' and node_type is distinct from 'weight'));
  commit;

  while 
    exists 
    (
      select         
      from sm_sc.tb_nn_node tb_a_fore
      where tb_a_fore.work_no = i_work_no    -- 2021082501
        and tb_a_fore.learn_cnt_fore < v_cur_learn_cnt
      limit 1
    )
  loop
    v_cur_nn_depth := v_cur_nn_depth + 1;
    v_cur_node_nos_last := v_cur_node_nos;
    with 
    -- 由 learn_cnt_fore 约束，找到与上次前向传播有关的，可前向计算的节点
    cte_y as
    (
      select 
        tb_a_fore.node_no
      -- , tb_a_fore.node_fn_type
      from sm_sc.tb_nn_path tb_a_fore_path
      inner join sm_sc.tb_nn_node tb_a_fore
        on tb_a_fore.node_no = tb_a_fore_path.fore_node_no
          and tb_a_fore.work_no = i_work_no   -- 2021082501
      inner join sm_sc.tb_nn_path tb_a_back_path
        on tb_a_back_path.fore_node_no = tb_a_fore.node_no
          and tb_a_back_path.work_no = i_work_no   -- 2021082501
      inner join sm_sc.tb_nn_node tb_a_back
        on tb_a_back.node_no = tb_a_back_path.back_node_no
          and tb_a_back.work_no = i_work_no   -- 2021082501
      where tb_a_fore_path.work_no = i_work_no   -- 2021082501
        and tb_a_fore.learn_cnt_fore < v_cur_learn_cnt 
        and tb_a_fore_path.back_node_no = any(v_cur_node_nos || v_input_nodes) 
      group by tb_a_fore.node_no -- , tb_a_fore.node_fn_type
      having count(*) filter (where tb_a_back.learn_cnt_fore > tb_a_fore.learn_cnt_fore) = count(*)
    ),
    cte_upd_fore_label as
    (
      update sm_sc.tb_nn_node tb_a_tar
      set 
        learn_cnt_fore = v_cur_learn_cnt,
        nn_depth_no = v_cur_nn_depth
      from cte_y tb_a_y
      where tb_a_tar.work_no = i_work_no   -- 2021082501
        and tb_a_y.node_no = tb_a_tar.node_no
      returning tb_a_tar.node_no
    )
    select array_agg(node_no) into v_cur_node_nos from cte_upd_fore_label
    ;
    commit;

-- -- debug
-- raise notice 'L256. begin: nn_depth updated nodes = %: %', v_cur_node_nos, v_cur_nn_depth;
    if v_cur_node_nos is not distinct from v_cur_node_nos_last
    then 
      raise exception 'v_cur_nn_depth: %; v_cur_node_nos is the same as v_cur_node_nos_last: %.', v_cur_nn_depth, coalesce(v_cur_node_nos_last :: text, 'null');
    end if;

  end loop;

  v_max_nn_depth := v_cur_nn_depth;

  -- 修改 weight 节点的深度， = min(下层 01_prod_mx 的深度) - 1，保证反向传播及时传递到 weight 节点
  with
  cte_nn_depth as
  (
    select 
      tb_a_back.node_no,
      min(tb_a_fore.nn_depth_no) - 1 as nn_depth_no
    from sm_sc.tb_nn_node tb_a_back
    inner join sm_sc.tb_nn_path tb_a_path
      on tb_a_back.node_no = tb_a_path.back_node_no
        and tb_a_path.work_no = i_work_no
    inner join sm_sc.tb_nn_node tb_a_fore
      on tb_a_path.fore_node_no = tb_a_fore.node_no
        and tb_a_fore.work_no = i_work_no
    where tb_a_back.work_no = i_work_no
      and tb_a_back.node_type = 'weight'
    group by tb_a_back.node_no
  )
  update sm_sc.tb_nn_node tb_a_back
  set nn_depth_no = tb_a.nn_depth_no
  from cte_nn_depth tb_a
  where tb_a_back.work_no = i_work_no
    and tb_a.node_no = tb_a_back.node_no
    -- and tb_a_back.node_type = 'weight'
  ;
  commit;

  -- 传播规划完毕，恢复 learn_cnt 为真实标记
  update sm_sc.tb_nn_node
  set 
    learn_cnt_fore = v_cur_learn_cnt,
    learn_cnt_back = v_cur_learn_cnt
  where work_no = i_work_no   -- 2021082501
    and (node_type not in ('input_01', 'input_02', 'input_03', 'input_04', 'weight') and node_fn_type <> '00_const')
  ;
  commit;

  
  -- ---------- 填充缺省协参部分。遍历 nn_depth，每次遍历，首先更新非 weight 节点的 node_fn_asso_value，再更新 node_depdt_len，结束 nn_depth 遍历，最后更新 weight 的 node_depdt_vals  ----------------------

  -- ------------------------------- 准备数据 -----------------------------------------------
-- -- debug
raise notice 'prepare data begin!!!!!!'; 

  -- ------------------------------- 审计数据部分 -----------------------------------------------
-- -- debug
raise notice 'check data len begin!!!!!!';

  -- 前向通烟更新 node_depdt_len

  update sm_sc.tb_nn_node
  set node_depdt_len = node_fn_asso_value :: int[]
  where work_no = i_work_no   -- 2021082501
    and node_fn_type = '00_const'
  ;
  commit;

    
  v_cur_nn_depth = 1;
  while v_cur_nn_depth <= v_max_nn_depth
  loop
    -- 审查 矩阵颗粒度聚合节点的自变量规格是否一致
    if exists
       (
         select  
         from sm_sc.tb_nn_node tb_a_fore
         inner join sm_sc.tb_nn_path tb_a_path_pn
           on tb_a_path_pn.work_no = i_work_no   -- 2021082501
             and tb_a_path_pn.fore_node_no = tb_a_fore.node_no
         inner join sm_sc.tb_nn_node tb_a_back_pn
           on tb_a_back_pn.work_no = i_work_no   -- 2021082501
             and tb_a_back_pn.node_no = tb_a_path_pn.back_node_no
         where tb_a_fore.work_no = i_work_no   -- 2021082501
           and tb_a_fore.nn_depth_no = v_cur_nn_depth
           and tb_a_fore.node_fn_type in ('06_aggr_mx_sum', '06_aggr_mx_prod', '06_aggr_mx_avg', '06_aggr_mx_max', '06_aggr_mx_min')
         group by tb_a_fore.node_no, tb_a_fore.node_fn_type
         having count(distinct tb_a_back_pn.node_depdt_len) > 1
       )
    then 
      raise exception 'these aggr_mx nodes have multi back nodes with unmatched dims: %'
        , (
            with 
            cte_idle_fore_node as 
            (
              select  
                tb_a_fore.node_no
              from sm_sc.tb_nn_node tb_a_fore
              inner join sm_sc.tb_nn_path tb_a_path_pn
                on tb_a_path_pn.work_no = i_work_no   -- 2021082501
                  and tb_a_path_pn.fore_node_no = tb_a_fore.node_no
              inner join sm_sc.tb_nn_node tb_a_back_pn
                on tb_a_back_pn.work_no = i_work_no   -- 2021082501
                  and tb_a_back_pn.node_no = tb_a_path_pn.back_node_no
              where tb_a_fore.work_no = i_work_no   -- 2021082501
                and tb_a_fore.nn_depth_no = v_cur_nn_depth
                and tb_a_fore.node_fn_type in ('06_aggr_mx_sum', '06_aggr_mx_prod', '06_aggr_mx_avg', '06_aggr_mx_max', '06_aggr_mx_min')
              group by tb_a_fore.node_no, tb_a_fore.node_fn_type
              having count(distinct tb_a_back_pn.node_depdt_len) > 1
            )
            select 
              string_agg(node_no :: varchar, ', ')
            from cte_idle_fore_node
          )
      ;
    end if;
    
    -- np aggr 情况，化为 1p
    with
    cte_concat_dims_change as 
    (
      select 
        tb_a_fore.node_no
      , (
          array 
          [
            case 
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_y' 
                then sum(coalesce(tb_a_back_pn.node_depdt_len[1], 1)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_y')
              else max(coalesce(tb_a_back_pn.node_depdt_len[1], 1)) filter(where tb_a_fore.node_fn_type <> '06_aggr_mx_concat_y')
            end,
            case 
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_x' 
                then sum(coalesce(tb_a_back_pn.node_depdt_len[2], 1)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x')
              else max(coalesce(tb_a_back_pn.node_depdt_len[2], 1)) filter(where tb_a_fore.node_fn_type <> '06_aggr_mx_concat_x')
            end,
            case 
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_x3' 
                then sum(coalesce(tb_a_back_pn.node_depdt_len[3], 1)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x3')
              else max(coalesce(tb_a_back_pn.node_depdt_len[3], 1)) filter(where tb_a_fore.node_fn_type <> '06_aggr_mx_concat_x3')
            end,
            case 
              when tb_a_fore.node_fn_type = '06_aggr_mx_concat_x4' 
                then sum(coalesce(tb_a_back_pn.node_depdt_len[4], 1)) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x4')
              else max(coalesce(tb_a_back_pn.node_depdt_len[4], 1)) filter(where tb_a_fore.node_fn_type <> '06_aggr_mx_concat_x4')
            end
          ] 
        )[1 : max(array_length(tb_a_back_pn.node_depdt_len, 1))]
          as a_pn_len
      -- 若干类型算子粒度的超参数在此自动配置填充，而不需要手动配置。参看字典表对各类算子 node_fn_asso_value 的解释
      , case tb_a_fore.node_fn_type
          when '06_aggr_mx_avg'
            then array[count(tb_a_back_pn.node_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_avg')]
          when '06_aggr_mx_concat_y'
            then array_agg(tb_a_back_pn.node_depdt_len[1] order by tb_a_path_pn.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_y')
          when '06_aggr_mx_concat_x'
            then array_agg(coalesce(tb_a_back_pn.node_depdt_len[2], 1) order by tb_a_path_pn.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x')
          when '06_aggr_mx_concat_x3'
            then array_agg(coalesce(tb_a_back_pn.node_depdt_len[3], 1) order by tb_a_path_pn.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x3')
          when '06_aggr_mx_concat_x4'
            then array_agg(coalesce(tb_a_back_pn.node_depdt_len[4], 1) order by tb_a_path_pn.path_ord_no) filter(where tb_a_fore.node_fn_type = '06_aggr_mx_concat_x4')
        end as a_node_fn_asso_value
      from sm_sc.tb_nn_node tb_a_fore
      inner join sm_sc.tb_nn_path tb_a_path_pn
        on tb_a_path_pn.work_no = i_work_no   -- 2021082501
          and tb_a_path_pn.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.tb_nn_node tb_a_back_pn
        on tb_a_back_pn.work_no = i_work_no   -- 2021082501
          and tb_a_back_pn.node_no = tb_a_path_pn.back_node_no
      where tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
        and tb_a_fore.node_fn_type in ('06_aggr_mx_avg', '06_aggr_mx_concat_y', '06_aggr_mx_concat_x', '06_aggr_mx_concat_x3', '06_aggr_mx_concat_x4')
      group by tb_a_fore.node_no, tb_a_fore.node_fn_type
    ),
    cte_p1_p2 as 
    (
      select 
        tb_a_fore.node_no,
        coalesce(tb_a_back_pn.a_pn_len, tb_a_back_p1.node_depdt_len) as a_p1_len,
        case when tb_a_fore.node_fn_type not like '06_aggr_mx_%' then tb_a_back_p2.node_depdt_len end as a_p2_len,
        tb_a_back_pn.a_node_fn_asso_value
      from sm_sc.tb_nn_node tb_a_fore
      inner join sm_sc.tb_nn_path tb_a_path_p1
        on tb_a_path_p1.work_no = i_work_no   -- 2021082501
          and tb_a_path_p1.path_ord_no = 1 -- -- 如果与 前向节点的 path_ord_no 冲突，使用 00_none 算子隔离。
          and tb_a_path_p1.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.tb_nn_node tb_a_back_p1
        on tb_a_back_p1.work_no = i_work_no   -- 2021082501
          and tb_a_back_p1.node_no = tb_a_path_p1.back_node_no
      left join sm_sc.tb_nn_path tb_a_path_p2
        on tb_a_path_p2.work_no = i_work_no   -- 2021082501
          and tb_a_path_p2.path_ord_no = 2 -- -- 如果与 前向节点的 path_ord_no 冲突，使用 00_none 算子隔离。
          and tb_a_path_p2.fore_node_no = tb_a_fore.node_no
      left join sm_sc.tb_nn_node tb_a_back_p2
        on tb_a_back_p2.work_no = i_work_no   -- 2021082501
          and tb_a_back_p2.node_no = tb_a_path_p2.back_node_no
      left join cte_concat_dims_change tb_a_back_pn
        on tb_a_back_pn.node_no = tb_a_fore.node_no
      where tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
    )
    update sm_sc.tb_nn_node tb_a_fore
    set 
      node_fn_asso_value = 
        coalesce(tb_a_fore.node_fn_asso_value, tb_a_p1_p2.a_node_fn_asso_value) 
    , node_depdt_len = 
        sm_sc.fv_lambda_arr_len
        (
          tb_a_fore.node_no,
          tb_a_fore.node_fn_type, 
          tb_a_p1_p2.a_p1_len :: int[], 
          tb_a_p1_p2.a_p2_len :: int[],
          coalesce(tb_a_fore.node_fn_asso_value, tb_a_p1_p2.a_node_fn_asso_value)
        )
    from cte_p1_p2 tb_a_p1_p2
    where tb_a_fore.work_no = i_work_no   -- 2021082501
      and tb_a_fore.node_no = tb_a_p1_p2.node_no
    ;
    commit;

    v_cur_nn_depth := v_cur_nn_depth + 1;
  end loop;

-- ---------------------------------------------------------------
  -- weight 的高宽，由前向算子的高宽反推得出
  update sm_sc.tb_nn_node tb_a_back 
  set 
    node_fn_asso_value = 
      sm_sc.fv_nn_weight_len
      (
        tb_a_fore.node_fn_type
      , tb_a_path.path_ord_no
      , tb_a_fore.node_fn_asso_value
      )
  from sm_sc.tb_nn_path tb_a_path, sm_sc.tb_nn_node tb_a_fore 
  where tb_a_back.work_no = i_work_no   -- 2021082501
    and tb_a_path.work_no = i_work_no   -- 2021082501
    and tb_a_fore.work_no = i_work_no   -- 2021082501
    and tb_a_path.back_node_no = tb_a_back.node_no
    and tb_a_fore.node_no = tb_a_path.fore_node_no
    and tb_a_back.node_type = 'weight'     
    and tb_a_back.node_fn_asso_value is null                   -- weight 节点的 tb_a_back.node_fn_type is null
    -- and tb_a_path.path_ord_no = 2
  ;
  commit;

-- ------------------------------------------------------------------------------
  -- 首轮训练之前，以 node_depdt_len 为依据，确定 weight 的矩阵规格
  if v_cur_learn_cnt = 0
  then    
    -- 初始化 w 权值，为避免鞍点，采用随机
    update sm_sc.tb_nn_node 
    set 
      node_depdt_vals = 
        sm_sc.fv_new_randn
        (
          0.0 :: float 
          
        -- , 1.0 / 0.6745  :: float     -- 假定，权重（斜率）是无偏的，大于 0.0 和小于 0.0 的概率相同，都是 50%
        --                              -- 参看标准正态分布表
        --                              -- 误差概率分布：当统计值的误差介于±0.6745(标准误差)范围时，概率为 50%；误差介于±2范围时，概率为95%；误差介于±3范围时，概率为99.7%；
        --                              -- 也可以自行修改该标准差，使用权重参数的 xaviar 初始化, He 初始化 等方法
        , (1.0 
          / 
          power
          (
            greatest
            (
              node_fn_asso_value[array_length(node_fn_asso_value, 1) - 1]
            , node_fn_asso_value[array_length(node_fn_asso_value, 1)]
            )
          , 0.5
          )) :: float
        , node_fn_asso_value :: int[]
        )
    -- , node_depdt_len = node_fn_asso_value
    where work_no = i_work_no   -- 2021082501
      and node_type = 'weight'          -- weight 节点的 node_fn_type = '' 或者 is null
      and node_fn_type = '00_const'
    ;
    commit;
  end if;

-- ------------------------------------------------------------------------------
  -- 审查 nn 节点算子类型的超参数是否完善配置
  v_cur_node_nos := 
    (
      with 
      cte_fn_asso_value_range
      as 
      (
        select 
          enum_group
        , sm_sc.fa_range_or(int4range(lower(enum_range) :: int, upper(enum_range) :: int, '[]') :: int4multirange) as a_fn_asso_value_range
        from sm_sc.tb_dic_enum
        where enum_name = 'node_fn_asso_value'
        group by enum_group
      )
      select 
        array_agg(distinct tb_a_node.node_no)
      from cte_fn_asso_value_range tb_a_dic
      inner join sm_sc.tb_nn_node tb_a_node 
        on tb_a_node.node_fn_type = tb_a_dic.enum_group
      where tb_a_node.work_no = i_work_no
        and (not array_length(tb_a_node.node_fn_asso_value, 1) <@ tb_a_dic.a_fn_asso_value_range)
            or tb_a_node.node_fn_asso_value is null
    )
  ;

  delete from sm_sc.__vt_nn_node where work_no = i_work_no;
  insert into sm_sc.__vt_nn_node
  (
    work_no                      ,
    node_no                  ,        
    node_type                    ,
    node_fn_type                 ,
    node_fn_asso_value      ,
    nn_depth_no                  ,
    node_depdt_vals                  
  )
  select 
    work_no                      ,
    node_no                  ,        
    node_type                    ,
    node_fn_type                 ,
    node_fn_asso_value      ,
    nn_depth_no                  ,
    case when node_type = 'weight' or node_fn_type = '00_const' then node_depdt_vals end as node_depdt_vals                 
  from sm_sc.tb_nn_node
  where work_no = i_work_no
  ;    
  delete from sm_sc.__vt_nn_path where work_no = i_work_no;
  insert into sm_sc.__vt_nn_path
  (
    work_no     
  , fore_node_no
  , path_ord_no 
  , back_node_no
  )
  select 
    work_no     
  , fore_node_no
  , path_ord_no 
  , back_node_no
  from sm_sc.tb_nn_path
  where work_no = i_work_no
  ;
  commit;

  if array_length(v_cur_node_nos, 1) > 0 
  then 
    raise warning 'these node_fn_asso_value is null, please check nodes: %.', v_cur_node_nos;
  else 
    raise notice 'prepare well done!!!!!!';
  end if;
  
  update sm_sc.tb_nn_node 
  set dropout_ratio = 0.0
  where work_no = i_work_no
    and dropout_ratio is null
  ;
  
  update sm_sc.tb_nn_node 
  set dropout_rescale = 1.0
  where work_no = i_work_no
    and dropout_rescale is null
  ;
  
  update sm_sc.tb_nn_node 
  set dropout_depdt_val = 0.0
  where work_no = i_work_no
    and dropout_depdt_val is null
  ;
  
  update sm_sc.tb_nn_node 
  set is_dropout = false
  where work_no = i_work_no
    and is_dropout is null
  ;
  
end
$$
language plpgsql;




-- -- 执行准备和检查
-- call sm_sc.prc_nn_prepare
-- (
--   pgv_get('vars', 'this_work_no_02', NULL::bigint)   ,
--   2500      -- ,
--   -- 200
-- );