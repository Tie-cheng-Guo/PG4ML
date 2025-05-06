drop procedure if exists sm_sc.prc_add_pretrain_from_infer_p(bigint, varchar(32), char(6));
create or replace procedure sm_sc.prc_add_pretrain_from_infer_p
(
  i_work_no           bigint
, i_loss_fn_type      varchar(32)
, i_model_code_6      char(6)    default left(md5(random()::text), 6)  -- 如果没有，那么随机生成
) as 
$$
declare
  v_cur_node_nos           bigint[];
begin
  -- model_code_6 优先使用指定 code；


  delete from sm_sc.tb_classify_task where work_no = i_work_no;
  delete from sm_sc.tb_nn_node where work_no = i_work_no;
  delete from sm_sc.tb_nn_path where work_no = i_work_no;
  -- delete from sm_sc.tb_nn_train_input_buff where work_no = i_work_no;
  
  insert into sm_sc.tb_classify_task
  (
    work_no     
  , model_code_6
  , learn_cnt   
  , loss_fn_type
  )
  select 
    i_work_no  
  , i_model_code_6
  , 1   
  , i_loss_fn_type
  ;
  
  insert into sm_sc.tb_nn_node
  (
    work_no           
  , node_no           
  , node_type         
  , node_fn_type      
  , node_fn_asso_value
  , nn_depth_no       
  -- , learn_cnt_fore    
  -- , learn_cnt_back    
  -- , is_fore_node      
  -- , is_back_node  
  -- , dropout_ratio     
  -- , dropout_rescale   
  -- , dropout_depdt_val 
  -- , is_dropout        
  -- , node_depdt_len    
  -- , pick_depdt_idx    
                      
  -- , node_depdt_vals   
  , p_node_depdt
  -- , node_dloss_ddepdt 
  -- , cost_delta_l1     
  -- , cost_delta_l2     
  -- , node_grp_no       
  -- , node_grp_ord_no   
  -- , node_desc   
  )
  select 
    work_no           
  , node_no           
  , node_type         
  , node_fn_type      
  , node_fn_asso_value
  , nn_depth_no       
  -- , node_depdt_vals  
  , case 
      when node_depdt_vals is not null 
        then
        sm_sc.__fv_set_kv
        (
          node_depdt_vals
        , i_model_code_6 ||
          '_' || i_work_no :: varchar   ||
          '_' || node_no :: varchar ||
          '__d__'  -- 'depdt'
        )
      else null
    end
  from sm_sc.__vt_nn_node
  where work_no = i_work_no
  ;
  
  insert into sm_sc.tb_nn_path
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
  from sm_sc.__vt_nn_path
  where work_no = i_work_no
  ;
  
  commit;
  
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

end
$$
language plpgsql;

-- call 
-- sm_sc.prc_add_pretrain_from_infer_p
-- (
--   -000000002
-- , '201'
-- );