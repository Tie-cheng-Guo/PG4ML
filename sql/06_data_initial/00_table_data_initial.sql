-- 初始化全局序列值
insert into sm_sc.__vt_global_seq(seq_no, cur_val) select 1, 1
on conflict (seq_no) do nothing
;
-- ---------------------------------------------------------------------------------------------------------------------

-- 初始化字典表
-- -------------------------------------------------------------------------
-- loss_fn_type  -- 损失函数类型
-- delete from sm_sc.tb_dic_enum where enum_name = 'loss_fn_type';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_order
)
with cte_loss_fn_type(enum_key, enum_value) as
(
            select '101', '最小二乘法'        
  union all select '201', '交叉熵    '        
  union all select '202', '交叉熵第二维度平均'
  union all select '203', '交叉熵。真实值入参是 onehot 编码的编号，而不是 onehot 编码本身'
  union all select '301', 'L1'
)
select 
  'loss_fn_type' as enum_name, 
  enum_key, 
  enum_value, 
  row_number() over() 
    + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'loss_fn_type'), 0) 
  as enum_order
from cte_loss_fn_type
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_order = excluded.enum_order
;

-- -------------------------------------------------------------------------
-- node_type   -- nn 节点类型
-- delete from sm_sc.tb_dic_enum where enum_name = 'node_type';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_order
)
with cte_node_type(enum_key, enum_value) as
(
  select 'input_01', 'input_01' union all   -- 规约：整个 nn 的小批量采样以该节点配置为准。缺省情况下，该配置产生的采样清单也同时更新到 input_02, input_03, input_04
  select 'input_02', 'input_02' union all   -- 规约：保持没有随机小批量采样配置即可。如果没有额外更新逻辑，该节点数据采样与 input_01 一致。不一致场景要额外编写逻辑。
  select 'input_03', 'input_03' union all   -- 规约：保持没有随机小批量采样配置即可。如果没有额外更新逻辑，该节点数据采样与 input_01 一致。不一致场景要额外编写逻辑。
  select 'input_04', 'input_04' union all   -- 规约：保持没有随机小批量采样配置即可。如果没有额外更新逻辑，该节点数据采样与 input_01 一致。不一致场景要额外编写逻辑。
  select 'output_01', 'output_01' union all
  select 'output_02', 'output_02' union all
  select 'output_03', 'output_03' union all
  select 'output_04', 'output_04' union all
  -- select 'offset', 'input' union all
  select 'weight', 'train' -- union all
  -- select 'prod_input', 'prod'
)
select 
  'node_type' as enum_name, 
  enum_key, 
  enum_value, 
  row_number() over() 
    + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'node_type'), 0) 
  as enum_order
from cte_node_type
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_order = excluded.enum_order
;

-- -------------------------------------------------------------------------
-- node_fn_type   -- 算子
-- delete from sm_sc.tb_dic_enum where enum_name = 'node_fn_type';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_group     ,
  enum_order
)
with cte_node_fn_type(enum_key, enum_value, enum_group) as
(
  select trim('00_full_dataset        '),         trim('                                 '),            '0_p' union all
  select trim('00_const               '),         trim('                                 '),            '0_p' union all
  select trim('00_none                '),         trim('sm_sc.fv_nn_none_py              '),            '1_p' union all
  select trim('00_buff_slice_rand_pick'),         trim('sm_sc.ft_nn_buff_slice_rand_pick '),            '1_p' union all
  select trim('01_add                 '),         trim('sm_sc.fv_opr_add_py              '),            '2_p' union all
  select trim('01_mul                 '),         trim('sm_sc.fv_opr_mul_py              '),            '2_p' union all
  select trim('01_sub                 '),         trim('sm_sc.fv_opr_sub_py              '),            '2_p' union all
  select trim('01_0sub                '),         trim('sm_sc.fv_opr_sub_py              '),            '1_p' union all
  select trim('01_div                 '),         trim('sm_sc.fv_opr_div_py              '),            '2_p' union all
  select trim('01_1div                '),         trim('sm_sc.fv_opr_div_py              '),            '1_p' union all
  select trim('01_pow                 '),         trim('sm_sc.fv_opr_pow_py              '),            '2_p' union all
  select trim('01_log                 '),         trim('sm_sc.fv_opr_log_py              '),            '2_p' union all
  select trim('01_exp                 '),         trim('sm_sc.fv_opr_exp_py              '),            '1_p' union all
  select trim('01_ln                  '),         trim('sm_sc.fv_opr_ln_py               '),            '1_p' union all
  select trim('01_abs                 '),         trim('sm_sc.fv_opr_abs                 '),            '1_p' union all
  select trim('01_prod_mx             '),         trim('sm_sc.fv_opr_prod_mx_py          '),            '2_p' union all
  select trim('01_chunk_prod_mx       '),         trim('sm_sc.fv_chunk_prod_mx           '),            '2_p' union all
  select trim('02_sin                 '),         trim('sm_sc.fv_sin                     '),            '1_p' union all
  select trim('02_cos                 '),         trim('sm_sc.fv_cos                     '),            '1_p' union all
  select trim('02_tan                 '),         trim('sm_sc.fv_tan                     '),            '1_p' union all
  select trim('02_cot                 '),         trim('sm_sc.fv_cot                     '),            '1_p' union all
  select trim('02_sec                 '),         trim('sm_sc.fv_sec                     '),            '1_p' union all
  select trim('02_csc                 '),         trim('sm_sc.fv_csc                     '),            '1_p' union all
  select trim('02_asin                '),         trim('sm_sc.fv_asin                    '),            '1_p' union all
  select trim('02_acos                '),         trim('sm_sc.fv_acos                    '),            '1_p' union all
  select trim('02_atan                '),         trim('sm_sc.fv_atan                    '),            '1_p' union all
  select trim('02_acot                '),         trim('sm_sc.fv_acot                    '),            '1_p' union all
  select trim('02_sinh                '),         trim('sm_sc.fv_sinh                    '),            '1_p' union all
  select trim('02_cosh                '),         trim('sm_sc.fv_cosh                    '),            '1_p' union all
  select trim('02_tanh                '),         trim('sm_sc.fv_tanh                    '),            '1_p' union all
  -- -- select trim('02_sech                '),         trim('sm_sc.fv_sech                    '),            '1_p' union all
  -- -- select trim('02_csch                '),         trim('sm_sc.fv_csch                    '),            '1_p' union all
  select trim('02_asinh               '),         trim('sm_sc.fv_asinh                   '),            '1_p' union all
  select trim('02_acosh               '),         trim('sm_sc.fv_acosh                   '),            '1_p' union all
  select trim('02_atanh               '),         trim('sm_sc.fv_atanh                   '),            '1_p' union all
  select trim('03_sigmoid             '),         trim('sm_sc.fv_activate_sigmoid        '),            '1_p' union all
  select trim('03_absqrt              '),         trim('sm_sc.fv_activate_absqrt         '),            '1_p' union all
  select trim('03_relu                '),         trim('sm_sc.fv_activate_relu           '),            '1_p' union all
  select trim('03_leaky_relu          '),         trim('sm_sc.fv_activate_leaky_relu     '),            '1_p' union all
  select trim('03_elu                 '),         trim('sm_sc.fv_activate_elu            '),            '1_p' union all
  select trim('03_selu                '),         trim('sm_sc.fv_activate_selu           '),            '1_p' union all
  select trim('03_gelu                '),         trim('sm_sc.fv_activate_gelu           '),            '1_p' union all
  select trim('03_swish               '),         trim('sm_sc.fv_activate_swish          '),            '1_p' union all
  select trim('03_softplus            '),         trim('sm_sc.fv_activate_softplus       '),            '1_p' union all
  select trim('03_boxcox              '),         trim('sm_sc.fv_activate_boxcox         '),            '1_p' union all
  select trim('03_softmax             '),         trim('sm_sc.fv_redistr_softmax_py      '),            '1_p' union all
  select trim('03_softmax_ex          '),         trim('sm_sc.fv_redistr_softmax_ex_py   '),            '1_p' union all
  select trim('03_zscore              '),         trim('sm_sc.fv_redistr_zscore          '),            '1_p' union all
  select trim('04_new                 '),         trim('sm_sc.fv_new                     '),            '1_p' union all
  select trim('04_reshape             '),         trim('sm_sc.fv_opr_reshape_py          '),            '1_p' union all
  select trim('04_repeat_axis         '),         trim('sm_sc.fv_repeat_axis_py          '),            '1_p' union all
  select trim('04_apad                '),         trim('sm_sc.fv_apad                    '),            '2_p' union all
  select trim('04_bpad                '),         trim('sm_sc.fv_bpad                    '),            '2_p' union all
  select trim('04_lpad                '),         trim('sm_sc.fv_lpad                    '),            '2_p' union all
  select trim('04_rpad                '),         trim('sm_sc.fv_rpad                    '),            '2_p' union all
  select trim('04_transpose           '),         trim('sm_sc.fv_opr_transpose_py        '),            '1_p' union all
  select trim('04_transpose_i         '),         trim('sm_sc.fv_opr_transpose_i_py      '),            '1_p' union all
  select trim('04_chunk_transpose     '),         trim('sm_sc.fv_chunk_transpose         '),            '1_p' union all
  select trim('04_transpose_nd        '),         trim('sm_sc.fv_opr_transpose_nd_py     '),            '1_p' union all
  select trim('04_turn_90             '),         trim('sm_sc.fv_opr_turn_90_py          '),            '1_p' union all
  select trim('04_turn_180            '),         trim('sm_sc.fv_opr_turn_180_py         '),            '1_p' union all
  select trim('04_mirror              '),         trim('sm_sc.fv_opr_mirror_py           '),            '1_p' union all
  select trim('04_mx_ele_3d_2_2d      '),         trim('sm_sc.fv_mx_ele_3d_2_2d_py       '),            '1_p' union all
  select trim('04_mx_ele_2d_2_3d      '),         trim('sm_sc.fv_mx_ele_2d_2_3d_py       '),            '1_p' union all
  select trim('04_mx_ele_4d_2_3d      '),         trim('sm_sc.fv_mx_ele_4d_2_3d_py       '),            '1_p' union all
  select trim('04_mx_ele_3d_2_4d      '),         trim('sm_sc.fv_mx_ele_3d_2_4d_py       '),            '1_p' union all
  select trim('04_mx_ele_flatten_2dims'),         trim('sm_sc.fv_mx_ele_flatten_2dims_py '),            '1_p' union all
  select trim('04_mx_slice_3d_2_2d    '),         trim('sm_sc.fv_mx_slice_3d_2_2d_py     '),            '1_p' union all
  select trim('04_mx_slice_4d_2_2d    '),         trim('sm_sc.fv_mx_slice_4d_2_2d_py     '),            '1_p' union all
  select trim('04_mx_slice_4d_2_3d    '),         trim('sm_sc.fv_mx_slice_4d_2_3d_py     '),            '1_p' union all
  select trim('04_mx_ascend_dim       '),         trim('sm_sc.fv_mx_ascend_dim           '),            '1_p' union all
  select trim('04_mx_descend_dim      '),         trim('sm_sc.fv_mx_descend_dim_py       '),            '1_p' union all
  select trim('04_rand_pick_y         '),         trim('sm_sc.ft_rand_slice_y_pick       '),            '1_p' union all
  select trim('04_rand_pick_x         '),         trim('sm_sc.ft_rand_slice_x_pick       '),            '1_p' union all
  select trim('04_rand_pick_x3        '),         trim('sm_sc.ft_rand_slice_x3_pick      '),            '1_p' union all
  select trim('04_rand_pick_x4        '),         trim('sm_sc.ft_rand_slice_x4_pick      '),            '1_p' union all
  select trim('04_chunk               '),         trim('sm_sc.fv_chunk                   '),            '1_p' union all
  select trim('04_slice_y             '),         trim('sm_sc.fv_slice_y                 '),            '1_p' union all
  select trim('04_slice_x             '),         trim('sm_sc.fv_slice_x                 '),            '1_p' union all
  select trim('04_slice_x3            '),         trim('sm_sc.fv_slice_x3                '),            '1_p' union all
  select trim('04_slice_x4            '),         trim('sm_sc.fv_slice_x4                '),            '1_p' union all
  select trim('04_sample_y            '),         trim('sm_sc.fv_sample_y                '),            '1_p' union all
  select trim('04_sample_x            '),         trim('sm_sc.fv_sample_x                '),            '1_p' union all
  select trim('04_sample_x3           '),         trim('sm_sc.fv_sample_x3               '),            '1_p' union all
  select trim('04_sample_x4           '),         trim('sm_sc.fv_sample_x4               '),            '1_p' union all
  select trim('04_lower_tri_mx        '),         trim('sm_sc.fv_lower_tri_mx            '),            '1_p' union all
  select trim('04_upper_tri_mx        '),         trim('sm_sc.fv_upper_tri_mx            '),            '1_p' union all
  select trim('04_lower_tri_mx_ex     '),         trim('sm_sc.fv_lower_tri_mx_ex         '),            '1_p' union all
  select trim('04_upper_tri_mx_ex     '),         trim('sm_sc.fv_upper_tri_mx_ex         '),            '1_p' union all
  select trim('04_lmask               '),         trim('sm_sc.fv_lmask                   '),            '2_p' union all
  select trim('04_rmask               '),         trim('sm_sc.fv_rmask                   '),            '2_p' union all
  select trim('04_amask               '),         trim('sm_sc.fv_amask                   '),            '2_p' union all
  select trim('04_bmask               '),         trim('sm_sc.fv_bmask                   '),            '2_p' union all
  select trim('05_pool_max_2d_grp_x   '),         trim('sm_sc.fv_pool_max_2d_grp_x       '),            '1_p' union all
  select trim('05_pool_avg_2d_grp_x   '),         trim('sm_sc.fv_pool_avg_2d_grp_x       '),            '1_p' union all
  select trim('05_pool_max            '),         trim('sm_sc.fv_pool_max_py             '),            '1_p' union all
  select trim('05_pool_avg            '),         trim('sm_sc.fv_pool_avg_py             '),            '1_p' union all
  select trim('05_pool_none           '),         trim('sm_sc.fv_pool_none               '),            '1_p' union all
  select trim('05_conv_2d_grp_x       '),         trim('sm_sc.fv_conv_2d_grp_x           '),            '2_p' union all
  select trim('05_conv_2d             '),         trim('sm_sc.fv_conv_2d_im2col_py       '),            '3_p' union all   -- '3_p' 兼容 '2_p', 此时第三目传 null
  select trim('05_tunnel_conv         '),         trim('sm_sc.fv_tunnel_conv_py          '),            '3_p' union all   -- '3_p' 兼容 '2_p', 此时第三目传 null
  select trim('05_conv_add            '),         trim('sm_sc.fv_conv_add                '),            '2_p' union all
  select trim('05_conv_sub            '),         trim('sm_sc.fv_conv_sub                '),            '2_p' union all
  select trim('05_conv_mul            '),         trim('sm_sc.fv_conv_mul                '),            '2_p' union all
  select trim('05_conv_div            '),         trim('sm_sc.fv_conv_div                '),            '2_p' union all
  select trim('05_conv_pow            '),         trim('sm_sc.fv_conv_pow                '),            '2_p' union all
  select trim('05_conv_log            '),         trim('sm_sc.fv_conv_log                '),            '2_p' union all
  select trim('05_conv_prod_mx        '),         trim('sm_sc.fv_conv_prod_mx            '),            '2_p' union all
  select trim('05_conv_de_sub         '),         trim('sm_sc.fv_conv_de_sub             '),            '2_p' union all
  select trim('05_conv_de_div         '),         trim('sm_sc.fv_conv_de_div             '),            '2_p' union all
  select trim('05_conv_de_pow         '),         trim('sm_sc.fv_conv_de_pow             '),            '2_p' union all
  select trim('05_conv_de_log         '),         trim('sm_sc.fv_conv_de_log             '),            '2_p' union all
  select trim('05_conv_de_prod_mx     '),         trim('sm_sc.fv_conv_de_prod_mx         '),            '2_p' union all
  select trim('06_aggr_mx_sum         '),         trim('sm_sc.fa_mx_sum                  '),            'n_p' union all
  select trim('06_aggr_mx_prod        '),         trim('sm_sc.fa_mx_prod                 '),            'n_p' union all
  select trim('06_aggr_mx_avg         '),         trim('sm_sc.fa_mx_avg                  '),            'n_p' union all
  select trim('06_aggr_mx_max         '),         trim('sm_sc.fa_mx_max                  '),            'n_p' union all
  select trim('06_aggr_mx_min         '),         trim('sm_sc.fa_mx_min                  '),            'n_p' union all
  select trim('06_aggr_mx_concat_y    '),         trim('sm_sc.fa_mx_concat_y             '),            'n_p' union all
  select trim('06_aggr_mx_concat_x    '),         trim('sm_sc.fa_mx_concat_x             '),            'n_p' union all
  select trim('06_aggr_mx_concat_x3   '),         trim('sm_sc.fa_mx_concat_x3            '),            'n_p' union all
  select trim('06_aggr_mx_concat_x4   '),         trim('sm_sc.fa_mx_concat_x4            '),            'n_p' union all
  select trim('07_aggr_slice_sum      '),         trim('sm_sc.fv_aggr_slice_sum_py       '),            '1_p' union all
  select trim('07_aggr_slice_avg      '),         trim('sm_sc.fv_aggr_slice_avg_py       '),            '1_p' union all
  select trim('07_aggr_slice_max      '),         trim('sm_sc.fv_aggr_slice_max_py       '),            '1_p' union all
  select trim('07_aggr_slice_min      '),         trim('sm_sc.fv_aggr_slice_min_py       '),            '1_p' union all
  select trim('07_aggr_slice_prod     '),         trim('sm_sc.fv_aggr_slice_prod_py      '),            '1_p' union all
  select trim('07_aggr_chunk_sum      '),         trim('sm_sc.fv_aggr_chunk_sum          '),            '1_p' union all
  select trim('07_aggr_chunk_avg      '),         trim('sm_sc.fv_aggr_chunk_avg          '),            '1_p' union all
  select trim('07_aggr_chunk_max      '),         trim('sm_sc.fv_aggr_chunk_max          '),            '1_p' union all
  select trim('07_aggr_chunk_min      '),         trim('sm_sc.fv_aggr_chunk_min          '),            '1_p' union all
  select trim('07_aggr_chunk_prod     '),         trim('sm_sc.fv_aggr_chunk_prod         '),            '1_p'
)
select 
  'node_fn_type' as enum_name, 
  enum_key, 
  enum_value, 
  enum_group,
  row_number() over() 
    + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'node_fn_type'), 0) 
  as enum_order
from cte_node_fn_type
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_group = excluded.enum_group
, enum_order = excluded.enum_order
;

-- -------------------------------------------------------------------------
-- node_fn_type_delta  -- 算子求导函数
-- delete from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_group     ,
  enum_order
)
with cte_node_fn_type_delta(enum_key, enum_value, enum_group) as
(
  -- select trim('dddi_full_dataset        '), trim('                                                     '),trim('00_full_dataset        ') union all
  -- select trim('dddi_const               '), trim('                                                     '),trim('00_const               ') union all
  -- select trim('dddi_buff_slice_rand_pick'), trim('                                                     '),trim('00_buff_slice_rand_pick') union all
     select trim('dldi_none                '), trim('sm_sc.fv_d_nn_none_dloss_dindepdt                    '),trim('00_none                ') union all
     select trim('dddi_add                 '), trim('sm_sc.fv_d_add                                       '),trim('01_add                 ') union all
     select trim('dddi_mul                 '), trim('sm_sc.fv_d_mul                                       '),trim('01_mul                 ') union all
     select trim('dddi_sub_1               '), trim('sm_sc.fv_d_sub_1                                     '),trim('01_sub                 ') union all
     select trim('dddi_sub_2               '), trim('sm_sc.fv_d_sub_2                                     '),trim('01_sub                 ') union all
     select trim('dddi_0sub_1              '), trim('sm_sc.fv_d_sub_2                                     '),trim('01_0sub                ') union all
     select trim('dddi_div_1               '), trim('sm_sc.fv_d_div_1                                     '),trim('01_div                 ') union all
     select trim('dddi_div_2               '), trim('sm_sc.fv_d_div_2                                     '),trim('01_div                 ') union all
     select trim('dddi_1div_1              '), trim('sm_sc.fv_d_div_2                                     '),trim('01_1div                ') union all
     select trim('dddi_pow_1               '), trim('sm_sc.fv_d_pow_1                                     '),trim('01_pow                 ') union all
     select trim('dddi_pow_2               '), trim('sm_sc.fv_d_pow_2                                     '),trim('01_pow                 ') union all
     select trim('dddi_log_1               '), trim('sm_sc.fv_d_log_1                                     '),trim('01_log                 ') union all
     select trim('dddi_log_2               '), trim('sm_sc.fv_d_log_2                                     '),trim('01_log                 ') union all
     select trim('dddi_exp                 '), trim('sm_sc.fv_d_exp                                       '),trim('01_exp                 ') union all
     select trim('dddi_ln                  '), trim('sm_sc.fv_d_ln                                        '),trim('01_ln                  ') union all
     select trim('dddi_abs                 '), trim('sm_sc.fv_d_abs                                       '),trim('01_1div                ') union all
     select trim('dddi_prod_mx_1           '), trim('sm_sc.fv_d_prod_mx_1                                 '),trim('01_prod_mx             ') union all
     select trim('dddi_prod_mx_2           '), trim('sm_sc.fv_d_prod_mx_2                                 '),trim('01_prod_mx             ') union all
     select trim('dldi_prod_mx_1           '), trim('sm_sc.fv_d_prod_mx_dloss_dindepdt_1                  '),trim('01_prod_mx             ') union all
     select trim('dldi_prod_mx_2           '), trim('sm_sc.fv_d_prod_mx_dloss_dindepdt_2                  '),trim('01_prod_mx             ') union all
     select trim('dddi_chunk_prod_mx_1     '), trim('sm_sc.fv_d_chunk_prod_mx_1                           '),trim('01_chunk_prod_mx       ') union all
     select trim('dddi_chunk_prod_mx_2     '), trim('sm_sc.fv_d_chunk_prod_mx_2                           '),trim('01_chunk_prod_mx       ') union all
     select trim('dldi_chunk_prod_mx_1     '), trim('sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1            '),trim('01_chunk_prod_mx       ') union all
     select trim('dldi_chunk_prod_mx_2     '), trim('sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_2            '),trim('01_chunk_prod_mx       ') union all
     select trim('dddi_sin                 '), trim('sm_sc.fv_d_sin                                       '),trim('02_sin                 ') union all
     select trim('dddi_cos                 '), trim('sm_sc.fv_d_cos                                       '),trim('02_cos                 ') union all
     select trim('dddi_tan                 '), trim('sm_sc.fv_d_tan                                       '),trim('02_tan                 ') union all
     select trim('dddi_cot                 '), trim('sm_sc.fv_d_cot                                       '),trim('02_cot                 ') union all
     select trim('dddi_sec                 '), trim('sm_sc.fv_d_sec                                       '),trim('02_sec                 ') union all
     select trim('dddi_csc                 '), trim('sm_sc.fv_d_csc                                       '),trim('02_csc                 ') union all
     select trim('dddi_asin                '), trim('sm_sc.fv_d_asin                                      '),trim('02_asin                ') union all
     select trim('dddi_acos                '), trim('sm_sc.fv_d_acos                                      '),trim('02_acos                ') union all
     select trim('dddi_atan                '), trim('sm_sc.fv_d_atan                                      '),trim('02_atan                ') union all
     select trim('dddi_acot                '), trim('sm_sc.fv_d_acot                                      '),trim('02_acot                ') union all
     select trim('dddi_sinh                '), trim('sm_sc.fv_d_sinh                                      '),trim('02_sinh                ') union all
     select trim('dddi_cosh                '), trim('sm_sc.fv_d_cosh                                      '),trim('02_cosh                ') union all
     select trim('dddi_tanh                '), trim('sm_sc.fv_d_tanh                                      '),trim('02_tanh                ') union all
     select trim('dddi_asinh               '), trim('sm_sc.fv_d_asinh                                     '),trim('02_asinh               ') union all
     select trim('dddi_acosh               '), trim('sm_sc.fv_d_acosh                                     '),trim('02_acosh               ') union all
     select trim('dddi_atanh               '), trim('sm_sc.fv_d_atanh                                     '),trim('02_atanh               ') union all
     select trim('dddi_sigmoid             '), trim('sm_sc.fv_d_activate_sigmoid                          '),trim('03_sigmoid             ') union all
     select trim('dddi_absqrt              '), trim('sm_sc.fv_d_activate_absqrt                           '),trim('03_absqrt              ') union all
     select trim('dddi_relu                '), trim('sm_sc.fv_d_activate_relu                             '),trim('03_relu                ') union all
     select trim('dddi_leaky_relu          '), trim('sm_sc.fv_d_activate_leaky_relu                       '),trim('03_leaky_relu          ') union all
     select trim('dddi_elu                 '), trim('sm_sc.fv_d_activate_elu                              '),trim('03_elu                 ') union all
     select trim('dddi_selu                '), trim('sm_sc.fv_d_activate_selu                             '),trim('03_selu                ') union all
     select trim('dddi_gelu                '), trim('sm_sc.fv_d_activate_gelu                             '),trim('03_gelu                ') union all
     select trim('dddi_swish               '), trim('sm_sc.fv_d_activate_swish                            '),trim('03_swish               ') union all
     select trim('dddi_softplus            '), trim('sm_sc.fv_d_activate_softplus                         '),trim('03_softplus            ') union all
     select trim('dddi_boxcox              '), trim('sm_sc.fv_d_activate_boxcox                           '),trim('03_boxcox              ') union all
     select trim('dldi_softmax             '), trim('sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py         '),trim('03_softmax             ') union all
     select trim('dldi_softmax_ex          '), trim('sm_sc.fv_d_redistr_softmax_dloss_dindepdt_py         '),trim('03_softmax_ex          ') union all
     select trim('dddi_zscore              '), trim('sm_sc.fv_d_redistr_zscore                            '),trim('03_zscore              ') union all
     select trim('dldi_new                 '), trim('sm_sc.fv_d_new_dloss_dindepdt                        '),trim('04_new                 ') union all
     select trim('dldi_reshape             '), trim('sm_sc.fv_d_reshape_dloss_dindepdt                    '),trim('04_reshape             ') union all
     select trim('dldi_repeat_axis         '), trim('sm_sc.fv_d_repeat_axis_dloss_dindepdt                '),trim('04_repeat_axis         ') union all
     select trim('dldi_apad_1              '), trim('sm_sc.fv_d_apad_dloss_dindepdt_1                     '),trim('04_apad                ') union all
     select trim('dldi_apad_2              '), trim('sm_sc.fv_d_apad_dloss_dindepdt_2                     '),trim('04_apad                ') union all
     select trim('dldi_bpad_1              '), trim('sm_sc.fv_d_bpad_dloss_dindepdt_1                     '),trim('04_bpad                ') union all
     select trim('dldi_bpad_2              '), trim('sm_sc.fv_d_bpad_dloss_dindepdt_2                     '),trim('04_bpad                ') union all
     select trim('dldi_lpad_1              '), trim('sm_sc.fv_d_lpad_dloss_dindepdt_1                     '),trim('04_lpad                ') union all
     select trim('dldi_lpad_2              '), trim('sm_sc.fv_d_lpad_dloss_dindepdt_2                     '),trim('04_lpad                ') union all
     select trim('dldi_rpad_1              '), trim('sm_sc.fv_d_rpad_dloss_dindepdt_1                     '),trim('04_rpad                ') union all
     select trim('dldi_rpad_2              '), trim('sm_sc.fv_d_rpad_dloss_dindepdt_2                     '),trim('04_rpad                ') union all
     select trim('dldi_transpose           '), trim('sm_sc.fv_d_transpose_dloss_dindepdt                  '),trim('04_transpose           ') union all
     select trim('dldi_transpose_i         '), trim('sm_sc.fv_d_transpose_i_dloss_dindepdt                '),trim('04_transpose_i         ') union all
     select trim('dldi_chunk_transpose_i   '), trim('sm_sc.fv_d_chunk_transpose_dloss_dindepdt            '),trim('04_chunk_transpose     ') union all
     select trim('dldi_transpose_nd        '), trim('sm_sc.fv_d_transpose_nd_dloss_dindepdt               '),trim('04_transpose_nd        ') union all
     select trim('dldi_turn_90             '), trim('sm_sc.fv_d_turn_90_dloss_dindepdt                    '),trim('04_turn_90             ') union all
     select trim('dldi_turn_180            '), trim('sm_sc.fv_d_turn_180_dloss_dindepdt                   '),trim('04_turn_180            ') union all
     select trim('dldi_mirror              '), trim('sm_sc.fv_d_mirror_dloss_dindepdt                     '),trim('04_mirror              ') union all
     select trim('dldi_mx_ele_3d_2_2d      '), trim('sm_sc.fv_d_mx_ele_3d_2_2d_dloss_dindepdt             '),trim('04_mx_ele_3d_2_2d      ') union all
     select trim('dldi_mx_ele_2d_2_3d      '), trim('sm_sc.fv_d_mx_ele_2d_2_3d_dloss_dindepdt             '),trim('04_mx_ele_2d_2_3d      ') union all
     select trim('dldi_mx_ele_4d_2_3d      '), trim('sm_sc.fv_d_mx_ele_4d_2_3d_dloss_dindepdt             '),trim('04_mx_ele_4d_2_3d      ') union all
     select trim('dldi_mx_ele_3d_2_4d      '), trim('sm_sc.fv_d_mx_ele_3d_2_4d_dloss_dindepdt             '),trim('04_mx_ele_3d_2_4d      ') union all
     select trim('dldi_mx_ele_flatten_2dims'), trim('sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt       '),trim('04_mx_ele_flatten_2dims') union all
     select trim('dldi_mx_slice_3d_2_2d    '), trim('sm_sc.fv_d_mx_slice_3d_2_2d_dloss_dindepdt           '),trim('04_mx_slice_3d_2_2d    ') union all
     select trim('dldi_mx_slice_4d_2_2d    '), trim('sm_sc.fv_d_mx_slice_4d_2_2d_dloss_dindepdt           '),trim('04_mx_slice_4d_2_2d    ') union all
     select trim('dldi_mx_slice_4d_2_3d    '), trim('sm_sc.fv_d_mx_slice_4d_2_3d_dloss_dindepdt           '),trim('04_mx_slice_4d_2_3d    ') union all
     select trim('dldi_mx_ascend_dim       '), trim('sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt              '),trim('04_mx_ascend_dim       ') union all
     select trim('dldi_mx_descend_dim      '), trim('sm_sc.fv_d_mx_descend_dim_dloss_dindepdt             '),trim('04_mx_descend_dim      ') union all
  -- select trim('dldi_rand_pick_y         '), trim('                                                     '),trim('04_rand_pick_y         ') union all
  -- select trim('dldi_rand_pick_x         '), trim('                                                     '),trim('04_rand_pick_x         ') union all
  -- select trim('dldi_rand_pick_x3        '), trim('                                                     '),trim('04_rand_pick_x3        ') union all
  -- select trim('dldi_rand_pick_x4        '), trim('                                                     '),trim('04_rand_pick_x4        ') union all
     select trim('dldi_chunk               '), trim('sm_sc.fv_d_chunk_dloss_dindepdt                      '),trim('04_chunk               ') union all
     select trim('dldi_slice_y             '), trim('sm_sc.fv_d_slice_y_dloss_dindepdt                    '),trim('04_slice_y             ') union all
     select trim('dldi_slice_x             '), trim('sm_sc.fv_d_slice_x_dloss_dindepdt                    '),trim('04_slice_x             ') union all
     select trim('dldi_slice_x3            '), trim('sm_sc.fv_d_slice_x3_dloss_dindepdt                   '),trim('04_slice_x3            ') union all
     select trim('dldi_slice_x4            '), trim('sm_sc.fv_d_slice_x4_dloss_dindepdt                   '),trim('04_slice_x4            ') union all
     select trim('dldi_sample_y            '), trim('sm_sc.fv_d_sample_y_dloss_dindepdt_1                 '),trim('04_sample_y            ') union all
     select trim('dldi_sample_x            '), trim('sm_sc.fv_d_sample_x_dloss_dindepdt_1                 '),trim('04_sample_x            ') union all
     select trim('dldi_sample_x3           '), trim('sm_sc.fv_d_sample_x3_dloss_dindepdt_1                '),trim('04_sample_x3           ') union all
     select trim('dldi_sample_x4           '), trim('sm_sc.fv_d_sample_x4_dloss_dindepdt_1                '),trim('04_sample_x4           ') union all
     select trim('dldi_lower_tri_mx        '), trim('sm_sc.fv_d_lower_tri_mx_dloss_dindepdt               '),trim('04_lower_tri_mx        ') union all
     select trim('dldi_upper_tri_mx        '), trim('sm_sc.fv_d_upper_tri_mx_dloss_dindepdt               '),trim('04_upper_tri_mx        ') union all
     select trim('dldi_lower_tri_mx_ex     '), trim('sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt            '),trim('04_lower_tri_mx_ex     ') union all
     select trim('dldi_upper_tri_mx_ex     '), trim('sm_sc.fv_d_upper_tri_mx_ex_dloss_dindepdt            '),trim('04_upper_tri_mx_ex     ') union all
     select trim('dldi_lmask               '), trim('sm_sc.fv_d_lmask_dloss_dindepdt_1                    '),trim('04_lmask               ') union all
     select trim('dldi_rmask               '), trim('sm_sc.fv_d_rmask_dloss_dindepdt_1                    '),trim('04_rmask               ') union all
     select trim('dldi_amask               '), trim('sm_sc.fv_d_amask_dloss_dindepdt_1                    '),trim('04_amask               ') union all
     select trim('dldi_bmask               '), trim('sm_sc.fv_d_bmask_dloss_dindepdt_1                    '),trim('04_bmask               ') union all
     select trim('dldi_pool_max_grp_x      '), trim('sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt             '),trim('05_pool_max_2d_grp_x   ') union all
     select trim('dldi_pool_avg_grp_x      '), trim('sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt             '),trim('05_pool_avg_2d_grp_x   ') union all
     select trim('dldi_pool_max            '), trim('sm_sc.fv_d_pool_max_dloss_dindepdt                   '),trim('05_pool_max            ') union all
     select trim('dldi_pool_avg            '), trim('sm_sc.fv_d_pool_avg_dloss_dindepdt_ex                '),trim('05_pool_avg            ') union all
     select trim('dldi_pool_none           '), trim('sm_sc.fv_d_pool_none_dloss_dindepdt                  '),trim('05_pool_none           ') union all
     select trim('dldi_conv_2d_grp_x_1     '), trim('sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1            '),trim('05_conv_2d_grp_x       ') union all
     select trim('dldi_conv_2d_grp_x_2     '), trim('sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_2            '),trim('05_conv_2d_grp_x       ') union all
     select trim('dldi_conv_2d_1           '), trim('sm_sc.fv_d_conv_2d_dloss_dindepdt_1_ex               '),trim('05_conv_2d             ') union all
     select trim('dldi_conv_2d_2           '), trim('sm_sc.fv_d_conv_2d_dloss_dindepdt_2_py               '),trim('05_conv_2d             ') union all
     select trim('dldi_conv_2d_3           '), trim('sm_sc.fv_d_conv_2d_dloss_dindepdt_3                  '),trim('05_conv_2d             ') union all
     select trim('dldi_tunnel_conv_1       '), trim('sm_sc.fv_d_tunnel_conv_dloss_dindepdt_1_py           '),trim('05_tunnel_conv         ') union all
     select trim('dldi_tunnel_conv_2       '), trim('sm_sc.fv_d_tunnel_conv_dloss_dindepdt_2_py           '),trim('05_tunnel_conv         ') union all
     select trim('dldi_tunnel_conv_3       '), trim('sm_sc.fv_d_tunnel_conv_dloss_dindepdt_3              '),trim('05_tunnel_conv         ') union all
     select trim('dldi_conv_add_1          '), trim('sm_sc.fv_d_conv_add_dloss_dindepdt_1                 '),trim('05_conv_add            ') union all
     select trim('dldi_conv_add_2          '), trim('sm_sc.fv_d_conv_add_dloss_dindepdt_2                 '),trim('05_conv_add            ') union all
     select trim('dldi_conv_sub_1          '), trim('sm_sc.fv_d_conv_sub_dloss_dindepdt_1                 '),trim('05_conv_sub            ') union all
     select trim('dldi_conv_sub_2          '), trim('sm_sc.fv_d_conv_sub_dloss_dindepdt_2                 '),trim('05_conv_sub            ') union all
     select trim('dldi_conv_mul_1          '), trim('sm_sc.fv_d_conv_mul_dloss_dindepdt_1                 '),trim('05_conv_mul            ') union all
     select trim('dldi_conv_mul_2          '), trim('sm_sc.fv_d_conv_mul_dloss_dindepdt_2                 '),trim('05_conv_mul            ') union all
     select trim('dldi_conv_div_1          '), trim('sm_sc.fv_d_conv_div_dloss_dindepdt_1                 '),trim('05_conv_div            ') union all
     select trim('dldi_conv_div_2          '), trim('sm_sc.fv_d_conv_div_dloss_dindepdt_2                 '),trim('05_conv_div            ') union all
     select trim('dldi_conv_pow_1          '), trim('sm_sc.fv_d_conv_pow_dloss_dindepdt_1                 '),trim('05_conv_pow            ') union all
     select trim('dldi_conv_pow_2          '), trim('sm_sc.fv_d_conv_pow_dloss_dindepdt_2                 '),trim('05_conv_pow            ') union all
     select trim('dldi_conv_log_1          '), trim('sm_sc.fv_d_conv_log_dloss_dindepdt_1                 '),trim('05_conv_log            ') union all
     select trim('dldi_conv_log_2          '), trim('sm_sc.fv_d_conv_log_dloss_dindepdt_2                 '),trim('05_conv_log            ') union all
     select trim('dldi_conv_prod_mx_1      '), trim('sm_sc.fv_d_conv_prod_mx_dloss_dindepdt_1             '),trim('05_conv_prod_mx        ') union all
     select trim('dldi_conv_prod_mx_2      '), trim('sm_sc.fv_d_conv_prod_mx_dloss_dindepdt_2             '),trim('05_conv_prod_mx        ') union all
     select trim('dldi_conv_de_sub_1       '), trim('sm_sc.fv_d_conv_de_sub_dloss_dindepdt_1              '),trim('05_conv_de_sub         ') union all
     select trim('dldi_conv_de_sub_2       '), trim('sm_sc.fv_d_conv_de_sub_dloss_dindepdt_2              '),trim('05_conv_de_sub         ') union all
     select trim('dldi_conv_de_div_1       '), trim('sm_sc.fv_d_conv_de_div_dloss_dindepdt_1              '),trim('05_conv_de_div         ') union all
     select trim('dldi_conv_de_div_2       '), trim('sm_sc.fv_d_conv_de_div_dloss_dindepdt_2              '),trim('05_conv_de_div         ') union all
     select trim('dldi_conv_de_pow_1       '), trim('sm_sc.fv_d_conv_de_pow_dloss_dindepdt_1              '),trim('05_conv_de_pow         ') union all
     select trim('dldi_conv_de_pow_2       '), trim('sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2              '),trim('05_conv_de_pow         ') union all
     select trim('dldi_conv_de_log_1       '), trim('sm_sc.fv_d_conv_de_log_dloss_dindepdt_1              '),trim('05_conv_de_log         ') union all
     select trim('dldi_conv_de_log_2       '), trim('sm_sc.fv_d_conv_de_log_dloss_dindepdt_2              '),trim('05_conv_de_log         ') union all
     select trim('dldi_conv_de_prod_mx_1   '), trim('sm_sc.fv_d_conv_de_prod_mx_dloss_dindepdt_1'          ),trim('05_conv_de_prod_mx     ') union all
     select trim('dldi_conv_de_prod_mx_2   '), trim('sm_sc.fv_d_conv_de_prod_mx_dloss_dindepdt_2          '),trim('05_conv_de_prod_mx     ') union all
     select trim('dddi_aggr_mx_sum         '), trim('sm_sc.fv_d_mx_sum                                    '),trim('06_aggr_mx_sum         ') union all
     select trim('dddi_aggr_mx_prod        '), trim('sm_sc.fv_d_mx_prod                                   '),trim('06_aggr_mx_prod        ') union all
     select trim('dddi_aggr_mx_avg         '), trim('sm_sc.fv_d_mx_avg                                    '),trim('06_aggr_mx_avg         ') union all
     select trim('dddi_aggr_mx_max         '), trim('sm_sc.fv_d_mx_max                                    '),trim('06_aggr_mx_max         ') union all
     select trim('dddi_aggr_mx_min         '), trim('sm_sc.fv_d_mx_min                                    '),trim('06_aggr_mx_min         ') union all
     select trim('dldi_aggr_mx_concat_y    '), trim('sm_sc.fv_d_mx_concat_y_dloss_dindepdt_n              '),trim('06_aggr_mx_concat_y    ') union all
     select trim('dldi_aggr_mx_concat_x    '), trim('sm_sc.fv_d_mx_concat_x_dloss_dindepdt_n              '),trim('06_aggr_mx_concat_x    ') union all
     select trim('dldi_aggr_mx_concat_x3   '), trim('sm_sc.fv_d_mx_concat_x3_dloss_dindepdt_n             '),trim('06_aggr_mx_concat_x3   ') union all
     select trim('dldi_aggr_mx_concat_x4   '), trim('sm_sc.fv_d_mx_concat_x4_dloss_dindepdt_n             '),trim('06_aggr_mx_concat_x4   ') union all
     select trim('dldi_aggr_slice_sum      '), trim('sm_sc.fv_d_aggr_slice_sum_dloss_dindepdt_py          '),trim('07_aggr_slice_sum      ') union all
     select trim('dldi_aggr_slice_avg      '), trim('sm_sc.fv_d_aggr_slice_avg_dloss_dindepdt_py          '),trim('07_aggr_slice_avg      ') union all
     select trim('dldi_aggr_slice_max      '), trim('sm_sc.fv_d_aggr_slice_max_dloss_dindepdt_py          '),trim('07_aggr_slice_max      ') union all
     select trim('dldi_aggr_slice_min      '), trim('sm_sc.fv_d_aggr_slice_min_dloss_dindepdt_py          '),trim('07_aggr_slice_min      ') union all
     select trim('dldi_aggr_slice_prod     '), trim('sm_sc.fv_d_aggr_slice_prod_dloss_dindepdt_py         '),trim('07_aggr_slice_prod     ') union all
     select trim('dldi_aggr_chunk_sum      '), trim('sm_sc.fv_d_aggr_chunk_sum_dloss_dindepdt             '),trim('07_aggr_chunk_sum      ') union all
     select trim('dldi_aggr_chunk_avg      '), trim('sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt             '),trim('07_aggr_chunk_avg      ') union all
     select trim('dldi_aggr_chunk_max      '), trim('sm_sc.fv_d_aggr_chunk_max_dloss_dindepdt             '),trim('07_aggr_chunk_max      ') union all
     select trim('dldi_aggr_chunk_min      '), trim('sm_sc.fv_d_aggr_chunk_min_dloss_dindepdt             '),trim('07_aggr_chunk_min      ') union all
     select trim('dldi_aggr_chunk_prod     '), trim('sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt            '),trim('07_aggr_chunk_prod     ')
)
select 
  'node_fn_type_delta' as enum_name, 
  enum_key, 
  enum_value, 
  enum_group,
  row_number() over() 
    + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta'), 0) 
  as enum_order
from cte_node_fn_type_delta
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_group = excluded.enum_group
, enum_order = excluded.enum_order
;

-- -------------------------------------------------------------------------
-- node_fn_asso_value  -- 算子超参数
-- delete from sm_sc.tb_dic_enum where enum_name = 'node_fn_asso_value';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_group     ,
  enum_order     ,
  enum_range
)
with cte_node_fn_asso_value(a_param_name, a_cn_desc, enum_group, enum_order, enum_range) as
(
     select trim('dataset_len__1d              '), trim('训练集规格                                       '), trim('00_full_dataset        '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('dataset_len__nd              '), trim('常数节点的各维度长度规格                         '), trim('00_const               '),  1, numrange(1.0, null, '[]') union all
     select trim('slice_range_lowers__2d       '), trim('若干切片范围下界                                 '), trim('00_buff_slice_rand_pick'),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_range_uppers__2d       '), trim('若干切片范围上界                                 '), trim('00_buff_slice_rand_pick'),  2, numrange(2.0, 2.0, '[]') union all
     select trim('rand_pick_cnts__2d           '), trim('在对应切片范围上随机选取训练集数量               '), trim('00_buff_slice_rand_pick'),  3, numrange(3.0, 3.0, '[]') union all
     select trim('p1_heigh__1d                 '), trim('入参一高度规格，非必要配置                       '), trim('01_prod_mx             '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('p1_width_p2_heigh__1d        '), trim('入参一宽度规格，也即入参二高度规格               '), trim('01_prod_mx             '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('p2_width__1d                 '), trim('入参二宽度规格                                   '), trim('01_prod_mx             '),  3, numrange(3.0, 3.0, '[]') union all
  -- select trim('p2_3d4d_len_y__1d            '), trim('高维广播入参二的第一维长度                       '), trim('01_prod_mx             '),  4, numrange(4.0, 4.0, '[]') union all
  -- select trim('p2_3d4d_len_x__1d            '), trim('高维广播入参二的第二维长度                       '), trim('01_prod_mx             '),  5, numrange(5.0, 5.0, '[]') union all
     select trim('p1_chunk_heigh__1d           '), trim('矩阵乘法 chunk 入参一高度规格                    '), trim('01_chunk_prod_mx       '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('p1_chunk_width_p2_heigh__1d  '), trim('矩阵乘法 chunk 入参一宽度规格，也即入参二高度规格'), trim('01_chunk_prod_mx       '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('p2_chunk_width__1d           '), trim('矩阵乘法 chunk 入参二宽度规格                    '), trim('01_chunk_prod_mx       '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('alpha__1d                    '), trim('leaky_relu 的超参数                              '), trim('03_leaky_relu          '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('alpha__1d                    '), trim('elu 的超参数                                     '), trim('03_elu                 '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('beta_gamma__1d               '), trim('absqrt 的超参数 beta 和 gamma。维长可为 null     '), trim('03_absqrt              '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('lambda__1d                   '), trim('boxcox 的超参数                                  '), trim('03_boxcox              '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('03_softmax             '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('03_softmax_ex          '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('03_zscore              '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('dims_times__1d               '), trim('各维度重复次数                                   '), trim('04_new                 '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('new_dims__1d                 '), trim('新维度规格。null 表示保留原矩阵相同位置维长不变  '), trim('04_reshape             '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('dims__2d                     '), trim('执行复制操作的若干维轴                           '), trim('04_repeat_axis         '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('repeat__2d                   '), trim('各维轴重复次数                                   '), trim('04_repeat_axis         '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('times__1d                    '), trim('填充重复次数                                     '), trim('04_apad                '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('times__1d                    '), trim('填充重复次数                                     '), trim('04_bpad                '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('times__1d                    '), trim('填充重复次数                                     '), trim('04_lpad                '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('times__1d                    '), trim('填充重复次数                                     '), trim('04_rpad                '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('chunk_len__1d                '), trim('块儿高宽规格                                     '), trim('04_chunk_transpose     '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dims__1d                     '), trim('转置的两个维度，缺省为高宽两维度                 '), trim('04_transpose           '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dims__1d                     '), trim('旧维度转置后所在新维度位置上                     '), trim('04_transpose_nd        '),  1, numrange(1.0, 4.0, '[]') union all
     select trim('dims_from_to__1d             '), trim('旋转的正方向起止两个维度                         '), trim('04_turn_90             '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dims__1d                     '), trim('旋转的两个维度                                   '), trim('04_turn_180            '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dim__1d                      '), trim('镜像维度，即镜面法面的维度                       '), trim('04_mirror              '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('dims_from_to__1d             '), trim('合并的两个维度                                   '), trim('04_mx_ele_3d_2_2d      '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dim_pin_ele__1d              '), trim('定住元素顺序的维度                               '), trim('04_mx_ele_3d_2_2d      '),  2, numrange(3.0, 3.0, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('拆分分组元素个数                                 '), trim('04_mx_ele_2d_2_3d      '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('dims_from__1d                '), trim('被拆分维度                                       '), trim('04_mx_ele_2d_2_3d      '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('dims_new__1d                 '), trim('新生维度                                         '), trim('04_mx_ele_2d_2_3d      '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('dim_pin__1d                  '), trim('是否在被拆分维度保留原来的元素顺序               '), trim('04_mx_ele_2d_2_3d      '),  4, numrange(4.0, 4.0, '[]') union all
     select trim('dims_from_to__1d             '), trim('合并的两个维度                                   '), trim('04_mx_ele_4d_2_3d      '),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dim_pin_ele__1d              '), trim('定住元素顺序的维度                               '), trim('04_mx_ele_4d_2_3d      '),  2, numrange(3.0, 3.0, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('拆分分组元素个数                                 '), trim('04_mx_ele_3d_2_4d      '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('dims_from__1d                '), trim('被拆分维度                                       '), trim('04_mx_ele_3d_2_4d      '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('dims_new__1d                 '), trim('新生维度                                         '), trim('04_mx_ele_3d_2_4d      '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('dim_pin__1d                  '), trim('是否在被拆分维度保留原来的元素顺序               '), trim('04_mx_ele_3d_2_4d      '),  4, numrange(4.0, 4.0, '[]') union all
     select trim('dims_from_to__1d             '), trim('被扁平化的来源维度与跌落至维度                   '), trim('04_mx_ele_flatten_2dims'),  1, numrange(1.0, 2.0, '[]') union all
     select trim('dim_pin_ele__1d              '), trim('定住元素顺序的维度                               '), trim('04_mx_ele_flatten_2dims'),  3, numrange(3.0, 3.0, '[]') union all
     select trim('dim_sliced__1d               '), trim('切片维度                                         '), trim('04_mx_slice_3d_2_2d    '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_pos__1d                '), trim('切片位置序号                                     '), trim('04_mx_slice_3d_2_2d    '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('dim_sliced__2d               '), trim('切片维度(两个)                                   '), trim('04_mx_slice_4d_2_2d    '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_pos__2d                '), trim('切片位置序号(两个)                               '), trim('04_mx_slice_4d_2_2d    '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('dim_sliced__1d               '), trim('切片维度                                         '), trim('04_mx_slice_4d_2_3d    '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_pos__1d                '), trim('切片位置序号                                     '), trim('04_mx_slice_4d_2_3d    '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('ascend_time__1d              '), trim('加壳次数                                         '), trim('04_mx_ascend_dim       '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('descend_time__1d             '), trim('去壳次数                                         '), trim('04_mx_descend_dim      '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('pick_cnt__1d                 '), trim('随机拣取个数                                     '), trim('04_rand_pick_y         '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('pick_cnt__1d                 '), trim('随机拣取个数                                     '), trim('04_rand_pick_x         '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('pick_cnt__1d                 '), trim('随机拣取个数                                     '), trim('04_rand_pick_x3        '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('pick_cnt__1d                 '), trim('随机拣取个数                                     '), trim('04_rand_pick_x4        '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('chunk_range_lower__2d        '), trim('切块儿位置各维度下标序号下界                     '), trim('04_chunk               '),  1, numrange(1.0, null, '[]') union all
     select trim('chunk_range_upper__2d        '), trim('切块儿位置各维度下标序号上界                     '), trim('04_chunk               '),  2, numrange(1.0, null, '[]') union all
     select trim('slice_range_lower__2d        '), trim('切片位置下标序号下界，为空则缺省为 1             '), trim('04_slice_y             '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_range_upper__2d        '), trim('切片位置下标序号上界，为空则缺省为自变量第一维长 '), trim('04_slice_y             '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('slice_range_lower__2d        '), trim('切片位置下标序号下界，为空则缺省为 1             '), trim('04_slice_x             '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_range_upper__2d        '), trim('切片位置下标序号上界，为空则缺省为自变量第二维长 '), trim('04_slice_x             '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('slice_range_lower__2d        '), trim('切片位置下标序号下界，为空则缺省为 1             '), trim('04_slice_x3            '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_range_upper__2d        '), trim('切片位置下标序号上界，为空则缺省为自变量第三维长 '), trim('04_slice_x3            '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('slice_range_lower__2d        '), trim('切片位置下标序号下界，为空则缺省为 1             '), trim('04_slice_x4            '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('slice_range_upper__2d        '), trim('切片位置下标序号上界，为空则缺省为自变量第四维长 '), trim('04_slice_x4            '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('period__2d_1d                '), trim('采样周期                                         '), trim('04_sample_y            '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__2d_1d            '), trim('窗口宽度，null 表示不约束                        '), trim('04_sample_y            '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('simp_ranges_lowers__2d       '), trim('若干采样范围下界                                 '), trim('04_sample_y            '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('simp_ranges_uppers__2d       '), trim('若干采样范围上界                                 '), trim('04_sample_y            '),  4, numrange(4.0, 4.0, '[]') union all
     select trim('period__2d_1d                '), trim('采样周期                                         '), trim('04_sample_x            '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__2d_1d            '), trim('窗口宽度，null 表示不约束                        '), trim('04_sample_x            '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('simp_ranges_lowers__2d       '), trim('若干采样范围下界                                 '), trim('04_sample_x            '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('simp_ranges_uppers__2d       '), trim('若干采样范围上界                                 '), trim('04_sample_x            '),  4, numrange(4.0, 4.0, '[]') union all
     select trim('period__2d_1d                '), trim('采样周期                                         '), trim('04_sample_x3           '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__2d_1d            '), trim('窗口宽度，null 表示不约束                        '), trim('04_sample_x3           '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('simp_ranges_lowers__2d       '), trim('若干采样范围下界                                 '), trim('04_sample_x3           '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('simp_ranges_uppers__2d       '), trim('若干采样范围上界                                 '), trim('04_sample_x3           '),  4, numrange(4.0, 4.0, '[]') union all
     select trim('period__2d_1d                '), trim('采样周期                                         '), trim('04_sample_x4           '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__2d_1d            '), trim('窗口宽度，null 表示不约束                        '), trim('04_sample_x4           '),  2, numrange(2.0, 2.0, '[]') union all
     select trim('simp_ranges_lowers__2d       '), trim('若干采样范围下界                                 '), trim('04_sample_x4           '),  3, numrange(3.0, 3.0, '[]') union all
     select trim('simp_ranges_uppers__2d       '), trim('若干采样范围上界                                 '), trim('04_sample_x4           '),  4, numrange(4.0, 4.0, '[]') union all
     select trim('upper_fill_value__1d         '), trim('上三角填充值                                     '), trim('04_lower_tri_mx        '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('lower_fill_value__1d         '), trim('下三角填充值                                     '), trim('04_upper_tri_mx        '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('upper_fill_value_ex__1d      '), trim('欠上三角填充值                                   '), trim('04_lower_tri_mx_ex     '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('lower_fill_value_ex__1d      '), trim('欠下三角填充值                                   '), trim('04_upper_tri_mx_ex     '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('mask_element__1d             '), trim('遮盖填充值                                       '), trim('04_lmask               '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('mask_element__1d             '), trim('遮盖填充值                                       '), trim('04_rmask               '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('mask_element__1d             '), trim('遮盖填充值                                       '), trim('04_amask               '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('mask_element__1d             '), trim('遮盖填充值                                       '), trim('04_bmask               '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('1d_2_2d_cnt_per_grp__1d      '), trim('扁平化之前的 2d 宽度规格                         '), trim('05_pool_max_2d_grp_x   '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__1d               '), trim('滑动窗口高宽规格                                 '), trim('05_pool_max_2d_grp_x   '),  2, numrange(2.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_pool_max_2d_grp_x   '),  3, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_pool_max_2d_grp_x   '),  4, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_pool_max_2d_grp_x   '),  5, numrange(10.0, 10.0, '[]') union all
     select trim('1d_2_2d_cnt_per_grp__1d      '), trim('扁平化之前的 2d 宽度规格                         '), trim('05_pool_avg_2d_grp_x   '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__1d               '), trim('滑动窗口高宽规格                                 '), trim('05_pool_avg_2d_grp_x   '),  2, numrange(2.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_pool_avg_2d_grp_x   '),  3, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_pool_avg_2d_grp_x   '),  4, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_pool_avg_2d_grp_x   '),  5, numrange(10.0, 10.0, '[]') union all
     select trim('input_arr_len_x__1d          '), trim('扁平化之后的 1d 宽度规格                         '), trim('05_pool_avg_2d_grp_x   '),  6, numrange(11.0, 11.0, '[]') union all
     select trim('window_len__1d               '), trim('滑动窗口高宽规格                                 '), trim('05_pool_max            '),  1, numrange(2.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_pool_max            '),  2, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_pool_max            '),  3, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_pool_max            '),  4, numrange(10.0, 10.0, '[]') union all
     select trim('window_len__1d               '), trim('滑动窗口高宽规格                                 '), trim('05_pool_avg            '),  1, numrange(2.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_pool_avg            '),  2, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_pool_avg            '),  3, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_pool_avg            '),  4, numrange(10.0, 10.0, '[]') union all
     select trim('window_len__1d               '), trim('滑动窗口高宽规格                                 '), trim('05_pool_none           '),  1, numrange(2.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_pool_none           '),  2, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_pool_none           '),  3, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_pool_none           '),  4, numrange(10.0, 10.0, '[]') union all
     select trim('1d_2_2d_cnt_per_grp__1d      '), trim('扁平化之前的 2d 宽度规格                         '), trim('05_conv_2d_grp_x       '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('window_len__1d               '), trim('滑动窗口高宽规格                                 '), trim('05_conv_2d_grp_x       '),  2, numrange(2.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_2d_grp_x       '),  3, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_2d_grp_x       '),  4, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_2d_grp_x       '),  5, numrange(10.0, 10.0, '[]') union all
  -- select trim('window_bias_label__1d        '), trim('是否有卷积偏移量                                 '), trim('05_conv_2d_grp_x       '),  6, numrange(12.0, 12.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_2d             '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_2d             '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_2d             '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('padding_mode__1d             '), trim('pad 模式。1: 值填充；2: 环绕填充                 '), trim('05_conv_2d             '),  4, numrange(11.0, 11.0, '[]') union all
     select trim('tunnel_axis__1d              '), trim('隧道所跨维轴                                     '), trim('05_tunnel_conv         '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_add            '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_add            '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_add            '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_sub            '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_sub            '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_sub            '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_mul            '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_mul            '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_mul            '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_div            '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_div            '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_div            '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_pow            '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_pow            '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_pow            '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_log            '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_log            '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_log            '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('window_len_heigh__1d         '), trim('滑动窗口高度规格                                 '), trim('05_conv_prod_mx        '),  1, numrange(2.0, 2.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_prod_mx        '),  2, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_prod_mx        '),  3, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_prod_mx        '),  4, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_de_sub         '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_de_sub         '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_de_sub         '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_de_div         '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_de_div         '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_de_div         '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_de_pow         '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_de_pow         '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_de_pow         '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_de_log         '),  1, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_de_log         '),  2, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_de_log         '),  3, numrange(10.0, 10.0, '[]') union all
     select trim('window_len_width__1d         '), trim('滑动窗口宽度规格                                 '), trim('05_conv_de_prod_mx     '),  1, numrange(3.0, 3.0, '[]') union all
     select trim('stride__1d                   '), trim('纵向和横向步长                                   '), trim('05_conv_de_prod_mx     '),  2, numrange(4.0, 5.0, '[]') union all
     select trim('padding__1d                  '), trim('上下左右补齐行数/列数                            '), trim('05_conv_de_prod_mx     '),  3, numrange(6.0, 9.0, '[]') union all
     select trim('padding_value__1d            '), trim('补齐填充元素值                                   '), trim('05_conv_de_prod_mx     '),  4, numrange(10.0, 10.0, '[]') union all
     select trim('mx_cnt__1d                   '), trim('聚合数量，也即 count                             '), trim('06_aggr_mx_avg         '),  1, numrange(1.0, 1.0, '[]') union all
     select trim('len_y__1d                    '), trim('聚合字段的 y 长度                                '), trim('06_aggr_mx_concat_y    '),  1, numrange(1.0, null, '[]') union all
     select trim('len_x__1d                    '), trim('聚合字段的 x 长度                                '), trim('06_aggr_mx_concat_x    '),  1, numrange(1.0, null, '[]') union all
     select trim('len_x3__1d                   '), trim('聚合字段的 x3 长度                               '), trim('06_aggr_mx_concat_x3   '),  1, numrange(1.0, null, '[]') union all
     select trim('len_x4__1d                   '), trim('聚合字段的 x4 长度                               '), trim('06_aggr_mx_concat_x4   '),  1, numrange(1.0, null, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('07_aggr_slice_sum      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('07_aggr_slice_avg      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('07_aggr_slice_max      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('07_aggr_slice_min      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('各维度每分组长度。维长可为 null，即缺省最大维长  '), trim('07_aggr_slice_prod     '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('切块各维度长度。维长可为 null，即缺省最大维长    '), trim('07_aggr_chunk_sum      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('切块各维度长度。维长可为 null，即缺省最大维长    '), trim('07_aggr_chunk_avg      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('切块各维度长度。维长可为 null，即缺省最大维长    '), trim('07_aggr_chunk_max      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('切块各维度长度。维长可为 null，即缺省最大维长    '), trim('07_aggr_chunk_min      '),  1, numrange(1, 4, '[]') union all
     select trim('cnt_per_grp__1d              '), trim('切块各维度长度。维长可为 null，即缺省最大维长    '), trim('07_aggr_chunk_prod     '),  1, numrange(1, 4, '[]')
)
select 
  'node_fn_asso_value' as enum_name, 
  enum_group || '_asso_' || enum_order as enum_key, 
  a_param_name || a_cn_desc as enum_value, 
  enum_group,
  enum_order,
  enum_range
from cte_node_fn_asso_value
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_group = excluded.enum_group
, enum_order = excluded.enum_order
, enum_range = excluded.enum_range
;

-- -------------------------------------------------------------------------
-- node_fn_type_delta_method   -- 算子求导方式
-- delete from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta_method';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_group     ,
  enum_order
)
with cte_node_fn_type(enum_key, enum_value, enum_group) as 
-- enum_group: 
--   0. 前向传播后，求 ddepdt/dindepdt
--   1. 反向传播。直接求 dloss/dindepdt, 而不需显式求取 ddepdt/dindepdt
-- enum_value:
--   第一位控制：第一目求导是否需要自变量
--   第二位控制：第二目求导是否需要自变量
--   第三位控制：第一目求导是否需要另一自变量
--   第四位控制：第二目求导是否需要另一自变量
--   第五位控制：第一目求导是否需要因变量
--   第六位控制：第二目求导是否需要因变量
--   第七位控制：第一目求导是否用到自变量维长规格
--   第八位控制：第二目求导是否用到自变量维长规格
(
  -- select trim('00_full_dataset        '),         trim(''),            '' union all
  -- select trim('00_const               '),         trim(''),            '' union all
  -- select trim('00_buff_slice_rand_pick'),         trim(''),            '' union all
  select trim('00_none                '),         trim('00000010'),            '1'  union all
  select trim('01_add                 '),         trim('00001110'),            '0'  union all
  select trim('01_mul                 '),         trim('00110000'),            '0'  union all
  select trim('01_sub                 '),         trim('00001110'),            '0'  union all
  select trim('01_0sub                '),         trim('00001010'),            '0'  union all
  select trim('01_div                 '),         trim('01110000'),            '0'  union all
  select trim('01_1div                '),         trim('10000000'),            '0'  union all
  select trim('01_pow                 '),         trim('10111100'),            '0'  union all
  select trim('01_log                 '),         trim('11111000'),            '0'  union all
  select trim('01_exp                 '),         trim('00001000'),            '0'  union all
  select trim('01_ln                  '),         trim('10000000'),            '0'  union all
  select trim('01_abs                 '),         trim('10000000'),            '0'  union all
  select trim('01_prod_mx             '),         trim('00110011'),            '1'  union all
  select trim('01_chunk_prod_mx       '),         trim('00110011'),            '1'  union all
  select trim('02_sin                 '),         trim('10000000'),            '0'  union all
  select trim('02_cos                 '),         trim('10000000'),            '0'  union all
  select trim('02_tan                 '),         trim('10000000'),            '0'  union all
  select trim('02_cot                 '),         trim('10000000'),            '0'  union all
  select trim('02_sec                 '),         trim('10000000'),            '0'  union all
  select trim('02_csc                 '),         trim('10000000'),            '0'  union all
  select trim('02_asin                '),         trim('10000000'),            '0'  union all
  select trim('02_acos                '),         trim('10000000'),            '0'  union all
  select trim('02_atan                '),         trim('10000000'),            '0'  union all
  select trim('02_acot                '),         trim('10000000'),            '0'  union all
  select trim('02_sinh                '),         trim('10000000'),            '0'  union all
  select trim('02_cosh                '),         trim('10000000'),            '0'  union all
  select trim('02_tanh                '),         trim('00001000'),            '0'  union all
  -- -- select trim('02_sech                '),         trim('10001000'),            '0'  union all
  -- -- select trim('02_csch                '),         trim('10001000'),            '0'  union all
  select trim('02_asinh               '),         trim('10000000'),            '0'  union all
  select trim('02_acosh               '),         trim('10000000'),            '0'  union all
  select trim('02_atanh               '),         trim('10000000'),            '0'  union all
  select trim('03_sigmoid             '),         trim('00001000'),            '0'  union all
  select trim('03_absqrt              '),         trim('10000000'),            '0'  union all
  select trim('03_relu                '),         trim('10000000'),            '0'  union all
  select trim('03_leaky_relu          '),         trim('10000000'),            '0'  union all
  select trim('03_elu                 '),         trim('10000000'),            '0'  union all
  select trim('03_selu                '),         trim('10001000'),            '0'  union all
  select trim('03_gelu                '),         trim('10000000'),            '0'  union all
  select trim('03_swish               '),         trim('10001000'),            '0'  union all
  select trim('03_softplus            '),         trim('10000000'),            '0'  union all
  select trim('03_boxcox              '),         trim('10000000'),            '0'  union all
  select trim('03_softmax             '),         trim('10001000'),            '1'  union all
  select trim('03_softmax_ex          '),         trim('10001000'),            '1'  union all
  select trim('03_zscore              '),         trim('10001000'),            '0'  union all
  select trim('04_new                 '),         trim('00000000'),            '1'  union all
  select trim('04_reshape             '),         trim('00000010'),            '1'  union all
  select trim('04_repeat_axis         '),         trim('00000000'),            '1'  union all
  select trim('04_apad                '),         trim('00000011'),            '1'  union all
  select trim('04_bpad                '),         trim('00000011'),            '1'  union all
  select trim('04_lpad                '),         trim('00000011'),            '1'  union all
  select trim('04_rpad                '),         trim('00000011'),            '1'  union all
  select trim('04_transpose           '),         trim('00000000'),            '1'  union all
  select trim('04_transpose_i         '),         trim('00000000'),            '1'  union all
  select trim('04_chunk_transpose     '),         trim('00000000'),            '1'  union all
  select trim('04_transpose_nd        '),         trim('00000000'),            '1'  union all
  select trim('04_turn_90             '),         trim('00000000'),            '1'  union all
  select trim('04_turn_180            '),         trim('00000000'),            '1'  union all
  select trim('04_mirror              '),         trim('00000000'),            '1'  union all
  select trim('04_mx_ele_3d_2_2d      '),         trim('00000010'),            '1'  union all
  select trim('04_mx_ele_2d_2_3d      '),         trim('00000000'),            '1'  union all
  select trim('04_mx_ele_4d_2_3d      '),         trim('00000010'),            '1'  union all
  select trim('04_mx_ele_3d_2_4d      '),         trim('00000000'),            '1'  union all
  select trim('04_mx_ele_flatten_2dims'),         trim('00000010'),            '1'  union all
  select trim('04_mx_slice_3d_2_2d    '),         trim('00000010'),            '1'  union all
  select trim('04_mx_slice_4d_2_2d    '),         trim('00000010'),            '1'  union all
  select trim('04_mx_slice_4d_2_3d    '),         trim('00000010'),            '1'  union all
  select trim('04_mx_ascend_dim       '),         trim('00000000'),            '1'  union all
  select trim('04_mx_descend_dim      '),         trim('00000000'),            '1'  union all
  -- select trim('04_rand_pick_y         '),         trim(''),            '' union all
  -- select trim('04_rand_pick_x         '),         trim(''),            '' union all
  -- select trim('04_rand_pick_x3        '),         trim(''),            '' union all
  -- select trim('04_rand_pick_x4        '),         trim(''),            '' union all
  select trim('04_chunk               '),         trim('00000010'),            '1'  union all
  select trim('04_slice_y             '),         trim('00000010'),            '1'  union all
  select trim('04_slice_x             '),         trim('00000010'),            '1'  union all
  select trim('04_slice_x3            '),         trim('00000010'),            '1'  union all
  select trim('04_slice_x4            '),         trim('00000010'),            '1'  union all
  select trim('04_sample_y            '),         trim('00000010'),            '1'  union all
  select trim('04_sample_x            '),         trim('00000010'),            '1'  union all
  select trim('04_sample_x3           '),         trim('00000010'),            '1'  union all
  select trim('04_sample_x4           '),         trim('00000010'),            '1'  union all
  select trim('04_lower_tri_mx        '),         trim('00000000'),            '1'  union all
  select trim('04_upper_tri_mx        '),         trim('00000000'),            '1'  union all
  select trim('04_lower_tri_mx_ex     '),         trim('00000000'),            '1'  union all
  select trim('04_upper_tri_mx_ex     '),         trim('00000000'),            '1'  union all
  select trim('04_lmask               '),         trim('00100000'),            '1'  union all
  select trim('04_rmask               '),         trim('00100000'),            '1'  union all
  select trim('04_amask               '),         trim('00100000'),            '1'  union all
  select trim('04_bmask               '),         trim('00100000'),            '1'  union all
  select trim('05_pool_max_2d_grp_x   '),         trim('10001000'),            '1'  union all
  select trim('05_pool_avg_2d_grp_x   '),         trim('00000000'),            '1'  union all
  select trim('05_pool_max            '),         trim('10001000'),            '1'  union all
  select trim('05_pool_avg            '),         trim('00000000'),            '1'  union all
  select trim('05_pool_none           '),         trim('00000010'),            '1'  union all
  select trim('05_conv_2d_grp_x       '),         trim('00110000'),            '1'  union all
  select trim('05_conv_2d             '),         trim('00110001'),            '1'  union all
  select trim('05_tunnel_conv         '),         trim('00110001'),            '1'  union all
  select trim('05_conv_add            '),         trim('00110011'),            '1'  union all
  select trim('05_conv_sub            '),         trim('00110011'),            '1'  union all
  select trim('05_conv_mul            '),         trim('00110011'),            '1'  union all
  select trim('05_conv_div            '),         trim('01110010'),            '1'  union all
  select trim('05_conv_pow            '),         trim('11111100'),            '1'  union all
  select trim('05_conv_log            '),         trim('11111000'),            '1'  union all
  select trim('05_conv_prod_mx        '),         trim('00110011'),            '1'  union all
  select trim('05_conv_de_sub         '),         trim('00110011'),            '1'  union all
  select trim('05_conv_de_div         '),         trim('01110010'),            '1'  union all
  select trim('05_conv_de_pow         '),         trim('11111100'),            '1'  union all
  select trim('05_conv_de_log         '),         trim('11111000'),            '1'  union all
  select trim('05_conv_de_prod_mx     '),         trim('00110011'),            '1'  union all
-- 对于聚合算子的所有自变量，无论顺序，统一以 path_ord_no = 1 配置该控制
  select trim('06_aggr_mx_sum         '),         trim('00001010'),            '0'  union all
  select trim('06_aggr_mx_prod        '),         trim('10001000'),            '0'  union all
  select trim('06_aggr_mx_avg         '),         trim('00001010'),            '0'  union all
  select trim('06_aggr_mx_max         '),         trim('10001000'),            '0'  union all
  select trim('06_aggr_mx_min         '),         trim('10001000'),            '0'  union all
  select trim('06_aggr_mx_concat_y    '),         trim('00000010'),            '1'  union all
  select trim('06_aggr_mx_concat_x    '),         trim('00000010'),            '1'  union all
  select trim('06_aggr_mx_concat_x3   '),         trim('00000010'),            '1'  union all
  select trim('06_aggr_mx_concat_x4   '),         trim('00000010'),            '1'  union all
  select trim('07_aggr_slice_sum      '),         trim('00000010'),            '1'  union all
  select trim('07_aggr_slice_prod     '),         trim('10001000'),            '1'  union all
  select trim('07_aggr_slice_avg      '),         trim('00000010'),            '1'  union all
  select trim('07_aggr_slice_max      '),         trim('10001000'),            '1'  union all
  select trim('07_aggr_slice_min      '),         trim('10001000'),            '1'  union all
  select trim('07_aggr_chunk_sum      '),         trim('00000010'),            '1'  union all
  select trim('07_aggr_chunk_prod     '),         trim('10001000'),            '1'  union all
  select trim('07_aggr_chunk_avg      '),         trim('00000010'),            '1'  union all
  select trim('07_aggr_chunk_max      '),         trim('10001000'),            '1'  union all
  select trim('07_aggr_chunk_min      '),         trim('10001000'),            '1'
)
select 
  'node_fn_type_delta_method' as enum_name, 
  enum_key, 
  enum_value, 
  enum_group,
  row_number() over() 
    + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta_method'), 0) 
  as enum_order
from cte_node_fn_type
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_group = excluded.enum_group
, enum_order = excluded.enum_order
;

-- -------------------------------------------------------------------------
-- nn_sess_status   -- 模型部署的 session 状态
-- delete from sm_sc.tb_dic_enum where enum_name = 'nn_sess_status';
insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_order
)
with 
cte_nn_sess_status(a_enum_key, a_enum_value) as
(
  select '0', 'idle'   union all 
  select '1', 'in-use'
) 
select 
  'nn_sess_status' as enum_name
, a_enum_key
, a_enum_value
, row_number() over()
from cte_nn_sess_status
on conflict(enum_name, enum_key)
do update
set 
  enum_value = excluded.enum_value
, enum_order = excluded.enum_order
;

-- -- -----------------------------------------------------------
-- -- 矩阵乘法近似算法的字典表
-- do 
-- $$
-- declare 
--   v_root    int    := 65536 * 4;    -- 65536;
--   v_root_x  float  := v_root;
--   v_range   int    := 20;
--   v_dic_arr float[];
-- begin
--   truncate table sm_sc.__vt_prod_mx_quantum_dic;
--   insert into sm_sc.__vt_prod_mx_quantum_dic
--   (
--     sign_reciprocal_quantum_key   
--   , sign_reciprocal_quantum_val   
--   , sign_reciprocal_quantum_desc  
--   )
--   select 
--     -- 按照 sign_reciprocal_quantum_val 大小排序的连续顺序号，以尽量提高寻址速度，尤其避免寻址过程中的乘法计算
--     -- a_no + v_root * v_range + sign(sign(a_no + v_root_x * v_range) + 0.5)  as sign_reciprocal_quantum_key     
--     a_no as sign_reciprocal_quantum_key     
--   , 2.0 ^ (a_no / v_root_x) as sign_reciprocal_quantum_val
--   , '2.0 ^ (' || a_no || ' / ' || v_root_x || ')' as sign_reciprocal_quantum_desc
--   -- -- from generate_series(- v_root * v_range, v_root * v_range) tb_a_no(a_no)
--   from generate_series(- v_root * v_range, 0) tb_a_no(a_no)
--   -- union all 
--   -- select 
--   --   0             as sign_reciprocal_quantum_key
--   -- , 0.0 :: float  as sign_reciprocal_quantum_desc
--   -- , '0'           as sign_reciprocal_quantum_desc
--   ;
--   
--   -- v_dic_arr[- v_root * v_range : v_root * v_range] := 
--   v_dic_arr[- v_root * v_range : 0] := 
--     (
--       select 
--         array_agg(sign_reciprocal_quantum_val order by sign_reciprocal_quantum_key)
--       from sm_sc.__vt_prod_mx_quantum_dic
--     )
--   ;
--   
--   truncate table sm_sc.__vt_prod_mx_quantum_dic_arr;
--   insert into sm_sc.__vt_prod_mx_quantum_dic_arr
--   (
--     sign_reciprocal_quantum_arr
--   , sign_reciprocal_quantum_arr_desc
--   )
--   values
--   (
--     v_dic_arr
--   , array[v_root, v_range]
--   )
--   ;
-- end
-- $$
-- language plpgsql;