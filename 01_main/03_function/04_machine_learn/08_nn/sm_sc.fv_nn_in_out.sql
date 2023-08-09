-- drop function if exists sm_sc.fv_nn_in_out(float[]);
create or replace function sm_sc.fv_nn_in_out
(
  i_work_no     bigint                ,
  i_in          float[]
)
returns float[]
as
$$
declare 
  v_session_id      bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)   :=   replace(gen_random_uuid()::char(36), '-', '')::char(32);
  v_cur_nn_depth    int           :=   
    coalesce 
    (
      (select nn_depth_no from sm_sc.__vt_nn_node where work_no = i_work_no and node_type = 'prod_input' limit 1),
      0 -- -- (select nn_depth_no from sm_sc.__vt_nn_node where work_no = i_work_no and node_type = 'input' limit 1)
    )
  ;
  v_nn_depth        int;
  v_return          float[];
begin
  -- -- -- 审计 session 结构
  -- -- create temp table if not exists sm_sc.__vt_tmp_nn_node
  -- -- (
  -- --   sess_id                 varchar(32),
  -- --   work_no                 bigint,           
  -- --   node_no                 bigint   ,           
  -- --   node_type               varchar(64)  ,    
  -- --   node_fn_type            varchar(64)  ,    
  -- --   node_fn_asso_value float[], 
  -- --   nn_depth_no             int  ,  
  -- --   node_y_vals              float[],
  -- --   primary key (sess_id, work_no, node_no)
  -- -- )
  -- -- ;
  
  -- 创建 session 
  insert into sm_sc.__vt_tmp_nn_node
  (
    sess_id                        ,
    work_no                        ,
    node_no                        ,
    node_type                      ,
    node_fn_type                   ,
    node_fn_asso_value        ,
    nn_depth_no                    ,
    node_y_vals             
  )
  select 
    v_session_id                    ,
    work_no                         ,
    node_no                         ,
    node_type                       ,
    node_fn_type                    ,
    node_fn_asso_value         ,
    nn_depth_no                     ,
    case node_type
      when 'prod_input' 
        then i_in
      when 'input' 
        then i_in
      when 'offset'
        then array[array[1]]
      when 'weight'
        then node_y_vals
    end             
  from sm_sc.__vt_nn_node
  where work_no = i_work_no
  ;
  -- commit;
  
  -- 前向传播
  v_nn_depth := (select max(nn_depth_no) from sm_sc.__vt_tmp_nn_node where sess_id = v_session_id and work_no = i_work_no);
  while v_cur_nn_depth < v_nn_depth
  loop 
    v_cur_nn_depth := v_cur_nn_depth + 1;
    with 
    cte_x as
    (
      select 
        tb_a_fore.node_no, 
        tb_a_fore.node_fn_type,
        count(tb_a_path.back_node_no) as fore_cnt,   -- 用于后续单双目判断
          -- 聚合后的入参归并结果当作单目运算唯一参数
        case 
          when tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x')
            then 
              sm_sc.fv_lambda_arr
              (
                null,
                tb_a_fore.node_fn_type,
                max(tb_a_back.node_y_vals) filter(where tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x')),
                null,
                max(tb_a_fore.node_fn_asso_value[1 : 1]) filter(where tb_a_fore.node_fn_type in ('rand_pick_y', 'rand_pick_x'))
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
          when tb_a_fore.node_fn_type not like 'agg_%' and tb_a_fore.node_fn_type not in ('rand_pick_y', 'rand_pick_x')
            then sm_sc.fa_mx_concat_x(case when tb_a_path.path_ord_no = 1 then tb_a_back.node_y_vals end) filter(where tb_a_fore.node_fn_type not like 'agg_%')
        end as bi_opr_input_1st
        ,
        case 
          when tb_a_fore.node_fn_type not like 'agg_%' and count(tb_a_path.back_node_no) = 2
            then sm_sc.fa_mx_concat_x(case when tb_a_path.path_ord_no = 2 then tb_a_back.node_y_vals end) filter(where tb_a_fore.node_fn_type not like 'agg_%' and tb_a_fore.node_fn_type not in ('add', 'sub'))
        end as bi_opr_input_2nd
      from sm_sc.__vt_tmp_nn_node tb_a_fore
      inner join sm_sc.tb_nn_path tb_a_path
        on tb_a_path.work_no = i_work_no   -- 2021082501
          and tb_a_path.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.__vt_tmp_nn_node tb_a_back
        on tb_a_back.sess_id = v_session_id
          and tb_a_back.work_no = i_work_no   -- 2021082501
          and tb_a_back.node_no = tb_a_path.back_node_no
      where tb_a_fore.sess_id = v_session_id
        and tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
      group by tb_a_fore.node_no, tb_a_fore.node_fn_type
    )
    update sm_sc.__vt_tmp_nn_node tb_a_tar_y
    set 
      node_y_vals = 
        case        
          -- 聚合已经在 cte_x 中，计算出来
          when tb_a_x_fore.node_fn_type = 'rand_pick_y'
            then tb_a_x_fore.bi_opr_input_1st[ : ][ : array_length(tb_a_x_fore.bi_opr_input_1st, 2) - 1]
          when tb_a_x_fore.node_fn_type = 'rand_pick_x'
            then tb_a_x_fore.bi_opr_input_1st[ : array_length(tb_a_x_fore.bi_opr_input_1st, 1) - 1][ : ]
          -- -- when tb_a_x_fore.fore_cnt = 2 and tb_a_tar_y.node_fn_type = 'prod_mx'
          -- --   -- -- -- 鉴于 x 来自海量数据样本，会是个高表，所以采用 x ** w 形式计算，而不是 w转置 ** x转置 的转置
          -- --   then tb_a_x_fore.bi_opr_input_1st |**| tb_a_x_fore.bi_opr_input_2nd
          when tb_a_x_fore.node_fn_type like 'agg_%'
            then tb_a_x_fore.bi_opr_input_1st
          -- 其他单目、双目运算，则调用 lambda
          else 
            sm_sc.fv_lambda_arr
            (
              null, 
              tb_a_tar_y.node_fn_type,
              tb_a_x_fore.bi_opr_input_1st,
              tb_a_x_fore.bi_opr_input_2nd,
              tb_a_tar_y.node_fn_asso_value
            )  
        end
    from cte_x tb_a_x_fore
    where tb_a_tar_y.sess_id = v_session_id
      and tb_a_tar_y.work_no = i_work_no   -- 2021082501
      and tb_a_x_fore.node_no = tb_a_tar_y.node_no
    ;      
    -- commit;
  end loop;
  
-- -- debug
-- raise notice 'row_cnt: %', (select count(*) from sm_sc.__vt_tmp_nn_node where sess_id = v_session_id and work_no = i_work_no);

  -- 返回结果
  with 
  cte_delete as 
  (
    -- 清理 session 数据
    delete from sm_sc.__vt_tmp_nn_node 
    where sess_id = v_session_id
      -- -- and work_no = i_work_no
    returning work_no, node_type, node_y_vals
  )
  select node_y_vals into v_return from sm_sc.__vt_tmp_nn_node
  where work_no = i_work_no
      and node_type = 'output'
  ;
  return v_return;
  -- commit;
  
end
$$
language plpgsql volatile
parallel unsafe
cost 100;

-- -- set min_parallel_table_scan_size = 8;
-- -- set min_parallel_index_scan_size = 16;
-- -- set force_parallel_mode = 'off';
-- -- set max_parallel_workers_per_gather = 1;
-- -- set parallel_setup_cost = 10000;
-- -- set parallel_tuple_cost = 10000.0;

-- -- 不支持开并行，务必关闭并行后执行 sm_sc.fv_nn_in_out
-- select 
--   sm_sc.fv_nn_in_out
--   (
--     2021112502, 
--     array[array[0.0 :: float, 0.0], array[0.0 :: float, 1.0], array[1.0 :: float, 0.0], array[1.0 :: float, 1.0]] 
--       +` sm_sc.fv_new_randn(0.0 :: float, 0.1, array[4, 2])
--   )