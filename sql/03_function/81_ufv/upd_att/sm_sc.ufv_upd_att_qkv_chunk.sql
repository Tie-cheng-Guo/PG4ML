-- drop function if exists sm_sc.ufv_upd_att_qkv_chunk(bigint, bigint, int, int, int, int);
create or replace function sm_sc.ufv_upd_att_qkv_chunk
(
  i_work_no                               bigint
, i_combine_no                            bigint
, i_seq_len                               int
, i_qk_width                              int
, i_kv_heigh                              int
, i_v_width                               int
)
returns void
as 
$$
-- declare 
begin
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[1] = i_seq_len
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (4, 5, 6, 8, 9, 14)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][1] = i_seq_len
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 18
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2] = i_qk_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (1, 2, 8)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][2] = i_qk_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (15, 16)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[3] = i_qk_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (4, 5)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2] = i_kv_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (9, 14)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][2] = i_kv_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 18
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[3] = i_kv_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (8, 13)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2] = i_v_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 3
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][2] = i_v_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 17
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[3] = i_v_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (6, 14)
  ;
end
$$
language plpgsql stable
parallel safe
;

-- select 
--   sm_sc.ufv_upd_att_qkv_chunk
--   (
--     -9                                -- i_work_no   
--   , -99                               -- i_combine_no
--   , 40                                -- i_seq_len   
--   , 64                                -- i_qk_width  
--   , 64                                -- i_kv_heigh  
--   , 64                                -- i_v_width   
--   )
