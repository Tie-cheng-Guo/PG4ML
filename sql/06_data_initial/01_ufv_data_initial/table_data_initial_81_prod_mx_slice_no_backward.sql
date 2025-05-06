-- -- node_fn_asso_value  -- 算子超参数
-- insert into sm_sc.tb_dic_enum
-- (
--   enum_name      ,
--   enum_key       ,
--   enum_value     ,
--   enum_group     ,
--   enum_order     ,
--   enum_range
-- )
-- with cte_node_fn_asso_value(a_param_name, a_cn_desc, enum_group, enum_order, enum_range) as
-- (
--      select trim('p1_len_col__1d  '), trim('入参一高度规格，也即列的高度     '), trim('81_prod_mx_slice_no_backward       '),  1, numrange(1.0, 1.0, '[]')
-- )
-- select 
--   'node_fn_asso_value' as enum_name, 
--   enum_group || '_asso_' || enum_order as enum_key, 
--   a_param_name || a_cn_desc as enum_value, 
--   enum_group,
--   enum_order,
--   enum_range
-- from cte_node_fn_asso_value
-- on conflict(enum_name, enum_key)
-- do update
-- set 
--   enum_value = excluded.enum_value
-- , enum_group = excluded.enum_group
-- , enum_order = excluded.enum_order
-- ;

-- ------------------------------------------------------------------------------------------

-- node_fn_type   -- 算子
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
  select trim('81_prod_mx_slice_no_backward      '),         trim('sm_sc.ufv_prod_mx_slice          '),            '2_p'
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

-- ------------------------------------------------------------------------------------------

-- -- node_fn_type_delta  -- 算子求导函数
-- insert into sm_sc.tb_dic_enum
-- (
--   enum_name      ,
--   enum_key       ,
--   enum_value     ,
--   enum_group     ,
--   enum_order
-- )
-- with cte_node_fn_type_delta(enum_key, enum_value, enum_group) as
-- (
--      select trim('dldi_query_from_col      '), trim('sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1      '),trim('81_prod_mx_slice_no_backward      ')
-- )
-- select 
--   'node_fn_type_delta' as enum_name, 
--   enum_key, 
--   enum_value, 
--   enum_group,
--   row_number() over() 
--     + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta'), 0) 
--   as enum_order
-- from cte_node_fn_type_delta
-- on conflict(enum_name, enum_key)
-- do update
-- set 
--   enum_value = excluded.enum_value
-- , enum_group = excluded.enum_group
-- , enum_order = excluded.enum_order
-- ;

-- ------------------------------------------------------------------------------------------

-- -- node_fn_type_delta_method   -- 算子求导方式
-- insert into sm_sc.tb_dic_enum
-- (
--   enum_name      ,
--   enum_key       ,
--   enum_value     ,
--   enum_group     ,
--   enum_order
-- )
-- with cte_node_fn_type(enum_key, enum_value, enum_group) as 
-- -- enum_group: 
-- --   0. 前向传播后，求 ddepdt/dindepdt
-- --   1. 反向传播。直接求 dloss/dindepdt, 而不需显式求取 ddepdt/dindepdt
-- -- enum_value:
-- --   第一位控制：第一目求导是否需要自变量
-- --   第二位控制：第二目求导是否需要自变量
-- --   第三位控制：第一目求导是否需要另一自变量
-- --   第四位控制：第二目求导是否需要另一自变量
-- --   第五位控制：第一目求导是否需要因变量
-- --   第六位控制：第二目求导是否需要因变量
-- --   第七位控制：第一目求导是否用到自变量维长规格
-- --   第八位控制：第二目求导是否用到自变量维长规格
-- (
--   select trim('81_prod_mx_slice_no_backward      '),         trim('00100010'),            '1'
-- )
-- select 
--   'node_fn_type_delta_method' as enum_name, 
--   enum_key, 
--   enum_value, 
--   enum_group,
--   row_number() over() 
--     + coalesce((select max(enum_order) from sm_sc.tb_dic_enum where enum_name = 'node_fn_type_delta_method'), 0) 
--   as enum_order
-- from cte_node_fn_type
-- on conflict(enum_name, enum_key)
-- do update
-- set 
--   enum_value = excluded.enum_value
-- , enum_group = excluded.enum_group
-- , enum_order = excluded.enum_order
-- ;