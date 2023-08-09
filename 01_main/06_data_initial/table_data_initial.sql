insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_group     ,
  enum_order     ,
  enum_range
)
-- 各种算子协参结构规约
select 
  'node_fn_asso_value'            as         enum_name      ,
  '1'                             as         enum_key       ,
  'i_1d_2_2d_cnt_per_grp'         as         enum_value     ,
  'conv_2d'                       as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '2'                             as         enum_key       ,
  'i_window_len'                  as         enum_value     ,
  'conv_2d'                       as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, 3.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '3'                             as         enum_key       ,
  'i_stride'                      as         enum_value     ,
  'conv_2d'                       as         enum_group     ,
  3                               as         enum_order     ,
  numrange(4.0, 5.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '4'                             as         enum_key       ,
  'i_padding'                     as         enum_value     ,
  'conv_2d'                       as         enum_group     ,
  4                               as         enum_order     ,
  numrange(6.0, 9.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '5'                             as         enum_key       ,
  'i_padding_value'               as         enum_value     ,
  'conv_2d'                       as         enum_group     ,
  5                               as         enum_order     ,
  numrange(10.0, 10.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '6'                             as         enum_key       ,
  'i_input_arr_len_x'             as         enum_value     ,
  'conv_2d'                       as         enum_group     ,
  6                               as         enum_order     ,
  numrange(11.0, 11.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '7'                             as         enum_key       ,
  'i_window_bias_label'           as         enum_value     ,     -- 1.0  : true
  'conv_2d'                       as         enum_group     ,
  7                               as         enum_order     ,
  numrange(12.0, 12.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '8'                             as         enum_key       ,
  'alpha'                         as         enum_value     ,
  'elu'                           as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '9'                             as         enum_key       ,
  'alpha'                         as         enum_value     ,
  'leaky_relu'                    as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '10'                             as         enum_key       ,
  'i_1d_2_2d_cnt_per_grp'         as         enum_value     ,
  'pool_max'                      as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '11'                            as         enum_key       ,
  'i_window_len'                  as         enum_value     ,
  'pool_max'                      as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, 3.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '12'                            as         enum_key       ,
  'i_stride'                      as         enum_value     ,
  'pool_max'                      as         enum_group     ,
  3                               as         enum_order     ,
  numrange(4.0, 5.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '13'                            as         enum_key       ,
  'i_padding'                     as         enum_value     ,
  'pool_max'                      as         enum_group     ,
  4                               as         enum_order     ,
  numrange(6.0, 9.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '14'                            as         enum_key       ,
  'i_padding_value'               as         enum_value     ,
  'pool_max'                      as         enum_group     ,
  5                               as         enum_order     ,
  numrange(10.0, 10.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '15'                            as         enum_key       ,
  'i_input_arr_len_x'             as         enum_value     ,
  'pool_max'                      as         enum_group     ,
  6                               as         enum_order     ,
  numrange(11.0, 11.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '16'                            as         enum_key       ,
  'i_1d_2_2d_cnt_per_grp'         as         enum_value     ,
  'pool_avg'                      as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '17'                            as         enum_key       ,
  'i_window_len'                  as         enum_value     ,
  'pool_avg'                      as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, 3.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '18'                            as         enum_key       ,
  'i_stride'                      as         enum_value     ,
  'pool_avg'                      as         enum_group     ,
  3                               as         enum_order     ,
  numrange(4.0, 5.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '19'                            as         enum_key       ,
  'i_padding'                     as         enum_value     ,
  'pool_avg'                      as         enum_group     ,
  4                               as         enum_order     ,
  numrange(6.0, 9.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '20'                            as         enum_key       ,
  'i_padding_value'               as         enum_value     ,
  'pool_avg'                      as         enum_group     ,
  5                               as         enum_order     ,
  numrange(10.0, 10.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '21'                            as         enum_key       ,
  'i_input_arr_len_x'             as         enum_value     ,
  'pool_avg'                      as         enum_group     ,
  6                               as         enum_order     ,
  numrange(11.0, 11.0, '[]')      as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '22'                            as         enum_key       ,
  'sample_cnt'                    as         enum_value     ,
  'rand_pick_x'                   as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '23'                            as         enum_key       ,
  'sample_cnt'                    as         enum_value     ,
  'rand_pick_y'                   as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '24'                            as         enum_key       ,
  'lower_idx'                     as         enum_value     ,
  'slice_y'                       as         enum_group     ,  -- 暂不支持多区间切片
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '25'                            as         enum_key       ,
  'upper_idx'                     as         enum_value     ,
  'slice_y'                       as         enum_group     ,  -- 暂不支持多区间切片
  2                               as         enum_order     ,
  numrange(2.0, 2.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '26'                            as         enum_key       ,
  'lower_idx'                     as         enum_value     ,
  'slice_x'                       as         enum_group     ,  -- 暂不支持多区间切片
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '27'                            as         enum_key       ,
  'upper_idx'                     as         enum_value     ,
  'slice_x'                       as         enum_group     ,  -- 暂不支持多区间切片
  2                               as         enum_order     ,
  numrange(2.0, 2.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '28'                            as         enum_key       ,
  '2d_length_y'                   as         enum_value     ,
  'prod_mx'                       as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '29'                            as         enum_key       ,
  '2d_length_wx'                  as         enum_value     ,   -- 矩阵乘法 x |**| w 的 array_length(x, 2), 也即 array_length(w, 1)
  'prod_mx'                       as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, 2.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '30'                            as         enum_key       ,
  '2d_length_x'                   as         enum_value     ,
  'prod_mx'                       as         enum_group     ,
  3                               as         enum_order     ,
  numrange(3.0, 3.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '31'                            as         enum_key       ,
  'weight_arr_len'                as         enum_value     ,   -- weight 的 array_length
  'const'                        as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 2.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '32'                            as         enum_key       ,
  'running_back_nodes_lens'       as         enum_value     ,
  'agg_concat_y'                  as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, null, '[]')       as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '33'                            as         enum_key       ,
  'running_back_nodes_lens'       as         enum_value     ,
  'agg_concat_x'                  as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, null, '[]')       as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '34'                            as         enum_key       ,
  'running_rand_idx'              as         enum_value     ,
  'rand_pick_y'                   as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, null, '[]')       as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '35'                            as         enum_key       ,
  'running_rand_idx'              as         enum_value     ,
  'rand_pick_x'                   as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, null, '[]')       as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '36'                            as         enum_key       ,
  'slice_range_lowers'            as         enum_value     ,
  'nn_buff_slice_rand_pick'       as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 1.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '37'                            as         enum_key       ,
  'slice_range_uppers'            as         enum_value     ,
  'nn_buff_slice_rand_pick'       as         enum_group     ,
  2                               as         enum_order     ,
  numrange(2.0, 2.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '38'                            as         enum_key       ,
  'rand_pick_cnts'                as         enum_value     ,
  'nn_buff_slice_rand_pick'       as         enum_group     ,
  3                               as         enum_order     ,
  numrange(3.0, 3.0, '[]')        as         enum_range
union all
select 
  'node_fn_asso_value'            as         enum_name      ,
  '39'                            as         enum_key       ,
  'yx_times'                      as         enum_value     ,
  'new'                           as         enum_group     ,
  1                               as         enum_order     ,
  numrange(1.0, 2.0, '[]')        as         enum_range
;
commit;

insert into sm_sc.tb_dic_enum
(
  enum_name      ,
  enum_key       ,
  enum_value     ,
  enum_group     ,
  enum_order
)
-- 损失函数类型
select 
  'loss_fn_type'                  as         enum_name      ,
  '1'                             as         enum_key       ,
  '最小二乘法'                    as         enum_value     ,
  null                            as         enum_group     ,
  1                               as         enum_order
union all
select 
  'loss_fn_type'                  as         enum_name      ,
  '2'                             as         enum_key       ,
  '交叉熵'                        as         enum_value     ,
  null                            as         enum_group     ,
  2                               as         enum_order
union all
-- -- -- 节点初始化标记
-- -- select 
-- --   'initial_label'                 as         enum_name      ,
-- --   '0'                             as         enum_key       ,
-- --   '普通传播节点'                  as         enum_value     ,
-- --   null                            as         enum_group     ,
-- --   1                               as         enum_order
-- -- union all
-- -- select 
-- --   'initial_label'                 as         enum_name      ,
-- --   '1'                             as         enum_key       ,
-- --   '初始化一次即可'                as         enum_value     ,
-- --   null                            as         enum_group     ,
-- --   2                               as         enum_order
-- -- union all
-- -- select 
-- --   'initial_label'                 as         enum_name      ,
-- --   '2'                             as         enum_key       ,
-- --   '前向传播节点起点'              as         enum_value     ,
-- --   null                            as         enum_group     ,
-- --   3                               as         enum_order
-- -- union all
-- 节点类型
select 
  'node_type'                     as         enum_name      ,
  'input'                         as         enum_key       ,
  'input'                         as         enum_value     ,
  null                            as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_type'                     as         enum_name      ,
  'output'                        as         enum_key       ,
  'output'                        as         enum_value     ,
  null                            as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_type'                     as         enum_name      ,
  'offset'                        as         enum_key       ,
  'input'                         as         enum_value     ,
  null                            as         enum_group     ,
  3                               as         enum_order
union all
select 
  'node_type'                     as         enum_name      ,
  'weight'                        as         enum_key       ,
  'train'                         as         enum_value     ,
  null                            as         enum_group     ,
  4                               as         enum_order
union all
select 
  'node_type'                     as         enum_name      ,
  'prod_input'                    as         enum_key       ,   -- 测试集、验证集的输入入口，与训练无关，sm_sc.fv_nn_in_out 会用到
  'prod'                          as         enum_value     ,
  null                            as         enum_group     ,
  5                               as         enum_order
union all

-- 以下为基础运算类型
select 
  'node_fn_type'                  as         enum_name      ,
  'const'                         as         enum_key       ,
  ''                              as         enum_value     ,
  '0_p'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'exp'                           as         enum_key       ,
  'sm_sc.fv_opr_exp'              as         enum_value     ,
  '1_p'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'ln'                            as         enum_key       ,
  'sm_sc.fv_opr_ln'               as         enum_value     ,
  '1_p'                           as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'sin'                           as         enum_key       ,
  'sm_sc.fv_sin'                  as         enum_value     ,
  '1_p'                           as         enum_group     ,
  3                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'cos'                           as         enum_key       ,
  'sm_sc.fv_cos'                  as         enum_value     ,
  '1_p'                           as         enum_group     ,
  4                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'tan'                           as         enum_key       ,
  'sm_sc.fv_tan'                  as         enum_value     ,
  '1_p'                           as         enum_group     ,
  5                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'cot'                           as         enum_key       ,
  'sm_sc.fv_cot'                  as         enum_value     ,
  '1_p'                           as         enum_group     ,
  6                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'sec'                           as         enum_key       ,
  'sm_sc.fv_sec'                  as         enum_value     ,
  '1_p'                           as         enum_group     ,
  7                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'csc'                           as         enum_key       ,
  'sm_sc.fv_csc'                  as         enum_value     ,
  '1_p'                           as         enum_group     ,
  8                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'asin'                          as         enum_key       ,
  'sm_sc.fv_asin'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  9                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'acos'                          as         enum_key       ,
  'sm_sc.fv_acos'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  10                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'atan'                          as         enum_key       ,
  'sm_sc.fv_atan'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  11                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'acot'                          as         enum_key       ,
  'sm_sc.fv_acot'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  12                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'asec'                          as         enum_key       ,
  'sm_sc.fv_asec'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  13                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'acsc'                          as         enum_key       ,
  'sm_sc.fv_acsc'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  14                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'sinh'                          as         enum_key       ,
  'sm_sc.fv_sinh'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  15                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'cosh'                          as         enum_key       ,
  'sm_sc.fv_cosh'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  16                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'tanh'                          as         enum_key       ,
  'sm_sc.fv_tanh'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  17                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'coth'                          as         enum_key       ,
  'sm_sc.fv_coth'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  18                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'sech'                          as         enum_key       ,
  'sm_sc.fv_sech'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  19                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'csch'                          as         enum_key       ,
  'sm_sc.fv_csch'                 as         enum_value     ,
  '1_p'                           as         enum_group     ,
  20                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'asinh'                         as         enum_key       ,
  'sm_sc.fv_asinh'                as         enum_value     ,
  '1_p'                           as         enum_group     ,
  21                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'acosh'                         as         enum_key       ,
  'sm_sc.fv_acosh'                as         enum_value     ,
  '1_p'                           as         enum_group     ,
  22                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'atanh'                         as         enum_key       ,
  'sm_sc.fv_atanh'                as         enum_value     ,
  '1_p'                           as         enum_group     ,
  23                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'acoth'                         as         enum_key       ,
  'sm_sc.fv_acoth'                as         enum_value     ,
  '1_p'                           as         enum_group     ,
  24                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'asech'                         as         enum_key       ,
  'sm_sc.fv_asech'                as         enum_value     ,
  '1_p'                           as         enum_group     ,
  25                              as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'acsch'                         as         enum_key       ,
  'sm_sc.fv_acsch'                as         enum_value     ,
  '1_p'                           as         enum_group     ,
  26                              as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'sigmoid'                        as         enum_key       ,
  'sm_sc.fv_sigmoid'               as         enum_value     ,
  '1_p'                            as         enum_group     ,
  27                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'relu'                           as         enum_key       ,
  'sm_sc.fv_relu'                  as         enum_value     ,
  '1_p'                            as         enum_group     ,
  28                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'leaky_relu'                     as         enum_key       ,
  'sm_sc.fv_leaky_relu'            as         enum_value     ,
  '1_p'                            as         enum_group     ,    -- 本来是双目，但第二目配置在 node 的协参
  29                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'elu'                            as         enum_key       ,
  'sm_sc.fv_elu'                   as         enum_value     ,    -- 本来是双目，但第二目配置在 node 的协参
  '1_p'                            as         enum_group     ,
  30                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'selu'                           as         enum_key       ,
  'sm_sc.fv_selu'                  as         enum_value     ,
  '1_p'                            as         enum_group     ,
  31                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'gelu'                           as         enum_key       ,
  'sm_sc.fv_gelu'                  as         enum_value     ,
  '1_p'                            as         enum_group     ,
  32                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'swish'                          as         enum_key       ,
  'sm_sc.fv_swish'                 as         enum_value     ,
  '1_p'                            as         enum_group     ,
  33                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'softplus'                       as         enum_key       ,
  'sm_sc.fv_softplus'              as         enum_value     ,
  '1_p'                            as         enum_group     ,
  34                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'softmax_mx'                     as         enum_key       ,
  'sm_sc.fv_standlize_mx_softmax'  as         enum_value     ,
  '1_p'                            as         enum_group     ,
  35                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'softmax_x'                      as         enum_key       ,
  'sm_sc.fv_standlize_x_softmax'   as         enum_value     ,
  '1_p'                            as         enum_group     ,
  36                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'softmax_y'                      as         enum_key       ,
  'sm_sc.fv_standlize_y_softmax'   as         enum_value     ,
  '1_p'                            as         enum_group     ,
  37                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'zscore_mx'                      as         enum_key       ,
  'sm_sc.fv_standlize_mx_zscore'   as         enum_value     ,
  '1_p'                            as         enum_group     ,
  38                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'zscore_x'                       as         enum_key       ,
  'sm_sc.fv_standlize_x_zscore'    as         enum_value     ,
  '1_p'                            as         enum_group     ,
  39                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'zscore_y'                       as         enum_key       ,
  'sm_sc.fv_standlize_y_zscore'    as         enum_value     ,
  '1_p'                            as         enum_group     ,
  40                               as         enum_order
union all
-- 分裂，规约以 slice_ 为前缀
select 
  'node_fn_type'                   as         enum_name      ,
  'rand_pick_x'                    as         enum_key       ,
  'sm_sc.ft_rand_slice_x_pick'     as         enum_value     ,
  '1_p'                            as         enum_group     ,
  41                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'rand_pick_y'                    as         enum_key       ,
  'sm_sc.ft_rand_slice_y'          as         enum_value     ,
  '1_p'                            as         enum_group     ,
  42                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'pool_max'                       as         enum_key       ,
  'sm_sc.fv_pool_max_2d_grp_x'     as         enum_value     ,
  '1_p'                            as         enum_group     ,
  43                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'pool_avg'                       as         enum_key       ,
  'sm_sc.fv_pool_avg_2d_grp_x'     as         enum_value     ,
  '1_p'                            as         enum_group     ,
  44                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'new'                            as         enum_key       ,
  'sm_sc.fv_new'                   as         enum_value     ,
  '1_p'                            as         enum_group     ,
  45                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'add'                           as         enum_key       ,
  'sm_sc.fv_opr_add'              as         enum_value     ,
  '2_p'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'mul'                           as         enum_key       ,
  'sm_sc.fv_opr_mul'              as         enum_value     ,
  '2_p'                           as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'sub'                           as         enum_key       ,
  'sm_sc.fv_opr_sub'              as         enum_value     ,
  '2_p'                           as         enum_group     ,
  3                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'div'                           as         enum_key       ,
  'sm_sc.fv_opr_div'              as         enum_value     ,
  '2_p'                           as         enum_group     ,
  5                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'pow'                           as         enum_key       ,
  'sm_sc.fv_opr_pow'              as         enum_value     ,
  '2_p'                           as         enum_group     ,
  7                               as         enum_order
union all
select 
  'node_fn_type'                  as         enum_name      ,
  'log'                           as         enum_key       ,
  'sm_sc.fv_opr_log'              as         enum_value     ,
  '2_p'                           as         enum_group     ,
  9                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'prod_mx'                        as         enum_key       ,
  'sm_sc.fv_opr_prod_mx_py'        as         enum_value     ,
  '2_p'                            as         enum_group     ,
  11                               as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'conv_2d'                        as         enum_key       ,
  'sm_sc.fv_conv_2d_grp_x'         as         enum_value     ,
  '2_p'                            as         enum_group     ,
  12                               as         enum_order
union all

-- 聚合，规约以 agg_ 为前缀
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_sum'                        as         enum_key       ,
  'sm_sc.fa_mx_sum'                as         enum_value     ,
  'n_p'                            as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_prod'                       as         enum_key       ,
  'sm_sc.fa_mx_prod'               as         enum_value     ,
  'n_p'                            as         enum_group     ,
  2                                as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_avg'                        as         enum_key       ,
  'sm_sc.fa_mx_avg'                as         enum_value     ,
  'n_p'                            as         enum_group     ,
  3                                as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_max'                        as         enum_key       ,
  'sm_sc.fa_mx_max'                as         enum_value     ,
  'n_p'                            as         enum_group     ,
  4                                as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_min'                        as         enum_key       ,
  'sm_sc.fa_mx_min'                as         enum_value     ,
  'n_p'                            as         enum_group     ,
  5                                as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_concat_x'                   as         enum_key       ,
  'sm_sc.fa_mx_concat_x'           as         enum_value     ,
  'n_p'                            as         enum_group     ,
  6                                as         enum_order
union all
select 
  'node_fn_type'                   as         enum_name      ,
  'agg_concat_y'                   as         enum_key       ,
  'sm_sc.fa_mx_concat_y'           as         enum_value     ,
  'n_p'                            as         enum_group     ,
  7                                as         enum_order
union all

-- 以下是运算求导类型 - 基础运算
select
  'node_fn_type_delta'            as         enum_name      ,
  'add'                           as         enum_key       ,
  'sm_sc.fv_opr_d_add'            as         enum_value     ,
  'add'                           as         enum_group     ,
  0                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'mul'                           as         enum_key       ,
  'sm_sc.fv_opr_d_mul'            as         enum_value     ,
  'mul'                           as         enum_group     ,
  0                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'sub_1'                         as         enum_key       ,
  'sm_sc.fv_opr_d_sub_1'          as         enum_value     ,
  'sub'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'sub_2'                         as         enum_key       ,
  'sm_sc.fv_opr_d_sub_2'          as         enum_value     ,
  'sub'                           as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'div_1'                         as         enum_key       ,
  'sm_sc.fv_opr_d_div_1'          as         enum_value     ,
  'div'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'div_2'                         as         enum_key       ,
  'sm_sc.fv_opr_d_div_2'          as         enum_value     ,
  'div'                           as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'pow_1'                         as         enum_key       ,
  'sm_sc.fv_opr_d_pow_1'          as         enum_value     ,
  'pow'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'pow_2'                         as         enum_key       ,
  'sm_sc.fv_opr_d_pow_2'          as         enum_value     ,
  'pow'                           as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'exp'                           as         enum_key       ,
  'sm_sc.fv_opr_d_exp'            as         enum_value     ,
  'exp'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'log_1'                         as         enum_key       ,
  'sm_sc.fv_opr_d_log_1'          as         enum_value     ,
  'log'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'log_2'                         as         enum_key       ,
  'sm_sc.fv_opr_d_log_2'          as         enum_value     ,
  'log'                           as         enum_group     ,
  2                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'ln'                            as         enum_key       ,
  'sm_sc.fv_opr_d_ln'             as         enum_value     ,
  'ln'                            as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'sin'                           as         enum_key       ,
  'sm_sc.fv_d_sin'                as         enum_value     ,
  'sin'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'cos'                           as         enum_key       ,
  'sm_sc.fv_d_cos'                as         enum_value     ,
  'cos'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'tan'                           as         enum_key       ,
  'sm_sc.fv_d_tan'                as         enum_value     ,
  'tan'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'cot'                           as         enum_key       ,
  'sm_sc.fv_d_cot'                as         enum_value     ,
  'cot'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'sec'                           as         enum_key       ,
  'sm_sc.fv_d_sec'                as         enum_value     ,
  'sec'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'csc'                           as         enum_key       ,
  'sm_sc.fv_d_csc'                as         enum_value     ,
  'csc'                           as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'asin'                          as         enum_key       ,
  'sm_sc.fv_d_asin'               as         enum_value     ,
  'asin'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'acos'                          as         enum_key       ,
  'sm_sc.fv_d_acos'               as         enum_value     ,
  'acos'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'atan'                          as         enum_key       ,
  'sm_sc.fv_d_atan'               as         enum_value     ,
  'atan'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'acot'                          as         enum_key       ,
  'sm_sc.fv_d_acot'               as         enum_value     ,
  'acot'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'asec'                          as         enum_key       ,
  'sm_sc.fv_d_asec'               as         enum_value     ,
  'asec'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'acsc'                          as         enum_key       ,
  'sm_sc.fv_d_acsc'               as         enum_value     ,
  'acsc'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'sinh'                          as         enum_key       ,
  'sm_sc.fv_d_sinh'               as         enum_value     ,
  'sinh'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'cosh'                          as         enum_key       ,
  'sm_sc.fv_d_cosh'               as         enum_value     ,
  'cosh'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'tanh'                          as         enum_key       ,
  'sm_sc.fv_d_tanh'               as         enum_value     ,
  'tanh'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'coth'                          as         enum_key       ,
  'sm_sc.fv_d_coth'               as         enum_value     ,
  'coth'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'sech'                          as         enum_key       ,
  'sm_sc.fv_d_sech'               as         enum_value     ,
  'sech'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'csch'                          as         enum_key       ,
  'sm_sc.fv_d_csch'               as         enum_value     ,
  'csch'                          as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'asinh'                         as         enum_key       ,
  'sm_sc.fv_d_asinh'              as         enum_value     ,
  'asinh'                         as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'acosh'                         as         enum_key       ,
  'sm_sc.fv_d_acosh'              as         enum_value     ,
  'acosh'                         as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'atanh'                         as         enum_key       ,
  'sm_sc.fv_d_atanh'              as         enum_value     ,
  'atanh'                         as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'acoth'                         as         enum_key       ,
  'sm_sc.fv_d_acoth'              as         enum_value     ,
  'acoth'                         as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'asech'                         as         enum_key       ,
  'sm_sc.fv_d_asech'              as         enum_value     ,
  'asech'                         as         enum_group     ,
  1                               as         enum_order
union all
select 
  'node_fn_type_delta'            as         enum_name      ,
  'acsch'                         as         enum_key       ,
  'sm_sc.fv_d_acsch'              as         enum_value     ,
  'acsch'                         as         enum_group     ,
  1                               as         enum_order

-- 以下是运算求导类型 - 定制运算
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'prod_mx_1'                      as         enum_key       ,
  'sm_sc.fv_opr_d_prod_mx'         as         enum_value     ,
  'prod_mx'                        as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'prod_mx_2'                      as         enum_key       ,
  'sm_sc.fv_opr_d_prod_mx'         as         enum_value     ,
  'prod_mx'                        as         enum_group     ,
  2                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'conv_2d_1'                      as         enum_key       ,
  'sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1'       as         enum_value     ,
  'conv_2d'                        as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'conv_2d_2'                      as         enum_key       ,
  'sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_2'       as         enum_value     ,
  'conv_2d'                        as         enum_group     ,
  2                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'pool_max'                       as         enum_key       ,
  'sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt'           as         enum_value     ,
  'pool_max'                       as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'pool_avg'                       as         enum_key       ,
  'sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt'           as         enum_value     ,
  'pool_avg'                       as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'sigmoid'                        as         enum_key       ,
  'sm_sc.fv_d_sigmoid'             as         enum_value     ,
  'sigmoid'                        as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'relu'                           as         enum_key       ,
  'sm_sc.fv_d_relu'                as         enum_value     ,
  'relu'                           as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'leaky_relu'                     as         enum_key       ,
  'sm_sc.fv_d_leaky_relu_asso'        as         enum_value     ,
  'leaky_relu'                     as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'elu'                            as         enum_key       ,
  'sm_sc.fv_d_elu_asso'               as         enum_value     ,
  'elu'                            as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'selu'                           as         enum_key       ,
  'sm_sc.fv_d_selu'                as         enum_value     ,
  'selu'                           as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'gelu'                           as         enum_key       ,
  'sm_sc.fv_d_gelu'                as         enum_value     ,
  'gelu'                           as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'swish'                          as         enum_key       ,
  'sm_sc.fv_d_swish'               as         enum_value     ,
  'swish'                          as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'softplus'                       as         enum_key       ,
  'sm_sc.fv_d_softplus'            as         enum_value     ,
  'softplus'                       as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'softmax_mx'                     as         enum_key       ,
  'sm_sc.fv_d_standlize_mx_softmax_dloss_dindepdt'          as         enum_value     ,
  'softmax_mx'                     as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'softmax_x'                      as         enum_key       ,
  'sm_sc.fv_d_standlize_x_softmax_dloss_dindepdt'          as         enum_value     ,
  'softmax_x'                      as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'softmax_y'                      as         enum_key       ,
  'sm_sc.fv_d_standlize_y_softmax_dloss_dindepdt'          as         enum_value     ,
  'softmax_y'                      as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'zscore_mx'                      as         enum_key       ,
  'sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt'          as         enum_value     ,
  'zscore_mx'                      as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'zscore_x'                       as         enum_key       ,
  'sm_sc.fv_d_standlize_x_zscore_dloss_dindepdt'          as         enum_value     ,
  'zscore_x'                       as         enum_group     ,
  1                                as         enum_order
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'zscore_y'                       as         enum_key       ,
  'sm_sc.fv_d_standlize_y_zscore_dloss_dindepdt'          as         enum_value     ,
  'zscore_y'                       as         enum_group     ,
  1                                as         enum_order

-- -- -- zscore_x_ex 的求导在 sm_sc.fv_lambda_arr_delta 直接编写，不调用 zscore 求导函数
-- -- -- 区别在于，求导函数自己计算本次抽样样本的平均，而 lambda 直接求导配合了 sm_sc.prc_nn_train 中编写的训练集平均值的迭代更新逻辑
union all
select 
  'node_fn_type_delta'             as         enum_name      ,
  'new'                            as         enum_key       ,
  'sm_sc.fv_d_new'                 as         enum_value     ,
  'new'                            as         enum_group     ,
  1                                as         enum_order
;
