-- drop function if exists sm_sc.fv_nn_weight_len(varchar(64), int, float[], int[]);
create or replace function sm_sc.fv_nn_weight_len
(
  i_node_fn_type             varchar(64)      ,
  i_path_ord_no              int              ,
  i_node_fn_asso_value       float[]          ,
  i_node_depdt_val_len       int[]       default null
)
returns int[]
as
$$
-- declare 
begin
  return 
    case 
      when i_node_fn_type = '05_conv_2d_grp_x' and i_path_ord_no = 2
        then 
          -- 卷积核扁平化
          case 
            when i_node_fn_asso_value[12] :: int :: boolean is true
              -- 配套偏移量
              then array[1, i_node_fn_asso_value[2] :: int * i_node_fn_asso_value[3] :: int + 1]
            else array[1, i_node_fn_asso_value[2] :: int * i_node_fn_asso_value[3] :: int]
          end    
      when i_node_fn_type = '01_prod_mx' and i_path_ord_no = 2
        -- then i_node_fn_asso_value[4] || (i_node_fn_asso_value[5] || i_node_fn_asso_value[2 : 3])    -- 参看字典表 enum_name = 'node_fn_asso_value' and enum_group = '01_prod_mx'
        then i_node_depdt_val_len[ : array_length(i_node_depdt_val_len, 1) - 2] || i_node_fn_asso_value[2 : 3]
      when i_node_fn_type = '05_conv_2d' and i_path_ord_no = 2
        -- then i_node_fn_asso_value[11] || (i_node_fn_asso_value[12] || i_node_fn_asso_value[2 : 3])    -- 参看字典表 enum_name = 'node_fn_asso_value' and enum_group = '05_conv_2d'
        then i_node_depdt_val_len[ : array_length(i_node_depdt_val_len, 1) - 2] || i_node_fn_asso_value[2 : 3]
      when i_node_fn_type = '05_conv_2d' and i_path_ord_no = 3
        then i_node_depdt_val_len[ : array_length(i_node_depdt_val_len, 1) - 2] || array[1, 1]
      -- else array[[1.0]]
    end
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;


-- select 
--   sm_sc.fv_nn_weight_len
--   (
--     '01_prod_mx'
--   , 2
--   , array[2.0, 3.0, 5.0]
--   , array[8, 10, 2, 5]
--   )