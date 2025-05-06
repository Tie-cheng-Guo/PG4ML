-- drop function if exists __ft_cte_nn_train_fore_cte_x(bigint, int, int, int);
create or replace function __ft_cte_nn_train_fore_cte_x
(
  i_work_no             bigint              ,
  i_cur_nn_depth        int                 ,
  i_cur_learn_cnt        int                 ,
  i_learn_cnt_init       int
)
returns -- sm_sc.fv_computational_graph_serialize   return jsonb
  -- 约定：如果 i_grad_name is null, 那么返回结果有且只有唯一一条记录 where o_out_param is null，表示计算图的根结果
  table
  (
    node_no                        bigint                 ,
    node_fn_type                   varchar(64)         ,
    pick_depdt_idx                     int4multirange[]     ,
    fore_cnt                       int              ,
    bi_opr_input_1st               float[]    ,
    bi_opr_input_2nd               float[]    ,
    back_node_os_len               int[]               ,
    is_bi_opr_input_1st_back       boolean             ,
    is_bi_opr_input_2nd_back       boolean             ,
    heavy_cost_lambda              float[]
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
      case 
        when sm_sc.tb_fore.node_fn_type = 'agg_concat_y' 
          then sm_sc.fa_range_or(sm_sc.tb_back.pick_depdt_idx order by sm_sc.tb_path.path_ord_no) filter(where sm_sc.tb_fore.node_fn_type = 'agg_concat_y')
        when sm_sc.tb_fore.node_fn_type = 'agg_concat_x' 
          then sm_sc.fa_range_or(distinct sm_sc.tb_back.pick_depdt_idx) filter(where sm_sc.tb_fore.node_fn_type = 'agg_concat_x')
        -- -- -- 几个输出矩阵高宽规格改变的特殊 fn, 规约按照第一目作为输入数据集高度规格
        -- -- when sm_sc.tb_fore.node_fn_type in ('conv_2d', 'prod_mx')
        else sm_sc.fa_range_or(case when sm_sc.tb_path.path_ord_no = 1 then sm_sc.tb_back.pick_depdt_idx end) filter(where sm_sc.tb_fore.node_fn_type not in ('agg_concat_y', 'agg_concat_x'))
      end as pick_depdt_idx,
      count(sm_sc.tb_path.back_node_no) as fore_cnt,   -- 用于后续单双目判断

      -- 聚合后的入参归并结果当作单目运算唯一参数
      -- 另一个同类型的限制是，一个CASE无法阻止其所包含的聚集表达式 的计算...取而代之的是，可以使用 一个WHERE或FILTER子句来首先阻止有问题的输入行到达 一个聚集函数。
      --   http://postgres.cn/docs/12/sql-expressions.html
      -- 对于以下 bi_opr_input_1st, bi_opr_input_2nd, 采用 filter 过滤掉必要的聚合输入，达到减少聚合计算以及入参宽高一致性保证等安全问题
      case 
        when sm_sc.tb_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new')
          then 
            sm_sc.fv_lambda_arr
            (
              sm_sc.tb_fore.node_no, -- --
              sm_sc.tb_fore.node_fn_type,
              max((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new')),
              null,
              max(sm_sc.tb_fore.node_fn_asso_value[1 : 1]) filter(where sm_sc.tb_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x', 'new'))
            )
        when sm_sc.tb_fore.node_fn_type = 'agg_concat_y'
          then sm_sc.fa_mx_concat_y((sm_sc.tb_back.node_o).m_vals order by sm_sc.tb_path.path_ord_no) filter(where sm_sc.tb_fore.node_fn_type = 'agg_concat_y')
        when sm_sc.tb_fore.node_fn_type = 'agg_concat_x'
          then sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals order by sm_sc.tb_path.path_ord_no) filter(where sm_sc.tb_fore.node_fn_type = 'agg_concat_x')
        when sm_sc.tb_fore.node_fn_type = 'agg_sum'  -- 求导时，只需要自变量高宽
          then sm_sc.fa_mx_sum((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_fore.node_fn_type = 'agg_sum')
        when sm_sc.tb_fore.node_fn_type = 'agg_avg'  -- 求导时，只需要自变量高宽
          then sm_sc.fa_mx_avg((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_fore.node_fn_type = 'agg_avg')
        when sm_sc.tb_fore.node_fn_type = 'agg_max'
          then sm_sc.fa_mx_max((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_fore.node_fn_type = 'agg_max') -- -- -- 记录最值所在 path_no 矩阵到协参，可设计 sm_sc.fa_mx_max_ex 的输出为 sm_sc.fa_mx_max_ex 的输出 concat 其位置矩阵
        when sm_sc.tb_fore.node_fn_type = 'agg_min'
          then sm_sc.fa_mx_min((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_fore.node_fn_type = 'agg_min') -- -- -- 记录最值所在 path_no 矩阵到协参，可设计 sm_sc.fa_mx_min_ex 的输出为 sm_sc.fa_mx_min_ex 的输出 concat 其位置矩阵
        when sm_sc.tb_fore.node_fn_type = 'agg_prod'
          then sm_sc.fa_mx_prod((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_fore.node_fn_type = 'agg_prod')
        when sm_sc.tb_fore.node_fn_type not like 'agg_%' and sm_sc.tb_fore.node_fn_type not in ('rand_pick_y', 'rand_pick_x', 'new')
          then sm_sc.fa_mx_concat_x(case when sm_sc.tb_path.path_ord_no = 1 then (sm_sc.tb_back.node_o).m_vals end) filter(where sm_sc.tb_fore.node_fn_type not like 'agg_%')
      end as bi_opr_input_1st
      ,
      case 
        when sm_sc.tb_fore.node_fn_type not like 'agg_%' and count(sm_sc.tb_path.back_node_no) = 2
          then sm_sc.fa_mx_concat_x(case when sm_sc.tb_path.path_ord_no = 2 then (sm_sc.tb_back.node_o).m_vals end) filter(where sm_sc.tb_fore.node_fn_type not like 'agg_%' and sm_sc.tb_fore.node_fn_type not in ('add', 'sub'))
      end as bi_opr_input_2nd
      ,
      case
        when sm_sc.tb_fore.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub')
          then array[array[max(sm_sc.tb_fore.node_depdt_len[1]) filter(where sm_sc.tb_fore.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub')), max(sm_sc.tb_fore.node_depdt_len[2]) filter(where sm_sc.tb_fore.node_fn_type in ('agg_sum', 'agg_avg', 'add', 'sub'))]]
        when sm_sc.tb_fore.node_fn_type in ('agg_concat_x', 'agg_concat_y')
          then array_agg(sm_sc.tb_back.node_depdt_len order by sm_sc.tb_path.path_ord_no) filter(where sm_sc.tb_fore.node_fn_type in ('agg_concat_x', 'agg_concat_y'))
        when sm_sc.tb_fore.node_fn_type = 'slice_x'   -- 暂不支持多区间切片
          then array[array[max(sm_sc.tb_back.node_depdt_len[1]) filter(where sm_sc.tb_fore.node_fn_type = 'slice_x'), max(sm_sc.tb_back.node_depdt_len[2]) filter(where sm_sc.tb_fore.node_fn_type = 'slice_x')]]
        when sm_sc.tb_fore.node_fn_type = 'slice_y'   -- 暂不支持多区间切片
          then array[array[max(sm_sc.tb_back.node_depdt_len[1]) filter(where sm_sc.tb_fore.node_fn_type = 'slice_y'), max(sm_sc.tb_back.node_depdt_len[2]) filter(where sm_sc.tb_fore.node_fn_type = 'slice_y')]]
      end as back_node_os_len
      ,
      -- 审计算子第一入参是否有必要求导，如果其反向节点不参与反向传播，那么不必要
      case 
        when sm_sc.tb_fore.node_fn_type not like 'agg_%'
          then (sm_sc.fa_mx_or(case when sm_sc.tb_path.path_ord_no = 1 then array[sm_sc.tb_back.is_back_node] else array[false] end))[1]
        else true
      end as is_bi_opr_input_1st_back
      ,
      -- 审计算子第二入参是否有必要求导，如果其反向节点不参与反向传播，那么不必要
      case 
        when sm_sc.tb_fore.node_fn_type not like 'agg_%'
          then (sm_sc.fa_mx_or(case when sm_sc.tb_path.path_ord_no = 2 then array[sm_sc.tb_back.is_back_node] else array[false] end))[1]
        else true
      end as is_bi_opr_input_2nd_back
      ,
      -- 将开销大的 prod_mx, conv_2d 集中在本 query, 便于并行与分布式改造
      case sm_sc.tb_fore.node_fn_type
        -- -- when sm_sc.tb_fore.node_fn_type in ('prod_mx', 'conv_2d')
        when 'prod_mx'
          then 
            sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_path.path_ord_no = 1 and sm_sc.tb_fore.node_fn_type = 'prod_mx')
            |**| sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_path.path_ord_no = 2 and sm_sc.tb_fore.node_fn_type = 'prod_mx')
        when 'conv_2d'
          then 
            -- -- sm_sc.fv_lambda_arr
            -- -- (
            -- --   sm_sc.tb_fore.node_no,  -- -- 
            -- --   sm_sc.tb_fore.node_fn_type,
            -- --   sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_path.path_ord_no = 1 and sm_sc.tb_fore.node_fn_type = 'conv_2d'),
            -- --   sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_path.path_ord_no = 2 and sm_sc.tb_fore.node_fn_type = 'conv_2d'),
            -- --   sm_sc.fa_mx_coalesce(sm_sc.tb_fore.node_fn_asso_value)
            -- -- )  
            sm_sc.fv_conv_2d_grp_x
            (
              sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_path.path_ord_no = 1 and sm_sc.tb_fore.node_fn_type = 'conv_2d'),   
              (sm_sc.fa_mx_coalesce(sm_sc.tb_fore.node_fn_asso_value))[1] :: int                                              ,   -- 规约：存放 i_1d_2_2d_cnt_per_grp
              sm_sc.fa_mx_concat_x((sm_sc.tb_back.node_o).m_vals) filter(where sm_sc.tb_path.path_ord_no = 2 and sm_sc.tb_fore.node_fn_type = 'conv_2d'),   
              (sm_sc.fa_mx_coalesce(sm_sc.tb_fore.node_fn_asso_value))[3] :: int                                              ,   -- 规约：存放 i_window_len_x 
              coalesce((sm_sc.fa_mx_coalesce(sm_sc.tb_fore.node_fn_asso_value))[4 : 5] :: int[]       ,array[1, 1]      )     ,   -- 规约：存放 i_stride       
              coalesce((sm_sc.fa_mx_coalesce(sm_sc.tb_fore.node_fn_asso_value))[6 : 9] :: int[]       ,array[0, 0, 0, 0])     ,   -- 规约：存放 i_padding      
              coalesce((sm_sc.fa_mx_coalesce(sm_sc.tb_fore.node_fn_asso_value))[10] :: float ,0.0              )         -- 规约：存放 i_padding_value
            )
      end as heavy_cost_lambda
    from sm_sc.tb_nn_node sm_sc.tb_fore
    inner join sm_sc.tb_nn_path sm_sc.tb_path
      on sm_sc.tb_path.work_no = i_work_no   -- 2021082501
        and sm_sc.tb_path.fore_node_no = sm_sc.tb_fore.node_no
    inner join sm_sc.tb_nn_node sm_sc.tb_back
      on sm_sc.tb_back.work_no = i_work_no   -- 2021082501
        and sm_sc.tb_back.node_no = sm_sc.tb_path.back_node_no
    where sm_sc.tb_fore.work_no = i_work_no   -- 2021082501
      and sm_sc.tb_fore.nn_depth_no = i_cur_nn_depth
      and (sm_sc.tb_fore.is_fore_node is true or i_cur_learn_cnt = i_learn_cnt_init)
    group by sm_sc.tb_fore.node_no, sm_sc.tb_fore.node_fn_type
  ;
end
$$
language plpgsql volatile
parallel unsafe
cost 100000;