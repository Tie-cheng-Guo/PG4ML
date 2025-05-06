-- drop function if exists sm_sc.ft_nn_in_out_p(bigint, bigint, float[], float[], float[], float[], int[]);
create or replace function sm_sc.ft_nn_in_out_p
(
  i_work_no            bigint
, i_sess_id            bigint
, i_indepdt_01 float[]                      -- 传入的自变量比训练集的记录大一个维度，用于一次请求传入多条预测数据
, i_indepdt_02 float[] default null
, i_indepdt_03 float[] default null
, i_indepdt_04 float[] default null
, i_depdt_nos  int[]   default array[1]         -- 指定要返回的因变量序号
)
returns table 
(
  o_depdt_01   float[]
, o_depdt_02   float[]
, o_depdt_03   float[]
, o_depdt_04   float[]
)
as
$$
declare 
  -- v_model_code_6     char(6)       :=   left(md5(random()::text), 6);
  v_cur_nn_depth     int           :=   
    coalesce 
    (
      -- (select nn_depth_no from sm_sc.__vt_nn_node where work_no = i_work_no and node_type = 'prod_input' limit 1),
      (
        select 
          min(nn_depth_no)
        from sm_sc.__vt_nn_node 
        where work_no = i_work_no 
          and 
          (
             node_type = 'input_01' and i_indepdt_01 is not null
          or node_type = 'input_02' and i_indepdt_02 is not null
          or node_type = 'input_03' and i_indepdt_03 is not null
          or node_type = 'input_04' and i_indepdt_04 is not null
          )
        limit 1
      ),
      0 -- -- (select nn_depth_no from sm_sc.__vt_nn_node where work_no = i_work_no and node_type = 'input' limit 1)
    )
  ;
  v_nn_depth         int;
  v_return           float[];
  v_output_node_type varchar(64)[] :=   
    (  
      select 
        array_agg
        (
          case a_depdt_no 
            when 1 then 'output_01' 
            when 2 then 'output_02' 
            when 3 then 'output_03' 
            when 4 then 'output_04' 
          end
        )
      from unnest(i_depdt_nos) tb_a(a_depdt_no)
    )
  ;
  v_output_01        float[];
  v_output_02        float[];
  v_output_03        float[];
  v_output_04        float[];
  v_null             varchar(64)[];
begin
  
  -- 审计 sess_id 是否有效
  if not exists (select  from sm_sc.__vt_nn_sess where sess_status = '1' and work_no = i_work_no and sess_id = i_sess_id)
    and i_sess_id <> 0   -- i_sess_id = 0 用于测试，无需注册，不支持并发
  then 
    raise exception 'not exists active sess_id: %, for work_no: %.  ', i_sess_id, i_work_no;
  end if;
  
  update sm_sc.__vt_tmp_nn_node
  set 
  -- , p_node_depdt = 
  --     case node_type
  --       when 'input_01' then i_indepdt_01
  --       when 'input_02' then i_indepdt_02
  --       when 'input_03' then i_indepdt_03
  --       when 'input_04' then i_indepdt_04
  --     end
    p_node_depdt = 
      sm_sc.__fv_set_kv
      (
        case node_type
          when 'input_01' then i_indepdt_01
          when 'input_02' then i_indepdt_02
          when 'input_03' then i_indepdt_03
          when 'input_04' then i_indepdt_04
        end
      , -- v_model_code_6 || 
        '_' || work_no :: varchar  || 
        '_' || node_no :: varchar  || 
        '__d' ||  -- 'depdt'
        '_'  || substr(node_type, 7) || -- input_no
        '_' || i_sess_id :: varchar
      )
  where sess_id = i_sess_id
    and work_no = i_work_no
    and node_type like 'input_%'
  ;  
  
  -- 前向传播
  -- -- v_nn_depth := (select max(nn_depth_no) from sm_sc.__vt_tmp_nn_node where sess_id = i_sess_id and work_no = i_work_no);
  v_nn_depth := (select max(nn_depth_no) from sm_sc.__vt_tmp_nn_node where sess_id = i_sess_id and work_no = i_work_no and node_type = any(v_output_node_type));
  while v_cur_nn_depth <= v_nn_depth
  loop 
    with     
    -- 参数准备，单目、双目（三目）算子
    cte_indepdt as
    (
      select 
        tb_a_fore.node_no
      , tb_a_fore.node_fn_type
      , sm_sc.fa_coalesce(case when tb_a_path.path_ord_no = 1 then tb_a_back.p_node_depdt end) as a_bi_opr_input_1st_p
      , sm_sc.fa_coalesce(case when tb_a_path.path_ord_no = 2 then tb_a_back.p_node_depdt end) as a_bi_opr_input_2nd_p
      , sm_sc.fa_coalesce(case when tb_a_path.path_ord_no = 3 then tb_a_back.p_node_depdt end) as a_bi_opr_input_3rd_p
      from sm_sc.__vt_tmp_nn_node tb_a_fore
      inner join sm_sc.__vt_nn_path tb_a_path
        on tb_a_path.work_no = i_work_no   -- 2021082501
          and tb_a_path.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.__vt_tmp_nn_node tb_a_back
        on tb_a_back.sess_id = i_sess_id
          and tb_a_back.work_no = i_work_no   -- 2021082501
          and tb_a_back.node_no = tb_a_path.back_node_no
      -- 先处理单目、双目（三目）算子，聚合函数算子另行处理
      inner join sm_sc.tb_dic_enum tb_a_dic
        on tb_a_dic.enum_name = 'node_fn_type'
          and tb_a_dic.enum_key = tb_a_fore.node_fn_type
          and tb_a_dic.enum_group in ('1_p', '2_p', '3_p')
      where tb_a_fore.sess_id = i_sess_id
        and tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
      group by tb_a_fore.node_no, tb_a_fore.node_fn_type
    )
    update sm_sc.__vt_tmp_nn_node tb_a_tar_depdt
    set 
      p_node_depdt = 
        sm_sc.fv_lambda_arr_p
        (
          ''
        , i_work_no
        , tb_a_indepdt_fore.node_no
        , i_sess_id
        , tb_a_tar_depdt.node_fn_type
        , tb_a_indepdt_fore.a_bi_opr_input_1st_p
        , tb_a_indepdt_fore.a_bi_opr_input_2nd_p
        , tb_a_tar_depdt.node_fn_asso_value
        , tb_a_indepdt_fore.a_bi_opr_input_3rd_p
        )
    from cte_indepdt tb_a_indepdt_fore
    where tb_a_tar_depdt.sess_id = i_sess_id
      and tb_a_tar_depdt.work_no = i_work_no   -- 2021082501
      and tb_a_indepdt_fore.node_no = tb_a_tar_depdt.node_no
    ;      
    
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
        , -- v_model_code_6 || 
          '_' || i_work_no :: varchar   ||
          '_' || tb_a_fore.node_no :: varchar ||
          '__d_aggr_'
        )
        as a_opr_depdt_p
      from sm_sc.__vt_tmp_nn_node tb_a_fore
      inner join sm_sc.__vt_nn_path tb_a_path
        on tb_a_path.work_no = i_work_no   -- 2021082501
          and tb_a_path.fore_node_no = tb_a_fore.node_no
      inner join sm_sc.__vt_tmp_nn_node tb_a_back
        on tb_a_back.sess_id = i_sess_id
          and tb_a_back.work_no = i_work_no   -- 2021082501
          and tb_a_back.node_no = tb_a_path.back_node_no
      -- 先处理单目、双目（三目）算子，聚合函数算子另行处理
      inner join sm_sc.tb_dic_enum tb_a_dic
        on tb_a_dic.enum_name = 'node_fn_type'
          and tb_a_dic.enum_key = tb_a_fore.node_fn_type
          and tb_a_dic.enum_group = 'n_p'
      where tb_a_fore.sess_id = i_sess_id
        and tb_a_fore.work_no = i_work_no   -- 2021082501
        and tb_a_fore.nn_depth_no = v_cur_nn_depth
      group by tb_a_fore.node_no, tb_a_fore.node_fn_type
    )
    update sm_sc.__vt_tmp_nn_node tb_a_tar_depdt
    set 
      p_node_depdt = tb_a_indepdt_fore.a_opr_depdt_p
    from cte_indepdt tb_a_indepdt_fore
    where tb_a_tar_depdt.sess_id = i_sess_id
      and tb_a_tar_depdt.work_no = i_work_no   -- 2021082501
      and tb_a_indepdt_fore.node_no = tb_a_tar_depdt.node_no
    ;
    -- commit;
    
    -- 清理当前层前向传播后的无用张量 kv
    -- 清理 depdt
    with 
    cte_clear_kv_list as 
    (
      select
        tb_a_back_node.node_no
      , max(tb_a_back_node.p_node_depdt) as p_node_depdt
      from sm_sc.__vt_tmp_nn_node tb_a_main_fore_node
      inner join sm_sc.__vt_nn_path tb_a_main_path
        on tb_a_main_path.fore_node_no = tb_a_main_fore_node.node_no 
          and tb_a_main_path.work_no = i_work_no
      inner join sm_sc.__vt_tmp_nn_node tb_a_back_node
        on tb_a_back_node.node_no = tb_a_main_path.back_node_no
          and tb_a_back_node.work_no = i_work_no
      inner join sm_sc.tb_dic_enum tb_a_back_dic 
        on tb_a_back_dic.enum_name = 'node_fn_type_delta_method'
          and tb_a_back_dic.enum_key = tb_a_back_node.node_fn_type
          and substr(tb_a_back_dic.enum_value, 5, 2) = '00'  -- 第一/二目求导不需要因变量
      inner join sm_sc.__vt_nn_path tb_a_path
        on tb_a_path.work_no = i_work_no
          and tb_a_path.back_node_no = tb_a_back_node.node_no
      inner join sm_sc.__vt_tmp_nn_node tb_a_fore_node
        on tb_a_fore_node.work_no = i_work_no
          and tb_a_fore_node.node_no = tb_a_path.fore_node_no
      where tb_a_main_fore_node.work_no = i_work_no
        and tb_a_main_fore_node.nn_depth_no = v_cur_nn_depth
      group by tb_a_back_node.node_no 
      having max(tb_a_fore_node.nn_depth_no) <= v_cur_nn_depth
    ),
    cte_upd_node_k_2_null as 
    (
      update sm_sc.__vt_tmp_nn_node tb_a_back_node
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
    
    v_cur_nn_depth := v_cur_nn_depth + 1;

  end loop;
  
-- -- debug
-- raise notice 'row_cnt: %', (select count(*) from sm_sc.__vt_tmp_nn_node where sess_id = i_sess_id and work_no = i_work_no);

  -- 准备输出结构。当前先逐个输出结构赋值，期待 pg unpivot
  select 
    sm_sc.__fv_get_kv(p_node_depdt)
  into 
    v_output_01
  from sm_sc.__vt_tmp_nn_node
  where sess_id = i_sess_id
    and work_no = i_work_no
    and node_type = 'output_01'
  ;
  select 
    sm_sc.__fv_get_kv(p_node_depdt)
  into 
    v_output_02
  from sm_sc.__vt_tmp_nn_node
  where sess_id = i_sess_id
    and work_no = i_work_no
    and node_type = 'output_02'
  ;
  select 
    sm_sc.__fv_get_kv(p_node_depdt)
  into 
    v_output_03
  from sm_sc.__vt_tmp_nn_node
  where sess_id = i_sess_id
    and work_no = i_work_no
    and node_type = 'output_03'
  ;
  select 
    sm_sc.__fv_get_kv(p_node_depdt)
  into 
    v_output_04
  from sm_sc.__vt_tmp_nn_node
  where sess_id = i_sess_id
    and work_no = i_work_no
    and node_type = 'output_04'
  ;
  
  -- -- 清理 session 数据
  -- delete from sm_sc.__vt_tmp_nn_node 
  -- where sess_id = i_sess_id
  --   -- -- and work_no = i_work_no
  -- ;
  
  -- 清理 kv 张量: depdt
  perform 
    sm_sc.__fv_delete_kv
    (
      array_agg(p_node_depdt)
    )
  from sm_sc.__vt_tmp_nn_node 
  where work_no = i_work_no
    and node_type <> 'weight'
    and node_fn_type <> '00_const'
    and sess_id = i_sess_id
  ;
  update sm_sc.__vt_tmp_nn_node
  set 
    p_node_depdt        = null
  where work_no = i_work_no
    and node_type <> 'weight'
    and node_fn_type <> '00_const'
    and sess_id = i_sess_id
  ;  

  -- 返回结果
  return query
    select 
      v_output_01
    , v_output_02
    , v_output_03
    , v_output_04
  ;
  
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- -- set min_parallel_table_scan_size = 8;
-- -- set min_parallel_index_scan_size = 16;
-- -- set force_parallel_mode = 'off';
-- -- set max_parallel_workers_per_gather = 1;
-- -- set parallel_setup_cost = 10000;
-- -- set parallel_tuple_cost = 10000.0;

-- -- 不支持开并行，务必关闭并行后执行 sm_sc.ft_nn_in_out_p
-- select 
--   o_depdt_01
-- from
--   sm_sc.ft_nn_in_out_p
--   (
--     -54321   --2021112502, 
--   , array[[0.0, 0.0]] :: float[]
--       +` sm_sc.fv_new_randn(0.0 :: float, 0.1, array[1, 2])
--   ) tb_a