-- drop function if exists sm_sc.fv_d_mx_ele_3d_2_2d_dloss_dindepdt(anyarray, int, int[2], int, int[4]);
create or replace function sm_sc.fv_d_mx_ele_3d_2_2d_dloss_dindepdt
(
  i_dloss_ddepdt_2d        anyarray
, i_dims_from_to           int[2]     -- 合并维度的原来两个维度。合并后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
                                      -- 枚举项包括，[1, 2] === [2, 1]; [2, 3] === [3, 2]; [1, 3]; [3, 1];
, i_dim_pin_ele            int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
, i_indepdt_len            int[4]
)
returns anyarray
as
$$
-- declare

begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_ddepdt_2d) <> 2
    then 
      raise exception 'ndims should be 2.';
    end if;
  end if;
  
  return 
    sm_sc.fv_mx_ele_2d_2_3d
    (
      i_dloss_ddepdt_2d
    , i_indepdt_len[case when i_dim_pin_ele = i_dims_from_to[1] then i_dims_from_to[1] else i_dims_from_to[2] end]   -- i_cnt_per_grp        
    , case when i_dims_from_to[1] < i_dims_from_to[2] then i_dims_from_to[2] - 1 else i_dims_from_to[2] end   -- i_dim_from           
    , i_dims_from_to[1]   -- i_dim_new            
    , i_dim_pin_ele = i_dims_from_to[2]   -- i_if_dim_pin_ele_on_from
    )
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- with 
-- cte_ele_3d_2_2d as 
-- (
--   select 
--     a_arr_3d
--   , a_dims_from_to
--   , a_dim_pin_ele
--   , sm_sc.fv_mx_ele_3d_2_2d(a_arr_3d, a_dims_from_to, a_dim_pin_ele) as a_out
--   from 
--     (select sm_sc.fv_new_rand(array[2,3,5]) as a_arr_3d) tb_a_arr_3d(a_arr_3d)
--   , (
--                 select array[1, 2]  
--       union all select array[2, 3] 
--       union all select array[2, 1]  
--       union all select array[3, 2] 
--       union all select array[1, 3] 
--       union all select array[3, 1]
--     ) tb_a_dims_from_to(a_dims_from_to)
--   , generate_series(1, 3) tb_a_dim_pin_ele(a_dim_pin_ele)
--   where a_dim_pin_ele = any(a_dims_from_to)
--   -- order by least(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   --   , a_dims_from_to[1]
--   --   , greatest(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   --   , a_dim_pin_ele
-- )
-- select 
--   array_dims(a_arr_3d) as a_dims_indepdt
-- , array_dims(a_out) a_dims_depdt
-- , a_dims_from_to
-- , a_dim_pin_ele
-- , sm_sc.fv_d_mx_ele_3d_2_2d_dloss_dindepdt
--   (
--     a_out
--   , a_dims_from_to
--   , a_dim_pin_ele
--   , (select array_agg(array_length(a_arr_3d, a_no) order by a_no) from generate_series(1, array_ndims(a_arr_3d)) tb_a_no(a_no))
--   ) = a_arr_3d
-- , array_dims(sm_sc.fv_d_mx_ele_3d_2_2d_dloss_dindepdt
--   (
--     a_out
--   , a_dims_from_to
--   , a_dim_pin_ele
--   , (select array_agg(array_length(a_arr_3d, a_no) order by a_no) from generate_series(1, array_ndims(a_arr_3d)) tb_a_no(a_no))
--   )) as a_dims_dloss_ddepdt
-- from cte_ele_3d_2_2d