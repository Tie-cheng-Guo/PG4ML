-- drop function if exists sm_sc.ufv_upd_att_ffn_chunk(bigint, bigint, int, int);
create or replace function sm_sc.ufv_upd_att_ffn_chunk
(
  
  i_work_no                            bigint
, i_combine_no                         bigint
, i_w_ff1_heigh_ff2_width              int    -- 通常对应 attention_qkv 的 i_v_width 
                                              -- 或多头的 i_v_width 的 concat
                                              -- 或 i_token_embedding_len
, i_w_ff1_width_ff2_heigh              int
)
returns void
as 
$$
-- declare 
begin
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[1] = i_w_ff1_heigh_ff2_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 3
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][1] = i_w_ff1_heigh_ff2_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 9
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2] = i_w_ff1_heigh_ff2_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 4
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][2] = i_w_ff1_heigh_ff2_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 10
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[3] = i_w_ff1_heigh_ff2_width
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 2
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[1] = i_w_ff1_width_ff2_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 6
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][1] = i_w_ff1_width_ff2_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 10
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2] = i_w_ff1_width_ff2_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no in (3, 7)
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[2][2] = i_w_ff1_width_ff2_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 9
  ;
  update sm_sc.__vt_tmp_nn_node
  set node_fn_asso_value[3] = i_w_ff1_width_ff2_heigh
  where work_no = i_work_no
    and node_grp_no = i_combine_no
    and node_grp_ord_no = 4
  ;
end
$$
language plpgsql stable
parallel safe
;

-- select 
--   sm_sc.ufv_upd_att_ffn_chunk
--   (
--     -9                                -- i_work_no   
--   , -99                               -- i_combine_no
--   , 64                                -- i_w_ff1_heigh_ff2_width  
--   , 64                                -- i_w_ff1_width_ff2_heigh   
--   )
