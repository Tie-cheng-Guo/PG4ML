-- drop function if exists sm_sc.fv_d_mx_ele_2d_2_3d_dloss_dindepdt(anyarray, int, int, boolean);
create or replace function sm_sc.fv_d_mx_ele_2d_2_3d_dloss_dindepdt
(
  i_dloss_ddepdt_3d      anyarray
-- , i_cnt_per_grp            int                  -- 新增维度的维度长度(元素个数)。
, i_dim_from               int                  -- 被拆分维度
, i_dim_new                int                  -- 新生维度
, i_dim_pin_ele_on_from    boolean              -- 是否在 from 维度保留元素顺序，否则在 new 维度保留元素顺序
)
returns anyarray
as
$$
-- declare

begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_ddepdt_3d) <> 3
    then 
      raise exception 'ndims should be 3.';
    end if;
  end if;

  return 
    sm_sc.fv_mx_ele_3d_2_2d
    (
      i_dloss_ddepdt_3d
    , array[i_dim_new, case when i_dim_from < i_dim_new then i_dim_from else i_dim_from + 1 end]
    , case 
        when i_dim_pin_ele_on_from 
          then case when i_dim_from < i_dim_new then i_dim_from else i_dim_from + 1 end
        else 
          i_dim_new
      end
    )
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- with 
-- cte_ele_2d_2_3d as 
-- (
--   select 
--     a_arr_2d
--   , a_dim_from
--   , a_dim_new
--   , a_dim_pin_ele_on_from
--   , sm_sc.fv_mx_ele_2d_2_3d
--     (
--       a_arr_2d
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     ) as a_ele_2d_2_3d
--   from 
--     (select sm_sc.fv_new_rand(array[6,10]) as a_arr_2d) tb_a_arr_2d(a_arr_2d)
--   , generate_series(1, 2) tb_a_dim_from(a_dim_from)
--   , generate_series(1, 3) tb_a_dim_new(a_dim_new)
--   , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)
--   -- order by a_dim_from, a_dim_new, a_dim_pin_ele_on_from
-- )
-- select 
--   sm_sc.fv_d_mx_ele_2d_2_3d_dloss_dindepdt
--   (
--     a_ele_2d_2_3d
--   , a_dim_from
--   , a_dim_new
--   , a_dim_pin_ele_on_from
--   ) = a_arr_2d
-- from cte_ele_2d_2_3d