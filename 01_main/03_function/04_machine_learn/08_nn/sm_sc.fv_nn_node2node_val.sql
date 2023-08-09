-- drop function if exists sm_sc.fv_nn_node2node_val(bigint, bigint, bigint);
create or replace function sm_sc.fv_nn_node2node_val
(
  i_work_no            bigint,
  i_begin_node_no       bigint,
  i_end_node_no       bigint
)
returns float[]
as 
$$
declare
  v_sess_id            bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)   :=  replace(gen_random_uuid()::char(36), '-', '')::char(32);
  v_cur_depth_no       int;
  v_begin_depth_no     int        :=  (select nn_depth_no from sm_sc.tb_nn_node where work_no = i_work_no and node_no = i_begin_node_no);
  v_end_depth_no       int        :=  (select nn_depth_no from sm_sc.tb_nn_node where work_no = i_work_no and node_no = i_end_node_no);
  v_ret                float[];
  
begin
  insert into sm_sc.__vt_tmp_node_node2node
  (
    sess_id      ,
    work_no      ,
    node_no      ,
    node_type
  )
  select 
    v_sess_id                          ,
    i_work_no                          ,
    fore_node_no                       ,
    max(node_type) as node_type
  from sm_sc.ft_nn_node2node_path(i_work_no, i_begin_node_no, i_end_node_no) tb_a(back_node_no, fore_node_no, path_ord_no, node_type)
  -- where node_type = 'nn_main'
  group by fore_node_no
  ;

  for v_cur_depth_no in v_begin_depth_no .. v_end_depth_no
  loop
    with 
    cte_aggr_o as 
    (
      select 
        tb_a_node_tar.node_no,
        max(tb_a_node_fore_dic.node_fn_type) as node_fn_type,
        case
          -- when max(tb_a_node_fore_dic.node_fn_type) in ('rand_pick_y', 'rand_pick_x', 'new')
          --   then sm_sc.fa_mx_coalesce((tb_a_node_back_dic.node_o).m_vals)
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_concat_y'
            then sm_sc.fa_mx_concat_y((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_concat_y')
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_concat_x'
            then sm_sc.fa_mx_concat_x((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_concat_x')
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_sum'
            then sm_sc.fa_mx_sum((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_sum')
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_avg'
            then sm_sc.fa_mx_avg((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_avg')
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_max'
            then sm_sc.fa_mx_max((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_max')
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_min'
            then sm_sc.fa_mx_min((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_min')
          when max(tb_a_node_fore_dic.node_fn_type) = 'agg_prod'
            then sm_sc.fa_mx_prod((tb_a_node_back_dic.node_o).m_vals order by tb_a_path.path_ord_no)
              filter(where tb_a_node_fore_dic.node_fn_type = 'agg_prod')
          else sm_sc.fa_mx_coalesce(case when tb_a_path.path_ord_no = 1 then (tb_a_node_back_dic.node_o).m_vals else null end order by tb_a_path.path_ord_no)
              filter(where tb_a_path.path_ord_no = 1)
        end as a_back_o_s_1st,
        sm_sc.fa_mx_coalesce(case when tb_a_path.path_ord_no = 2 then (tb_a_node_back_dic.node_o).m_vals else null end order by tb_a_path.path_ord_no) 
              filter(where tb_a_path.path_ord_no = 2)as a_back_o_s_2nd,
        sm_sc.fa_mx_coalesce(tb_a_node_fore_dic.node_fn_asso_value) as node_fn_asso_value
      from sm_sc.__vt_tmp_node_node2node tb_a_node_tar
      inner join sm_sc.tb_nn_node tb_a_node_fore_dic
        on tb_a_node_tar.node_no = tb_a_node_fore_dic.node_no
      inner join sm_sc.tb_nn_path tb_a_path
        on tb_a_path.fore_node_no = tb_a_node_fore_dic.node_no
      inner join sm_sc.tb_nn_node tb_a_node_back_dic
        on tb_a_node_back_dic.node_no = tb_a_path.back_node_no
      where tb_a_node_tar.node_type = 'nn_main'
        and tb_a_node_fore_dic.work_no = i_work_no
        and tb_a_node_tar.work_no = i_work_no
        and tb_a_path.work_no = i_work_no
        and tb_a_node_tar.sess_id = v_sess_id
        and tb_a_node_fore_dic.nn_depth_no = v_cur_depth_no
      group by tb_a_node_tar.node_no, tb_a_node_tar.sess_id
    )
    update sm_sc.__vt_tmp_node_node2node tb_a_node_tar
    set 
      node_y_vals = 
        case 
          when node_fn_type like 'agg_%'
            then tb_a_sour.a_back_o_s_1st
          else          
            sm_sc.fv_lambda_arr
            (
              tb_a_node_tar.node_no, 
              tb_a_sour.node_fn_type, 
              tb_a_sour.a_back_o_s_1st, 
              tb_a_sour.a_back_o_s_2nd,
              tb_a_sour.node_fn_asso_value
            )
        end
    from cte_aggr_o tb_a_sour
    where tb_a_node_tar.node_type = 'nn_main'
      and tb_a_node_tar.node_no = tb_a_sour.node_no
      and tb_a_node_tar.sess_id = v_sess_id
    ;
  end loop;
  
  select 
    node_y_vals into v_ret 
  from sm_sc.__vt_tmp_node_node2node
  where sess_id = v_sess_id
    and node_no = i_end_node_no
  ;  
  delete from sm_sc.__vt_tmp_node_node2node
  where sess_id = v_sess_id
  ;  
  return v_ret;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select sm_sc.fv_nn_node2node_val(2022030501, 103010025, 106020001)