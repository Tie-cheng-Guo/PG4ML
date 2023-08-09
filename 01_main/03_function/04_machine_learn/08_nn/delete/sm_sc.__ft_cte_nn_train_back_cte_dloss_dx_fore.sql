-- drop function if exists __ft_cte_nn_train_back_cte_dloss_dx_fore(bigint, int);
create or replace function __ft_cte_nn_train_back_cte_dloss_dx_fore
(
  i_work_no             bigint              ,
  i_cur_nn_depth        int
)
returns -- sm_sc.fv_computational_graph_serialize   return jsonb
  -- 约定：如果 i_grad_name is null, 那么返回结果有且只有唯一一条记录 where o_out_param is null，表示计算图的根结果
  table
  (
    node_no                        bigint                 ,
    node_fn_type                   varchar(64)         ,
    a_dloss_dx_fore_1st            float[]    ,
    a_dloss_dx_fore_2nd            float[]    ,
    node_fn_asso_value        float[]    ,
    node_o_m_vals                  float[]
  )
as
$$
-- declare
begin
  -- 强制开启并行
  set min_parallel_table_scan_size = 0;
  set min_parallel_index_scan_size = 0;
  set force_parallel_mode = 'on';
  set max_parallel_workers_per_gather = 6;
  set parallel_setup_cost = 0;
  set parallel_tuple_cost = 0.0;
  
  return query      
    select 
      sm_sc.tb_fore.node_no,
      sm_sc.tb_fore.node_fn_type,
      -- 链式求导
      case 
        when sm_sc.tb_fore.node_fn_type in ('agg_max', 'agg_min', 'agg_prod', 'softmax_x', 'zscore_x', 'agg_concat_x', 'agg_concat_y')
          then (sm_sc.tb_fore.node_o).m_dloss_dy
        when sm_sc.tb_fore.node_fn_type = 'prod_mx' and sm_sc.tb_back_p1.is_back_node
          then (sm_sc.tb_fore.node_o).m_dloss_dy |**| (|^~| (sm_sc.tb_fore.node_o).m_dy_d1st)
        when sm_sc.tb_fore.node_fn_type = 'conv_2d' and sm_sc.tb_back_p1.is_back_node
          then 
            sm_sc.fv_lambda_arr_dloss_dindepdt
            (
              sm_sc.tb_fore.node_no,   -- -- 
              sm_sc.tb_fore.node_fn_type                ,
              null                                ,   -- sm_sc.tb_x_fore.bi_opr_input_1st    ,
              1                                   ,
              (sm_sc.tb_fore.node_o).m_dy_d1st          ,
              sm_sc.tb_fore.node_fn_asso_value     ,
              null                                ,   -- (sm_sc.tb_fore.node_o).m_vals              ,
              (sm_sc.tb_fore.node_o).m_dloss_dy
            )            
        when sm_sc.tb_fore.node_fn_type = 'pool_max' and sm_sc.tb_back_p1.is_back_node
          then 
            sm_sc.fv_lambda_arr_dloss_dindepdt
            (
              sm_sc.tb_fore.node_no,   -- -- 
              sm_sc.tb_fore.node_fn_type                     ,
              (sm_sc.tb_fore.node_o).m_dy_d1st               , -- 此时非真实 node_o.m_dy_d1st, 仅是寄存 bi_opr_input_1st
              1                                        ,
              null                                     , 
              sm_sc.tb_fore.node_fn_asso_value          ,
              (sm_sc.tb_fore.node_o).m_vals                  ,
              (sm_sc.tb_fore.node_o).m_dloss_dy
            )
        when sm_sc.tb_fore.node_fn_type = 'pool_avg' and sm_sc.tb_back_p1.is_back_node
          then 
            sm_sc.fv_lambda_arr_dloss_dindepdt
            (
              sm_sc.tb_fore.node_no,   -- -- 
              sm_sc.tb_fore.node_fn_type                     ,
              null                                     ,
              1                                        ,
              null                                     , 
              sm_sc.tb_fore.node_fn_asso_value          ,
              (sm_sc.tb_fore.node_o).m_vals                  ,
              (sm_sc.tb_fore.node_o).m_dloss_dy
            )
        when sm_sc.tb_fore.node_fn_type = 'agg_avg' and sm_sc.tb_back_p1.is_back_node
          then 
            sm_sc.fv_lambda_arr_delta
            (
              sm_sc.tb_fore.node_no,   -- -- 
              sm_sc.tb_fore.node_fn_type            ,
              (sm_sc.tb_fore.node_o).m_dy_d1st       ,-- 此时非真实 node_o.m_dy_d1st, 仅是寄存 bi_opr_input_1st
              1                             ,
              null                          ,
              array[sm_sc.tb_fore.node_o_len :: float[]] -- -- sm_sc.tb_fore.node_fn_asso_value 
            )
        when sm_sc.tb_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new') and sm_sc.tb_back_p1.is_back_node
          then 
            sm_sc.fv_lambda_arr_dloss_dindepdt
            (
              sm_sc.tb_fore.node_no,   -- -- 
              sm_sc.tb_fore.node_fn_type                     ,
              null                                     ,
              1                                        ,
              null                                     ,
              sm_sc.tb_fore.node_fn_asso_value          ,
              null                                     ,
              (sm_sc.tb_fore.node_o).m_dloss_dy
            )
        else case when sm_sc.tb_back_p1.is_back_node then (sm_sc.tb_fore.node_o).m_dloss_dy *` (sm_sc.tb_fore.node_o).m_dy_d1st else null end
      end
        as a_dloss_dx_fore_1st,
      case
        when sm_sc.tb_fore.node_fn_type = 'prod_mx' and sm_sc.tb_back_p2.is_back_node
          then (sm_sc.tb_fore.node_o).m_dy_d2nd |**| (sm_sc.tb_fore.node_o).m_dloss_dy
        when sm_sc.tb_fore.node_fn_type = 'conv_2d' and sm_sc.tb_back_p2.is_back_node
          then
            sm_sc.fv_lambda_arr_dloss_dindepdt
            (
              sm_sc.tb_fore.node_no,   -- -- 
              sm_sc.tb_fore.node_fn_type                ,
              null                                ,
              2                                   ,
              (sm_sc.tb_fore.node_o).m_dy_d2nd          ,
              sm_sc.tb_fore.node_fn_asso_value     ,
              null                                ,
              (sm_sc.tb_fore.node_o).m_dloss_dy
            )
        when sm_sc.tb_fore.node_fn_type in ('agg_concat_y', 'agg_concat_x', 'rand_pick_y', 'rand_pick_x', 'new')
          -- 此处 (sm_sc.tb_fore.node_o).m_dy_d2nd 寄存的是反向各路节点的高宽规格 back_node_os_len
          then null
        else case when sm_sc.tb_back_p2.is_back_node then (sm_sc.tb_fore.node_o).m_dloss_dy *` (sm_sc.tb_fore.node_o).m_dy_d2nd else null end
      end
        as a_dloss_dx_fore_2nd,
      sm_sc.tb_fore.node_fn_asso_value,
      case when sm_sc.tb_fore.node_fn_type in ('agg_max', 'agg_min', 'agg_prod', 'zscore_x', 'softmax_x') then (sm_sc.tb_fore.node_o).m_vals end as node_o_m_vals
    from sm_sc.tb_nn_node sm_sc.tb_fore
    left join sm_sc.tb_nn_path sm_sc.tb_path_p1
      on sm_sc.tb_path_p1.fore_node_no = sm_sc.tb_fore.node_no 
        and sm_sc.tb_path_p1.path_ord_no = 1
        and sm_sc.tb_path_p1.work_no = i_work_no   -- 2021082501
    left join sm_sc.tb_nn_node sm_sc.tb_back_p1
      on sm_sc.tb_back_p1.node_no = sm_sc.tb_path_p1.back_node_no
        and sm_sc.tb_back_p1.work_no = i_work_no   -- 2021082501
    left join sm_sc.tb_nn_path sm_sc.tb_path_p2
      on sm_sc.tb_path_p2.fore_node_no = sm_sc.tb_fore.node_no 
        and sm_sc.tb_path_p2.path_ord_no = 2
        and sm_sc.tb_path_p2.work_no = i_work_no   -- 2021082501
    left join sm_sc.tb_nn_node sm_sc.tb_back_p2
      on sm_sc.tb_back_p2.node_no = sm_sc.tb_path_p2.back_node_no
        and sm_sc.tb_back_p2.work_no = i_work_no   -- 2021082501
    where sm_sc.tb_fore.work_no = i_work_no   -- 2021082501
      and sm_sc.tb_fore.nn_depth_no = i_cur_nn_depth
      and sm_sc.tb_fore.is_back_node
  ;
end
$$
language plpgsql volatile
parallel unsafe
cost 100000;