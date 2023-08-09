drop procedure if exists sm_sc.prc_nn_prepare;
create or replace procedure sm_sc.prc_nn_prepare
(
  i_work_no                          bigint                                   ,                                                                                                -- 训练任务编号
  i_limit_train_times                int               default    10000                                                                                                        -- 最大训练次数，然后未完成中止
)
as
$$
declare -- here
  v_cur_learn_cnt          bigint               := (select learn_cnt from sm_sc.tb_classify_task where work_no = i_work_no limit 1);   -- 训练次数序号
  v_input_asso_value       int[]             := (select node_fn_asso_value :: int[] from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input' limit 1);
  v_input_cnt              int               := (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
  v_input_len_x            int               := (select array_length(i_x, 1) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no limit 1);
  -- v_len_x1                 int               := (select array_length(i_x, 1) from sm_sc.tb_classify_task where work_no = i_work_no limit 1);         -- 2021082501
  -- v_len_x2                 int               := (select array_length(i_x, 2) from sm_sc.tb_classify_task where work_no = i_work_no limit 1) + 1;         -- 2021082501 
  v_cur_node_nos           bigint[];
  v_input_nodes            bigint[]             := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input', 'offset', 'weight') limit 1);
  -- v_init_nodes             bigint[]             := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input', 'offset') limit 1);
  v_cur_nn_depth           int               := 0;   -- 深度层数游标
  v_max_nn_depth           int;

begin
  set search_path to public;

  -- ------------------------------- 审计部分 -----------------------------------------------
  -- 审计 训练任务是否存在
  if not exists(select  from sm_sc.tb_classify_task where work_no = i_work_no)
  then
    raise exception 'no such work NO. = %!', i_work_no;

  -- -- -- 审计 array_length(i_x, 1) == array_length(i_y, 1)，否则报错抛出
  -- -- elsif exists (select  from sm_sc.tb_classify_task where work_no = i_work_no and array_length(i_x, 1) <> array_length(i_y, 1))
  -- -- then
  -- --   raise exception 'unmatched 1D length between i_x and i_y!';

  -- 审计 输入节点是否只有一个
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input' having count(*) > 1)
  then
    raise exception 'more than 1 input node, or expect one-hot i_x!';
    
  -- 审计 测试与验证的输入节点是否只有一个
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'prod_input' having count(*) > 1)
  then
    raise exception 'more than 1 prod_input node, or expect one-hot i_x!';

  -- 审计 输出节点是否只有一个
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'output' having count(*) > 1)
  then
    raise exception 'more than 1 output node, or expect one-hot i_y!';
    
  -- 审计 训练集每条数据的宽度同一
  elsif exists (select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and array_length(i_x, 1) <> v_input_len_x)
  then
    raise exception 'there should not be different arrray_length(i_x, 2).';
    
  -- 审计 训练集不存在 null 之元素
  elsif exists (select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and array_position(i_x, null::float) is not null)
  then 
    raise exception 'there are some null element in input i_x.';
    
  -- 审计 训练集每条数据判断结果的宽度同一
  elsif exists (select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and array_length(i_y, 2) <> v_input_len_x)
  then
    raise exception 'there should not be different arrray_length(i_y, 2).';
    
  -- 审计 训练集判断结果不存在 null 之元素
  elsif exists (select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no and array_position(i_y, null::float) is not null)
  then 
    raise exception 'there are some null element in input i_y.';

  -- 审计 小批量随机的训练集记录数目是否符合要求
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input' and node_fn_type = 'buff_slice_rand_pick')
    and v_input_cnt < sm_sc.fv_aggr_slice_max(v_input_asso_value[2 : 2][ : ])
  then 
    raise exception 'count of training data should not be less than slices'' uppers of input node.';
  elsif exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input' and node_fn_type = 'buff_slice_rand_pick')
    and not sm_sc.fv_aggr_slice_and(v_input_asso_value[3 : 3][ : ] <=` (v_input_asso_value[2 : 2][ : ] -` v_input_asso_value[1 : 1][ : ] +` 1))
  then 
    raise exception 'there should be not any rand_pick_cnt more than its slice range.';
  -- 审计 offset 只能有一个前向节点，且该节点 like 'agg_concat_%'
  elsif exists 
  (
    select  from sm_sc.tb_nn_node tb_a_back
    inner join sm_sc.tb_nn_path tb_a_path 
      on tb_a_path.back_node_no = tb_a_back.node_no
        and tb_a_path.work_no = i_work_no 
    inner join sm_sc.tb_nn_node tb_a_fore
      on tb_a_fore.node_no = tb_a_path.fore_node_no
        and tb_a_fore.work_no = i_work_no 
    where tb_a_back.work_no = i_work_no 
      and tb_a_back.node_type = 'offset' 
    group by tb_a_back.node_no
    having count(tb_a_fore.node_no) > 1
      or count(tb_a_fore.node_no) filter(where tb_a_fore.node_fn_type not like 'agg_concat_%') > 0
  )
  then 
    raise exception 'there should not be offset nodes with more than 1 fore node, or no like ''agg_concat_%%'' fore nodes.';

  -- 审计 offset 只能有一个前向节点，且该节点 like 'agg_concat_%'
  

  -- -- -- 限制 slice 只能在 input 之后出现，用于数据预处理，分组抽样
  -- -- elsif exists 
  -- -- (
  -- --   select  
  -- --   from sm_sc.tb_nn_node tb_a_slice 
  -- --   inner join sm_sc.tb_nn_path tb_a_path 
  -- --     on tb_a_path.fore_node_no = tb_a_slice.node_no
  -- --       and tb_a_path.work_no = i_work_no
  -- --   inner join sm_sc.tb_nn_node tb_a_input 
  -- --     on tb_a_input.node_no = tb_a_path.fore_node_no
  -- --       and tb_a_input.work_no = i_work_no
  -- --   where tb_a_slice.work_no = i_work_no 
  -- --     and tb_a_input.node_type <> 'input' 
  -- --     and tb_a_slice.node_type like 'slice_%' 
  -- --     limit 1
  -- -- )
  -- -- then
  -- --   raise exception 'have not support slice after other node without node_type = ''input''!';

  -- 审计 算子入参数量
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
    having count(tb_a_path.path_ord_no) > 2
  )
  then
    raise exception 'too many pathes point to an fn with 2_p.';
  
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
        and node_type = 'output'
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
      -- -- node_o_len   = 
      -- --   array 
      -- --   [
      -- --     case tb_a_tar.node_fn_type 
      -- --       when 'const' 
      -- --         then (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no) 
      -- --       when 'buff_slice_rand_pick' 
      -- --         then sm_sc.fv_aggr_slice_sum(node_fn_asso_value[3 : 3][ : ] :: int[]) 
      -- --     end,
      -- --     v_input_len_x
      -- --   ]
      -- -- ,                        -- -- array[array_length(tb_a_sour.i_x, 1), array_length(tb_a_sour.i_x, 2)],
      is_fore_node = 
        case tb_a_tar.node_fn_type 
          when 'const' 
            then false 
          when 'buff_slice_rand_pick' 
            then true 
        end
    where tb_a_tar.work_no = i_work_no   -- 2021082501
      and tb_a_tar.node_type = 'input'
    ;
    commit;
    
-- -- -- debug
-- raise notice 'L226. begin: node_o_len of input: %;', (select node_o_len from sm_sc.tb_nn_node where work_no = i_work_no and node_type = 'input');
  
    -- 标记前向传播节点
    -- 缺省 true. 从神经网络的初始起点（包括）开始审计，至 prod_mx, conv_2d, rand 类算子为止（不包括），沿途皆为 false
    update sm_sc.tb_nn_node
    set 
      is_fore_node = false
    where work_no = i_work_no   -- 2021082501
      -- and node_no = any(v_init_nodes)
      and node_type = 'offset'   -- -- in ('input', 'offset')
    ;
    commit;
    
    -- 更新 is_fore_node
    v_cur_node_nos := (select array_agg(node_no) from sm_sc.tb_nn_node where work_no = i_work_no and node_type in ('input', 'offset') limit 1);     -- -- v_input_nodes
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
          and tb_a_fore.node_fn_type not in ('prod_mx', 'conv_2d', 'rand_pick_x', 'rand_pick_y', 'new')
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
      where node_fn_type not in ('prod_mx', 'conv_2d', 'rand_pick_x', 'rand_pick_y', 'new')
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
      -- and tb_a_tar.node_type <> 'output'
    ;
    commit;   
  end if;
  
  -- 每次启动训练，都重新计算 node_o_len，用于适配动态调整随机小批量的每个类别抽样数量
  update sm_sc.tb_nn_node tb_a_tar
  set 
    node_o_len   = 
      array 
      [
        case tb_a_tar.node_fn_type 
          when 'const' 
            then (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no) 
          when 'buff_slice_rand_pick' 
            then sm_sc.fv_aggr_slice_sum(node_fn_asso_value[3 : 3][ : ] :: int[]) 
        end,
        v_input_len_x
      ]
    -- -- ,                        -- -- array[array_length(tb_a_sour.i_x, 1), array_length(tb_a_sour.i_x, 2)],
    -- -- is_fore_node = 
    -- --   case tb_a_tar.node_fn_type 
    -- --     when 'const' 
    -- --       then false 
    -- --     when 'buff_slice_rand_pick' 
    -- --       then true 
    -- --   end
  where tb_a_tar.work_no = i_work_no   -- 2021082501
    and tb_a_tar.node_type = 'input'
  ;
  commit;

  -- 对齐训练次数；训练过程中，输入、偏移量系数节点不参与传播
  update sm_sc.tb_nn_node
  set 
    learn_cnt_fore = case when node_type in ('input', 'offset', 'weight') then i_limit_train_times else v_cur_learn_cnt end,
    learn_cnt_back = case when node_type in ('input', 'offset') then i_limit_train_times else v_cur_learn_cnt end
  where work_no = i_work_no   -- 2021082501
  ;
  commit;

-- -- debug
raise notice 'L102. begin: v_cur_learn_cnt: %', v_cur_learn_cnt;

  -- 传播规划
  -- 先做个 learn_cnt_.. 的负标记
  update sm_sc.tb_nn_node
  set 
    learn_cnt_fore = - 1,
    learn_cnt_back = - 1
  where work_no = i_work_no
    and (node_type not in ('input', 'offset', 'weight') or node_type is null)
  ;
  commit;
  -- 前向打标
  v_cur_node_nos := v_input_nodes;
  v_cur_nn_depth := 0;

-- -- -- debug
-- raise notice 'L224. begin: v_cur_node_nos: %; v_input_nodes: %; v_cur_nn_depth: %;', v_cur_node_nos, v_input_nodes, v_cur_nn_depth;

  update sm_sc.tb_nn_node set nn_depth_no = 0 where work_no = i_work_no and node_type = 'input';
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
    with 
    -- 由 learn_cnt_fore 约束，找到与上次前向传播有关的，可前向计算的节点
    cte_y as
    (
      select 
        tb_a_fore.node_no,
        tb_a_fore.node_fn_type
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
      group by tb_a_fore.node_no, tb_a_fore.node_fn_type
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

  end loop;

  v_max_nn_depth := v_cur_nn_depth;

  -- 修改 weight 节点的深度， = min(下层 prod_mx 的深度) - 1，保证反向传播及时传递到 weight 节点
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
    and (node_type not in ('input', 'offset', 'weight') or node_type is null)
  ;
  commit;

  
  -- ------------------------------- 填充缺省协参部分，slice, weight 可能会需要 -----------------------------------------------
  
  -- 如果未配置 slice_ 算子协参，那么配置切片分发为默认 path_no 单列切片
  -- 规约协参配置，也能支持多个间断切片，参看 node_fn_asso_value 与 sm_sc.fv_sample_y / sm_sc.fv_sample_x
  
  -- slice 的切片位置
  update sm_sc.tb_nn_node tb_a_fore
  set node_fn_asso_value = array[tb_a_path.path_ord_no]
  from sm_sc.tb_nn_path tb_a_path
  where tb_a_fore.work_no = i_work_no   -- 2021082501
    and tb_a_path.work_no = i_work_no   -- 2021082501
    and tb_a_fore.node_fn_type like 'slice_%'
    and tb_a_fore.node_no = tb_a_path.fore_node_no
    and tb_a_fore.node_fn_asso_value is null
  ;
  commit;
  
  -- -- -- weight 的高宽，通常 array_length(weight, 2) === 1, 由 prod_mx, conv_2d 算子的高宽反向推到得出，用于初始化 weight
  update sm_sc.tb_nn_node tb_a_back 
  set 
    node_fn_asso_value = 
      case 
        when tb_a_fore.node_fn_type = 'prod_mx'
          then tb_a_fore.node_fn_asso_value[2 : 3]    -- 参看字典表 enum_name = 'node_fn_asso_value' and enum_group = 'prod_mx'
        when tb_a_fore.node_fn_type = 'conv_2d'
          then tb_a_fore.node_fn_asso_value[2 : 3]    -- 参看字典表 enum_name = 'node_fn_asso_value' and enum_group = 'conv_2d'
      end
  from sm_sc.tb_nn_path tb_a_path, sm_sc.tb_nn_node tb_a_fore 
  where tb_a_back.work_no = i_work_no   -- 2021082501
    and tb_a_path.work_no = i_work_no   -- 2021082501
    and tb_a_fore.work_no = i_work_no   -- 2021082501
    and tb_a_path.back_node_no = tb_a_back.node_no
    and tb_a_fore.node_no = tb_a_path.fore_node_no
    and tb_a_back.node_type = 'weight'
  ;
  commit;


  -- ------------------------------- 准备数据 -----------------------------------------------
-- -- debug
raise notice 'L045. prepare data begin!!!!!!'; 

  -- ------------------------------- 审计数据部分 -----------------------------------------------
-- -- debug
raise notice 'L504. check data len begin!!!!!!';

  -- 前向通烟更新 node_o_len

  -- 首轮训练之前，以 node_o_len 为依据，确定 weight 的矩阵规格
  if v_cur_learn_cnt = 0
  then    
    -- 初始化 w 权值，为避免鞍点，采用随机
    
    update sm_sc.tb_nn_node tb_a_back
    set 
      -- node_fn_asso_value[1] :: int             -- 规约：存放 array_length(i_x, 1)
      -- node_fn_asso_value[2] :: int             -- 规约：存放 array_length(i_x, 2), 也即 array_length(i_w, 1)
      -- node_fn_asso_value[3] :: int             -- 规约：存放 array_length(i_w, 2), 也即 1
      node_y_vals = 
        sm_sc.fv_new_randn
        (
          0.0, 
          exp(1.0),    -- 不要太小，0.1 还是太靠近 0 了，比 1.0 大一些，负面影响仍然可控，又可以保证权重参数差异化，避免梯度鞍点附近的极小值。也可以自行修改使用权重参数初始化的 He initialization 等方法
          case tb_a_fore.node_fn_type
            when 'prod_mx'
              then tb_a_fore.node_fn_asso_value[2 : 3] :: int[]
            when 'conv_2d'
              then 
                -- 卷积核扁平化
                case 
                  when tb_a_fore.node_fn_asso_value[12] :: int :: boolean is true
                    -- 配套偏移量
                    then array[1, tb_a_fore.node_fn_asso_value[2] :: int * tb_a_fore.node_fn_asso_value[3] :: int + 1]
                  else array[1, tb_a_fore.node_fn_asso_value[2] :: int * tb_a_fore.node_fn_asso_value[3] :: int]
                end
            -- -- else array[1, 1]
          end
        ),
      node_o_len = 
        case tb_a_fore.node_fn_type
          when 'prod_mx'
            then tb_a_fore.node_fn_asso_value[2 : 3] :: int[]
          when 'conv_2d'
            -- 卷积核扁平化，配套偏移量
            then array[1, tb_a_fore.node_fn_asso_value[2] :: int * tb_a_fore.node_fn_asso_value[3] :: int + 1]
          -- -- else
        end
    from sm_sc.tb_nn_path tb_a_path, sm_sc.tb_nn_node tb_a_fore
    where tb_a_back.work_no = i_work_no   -- 2021082501
      and tb_a_back.node_type = 'weight'
      and tb_a_path.work_no = i_work_no   -- 2021082501
      and tb_a_path.back_node_no = tb_a_back.node_no
      and tb_a_path.path_ord_no = 2
      and tb_a_fore.work_no = i_work_no   -- 2021082501
      and tb_a_fore.node_no = tb_a_path.fore_node_no
    ;
    commit;
  end if;
    
  v_cur_nn_depth = 1;
  while v_cur_nn_depth <= v_max_nn_depth
  loop

    -- -- -- np aggr 情况，化为 1p
    with
    cte_concat_yx_change as 
    (
      select 
        tb_a_fore.node_no,
        array 
        [
          case 
            when tb_a_fore.node_fn_type = 'agg_concat_y' 
              then sum(tb_a_back_pn.node_o_len[1]) filter(where tb_a_fore.node_fn_type = 'agg_concat_y')
            else max(tb_a_back_pn.node_o_len[1]) filter(where tb_a_fore.node_fn_type <> 'agg_concat_y')
          end,
          case 
            when tb_a_fore.node_fn_type = 'agg_concat_x' 
              then sum(tb_a_back_pn.node_o_len[2]) filter(where tb_a_fore.node_fn_type = 'agg_concat_x')
            else max(tb_a_back_pn.node_o_len[2]) filter(where tb_a_fore.node_fn_type <> 'agg_concat_x')
          end
        ] as pn_len
      from sm_sc.tb_nn_node tb_a_fore
      inner join sm_sc.tb_nn_path tb_a_path_pn
        on tb_a_path_pn.work_no = i_work_no   -- 2021082501
          and tb_a_path_pn.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.tb_nn_node tb_a_back_pn
        on tb_a_back_pn.work_no = i_work_no   -- 2021082501
          and tb_a_back_pn.node_no = tb_a_path_pn.back_node_no
      where tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
        and tb_a_fore.node_fn_type in ('agg_concat_y', 'agg_concat_x')
      group by tb_a_fore.node_no, tb_a_fore.node_fn_type
    ),
    cte_p1_p2 as 
    (
      select 
        tb_a_fore.node_no,
        coalesce(tb_a_back_pn.pn_len, array[tb_a_back_p1.node_o_len[1], tb_a_back_p1.node_o_len[2]]) as p1_len,
        case when tb_a_fore.node_fn_type not like 'agg_%' then array[tb_a_back_p2.node_o_len[1], tb_a_back_p2.node_o_len[2]] end as p2_len
      from sm_sc.tb_nn_node tb_a_fore
      inner join sm_sc.tb_nn_path tb_a_path_p1
        on tb_a_path_p1.work_no = i_work_no   -- 2021082501
          and tb_a_path_p1.path_ord_no = 1 -- -- (... or tb_a_fore.node_fn_type like 'slice_%')  -- 规约：node_fn_type like 'slice_%' 的 node 只有一个 back node，且 path_ord_no 不一定为 1。
          and tb_a_path_p1.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.tb_nn_node tb_a_back_p1
        on tb_a_back_p1.work_no = i_work_no   -- 2021082501
          and tb_a_back_p1.node_no = tb_a_path_p1.back_node_no
      left join sm_sc.tb_nn_path tb_a_path_p2
        on tb_a_path_p2.work_no = i_work_no   -- 2021082501
          and tb_a_path_p2.path_ord_no = 2 -- -- and tb_a_fore.node_fn_type not like 'slice_%'  -- 规约：node_fn_type like 'slice_%' 的 node 只有一个 back node，且 path_ord_no 不一定为 1。
          and tb_a_path_p2.fore_node_no = tb_a_fore.node_no
      left join sm_sc.tb_nn_node tb_a_back_p2
        on tb_a_back_p2.work_no = i_work_no   -- 2021082501
          and tb_a_back_p2.node_no = tb_a_path_p2.back_node_no
      left join cte_concat_yx_change tb_a_back_pn
        on tb_a_back_pn.node_no = tb_a_fore.node_no
      where tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
    )
    update sm_sc.tb_nn_node tb_a_fore
    set 
      node_o_len = 
        sm_sc.fv_lambda_arr_len
        (
          tb_a_fore.node_no,
          tb_a_fore.node_fn_type, 
          tb_a_p1_p2.p1_len :: int[], 
          tb_a_p1_p2.p2_len :: int[],
          tb_a_fore.node_fn_asso_value
        )
    from cte_p1_p2 tb_a_p1_p2
    where tb_a_fore.work_no = i_work_no   -- 2021082501
      and tb_a_fore.node_no = tb_a_p1_p2.node_no
    ;
    commit;

    -- 按照来自上游的弟弟节点的输入 y_len 确定 offset y_len
    with 
    cte_brother_y_len as 
    (
      select 
        tb_a_back_offset.node_no,
        max(tb_a_back_brother.node_o_len[1]) as node_o_len_y
      from sm_sc.tb_nn_node tb_a_back_offset
      inner join sm_sc.tb_nn_path tb_a_path_fore
        on tb_a_path_fore.work_no = i_work_no   -- 2021082501
          and tb_a_path_fore.back_node_no = tb_a_back_offset.node_no
      inner join sm_sc.tb_nn_node tb_a_fore
        on tb_a_fore.work_no = i_work_no   -- 2021082501
          and tb_a_fore.node_no = tb_a_path_fore.fore_node_no
          and tb_a_fore.nn_depth_no = v_cur_nn_depth + 1
      left join sm_sc.tb_nn_path tb_a_path_back
        on tb_a_path_back.work_no = i_work_no   -- 2021082501
          and tb_a_path_back.fore_node_no = tb_a_path_fore.fore_node_no
      left join sm_sc.tb_nn_node tb_a_back_brother
        on tb_a_back_brother.work_no = i_work_no   -- 2021082501
          and tb_a_back_brother.node_no = tb_a_path_back.back_node_no
      where tb_a_back_offset.work_no = i_work_no   -- 2021082501
        and tb_a_back_offset.node_type = 'offset'
      group by tb_a_back_offset.node_no
    )
    update sm_sc.tb_nn_node tb_a_tar
    set 
      node_y_vals = sm_sc.fv_new(1.0, array[node_o_len_y, 1]),
      node_o_len = array[node_o_len_y, 1]
    from cte_brother_y_len tb_a_brother
    where tb_a_tar.work_no = i_work_no   -- 2021082501
      and tb_a_tar.node_no = tb_a_brother.node_no
    ;
    commit;

    v_cur_nn_depth := v_cur_nn_depth + 1;
  end loop;

raise notice 'prepare well done!!!!!!';

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