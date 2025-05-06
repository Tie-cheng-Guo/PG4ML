-- drop function if exists sm_sc.fv_mx_ele_1d_2_2d_py(float[], int);
create or replace function sm_sc.fv_mx_ele_1d_2_2d_py
(
  i_ele_1d                    float[]
, i_cnt_per_grp               int                          -- 对于单行多列，将向下堆砌多行；对于多行单列，将向右堆砌多列
, i_dim_new                   int        default 1         -- 新生维度
, i_if_dim_pin_ele_on_from    boolean    default true      -- 是否在 from 维度保留元素顺序，否则在 new 维度保留元素顺序
)
returns float[]
as
$$
-- declare

begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_ele_1d) not in (1, 2) 
      or cardinality(i_ele_1d) not in (array_length(i_ele_1d, 1), array_length(i_ele_1d, 2))
    then 
      raise exception 'ndims should be 1.';
    elsif i_cnt_per_grp > 1
      and cardinality(i_ele_1d) % i_cnt_per_grp > 0
    then 
      raise exception 'unsupported count of groups. len_ele_1d_y: %; len_ele_1d_x: %; cnt_per_grp: %; i_ele_1d: %;', array_length(i_ele_1d, 1), array_length(i_ele_1d, 2), i_cnt_per_grp, i_ele_1d;
    end if;
  end if;

  if i_ele_1d is null 
  then 
    return null;
  elsif i_dim_new = 1 and i_if_dim_pin_ele_on_from is true
    or i_dim_new = 2 and i_if_dim_pin_ele_on_from is false
  then 
    return 
      sm_sc.fv_opr_reshape_py(i_ele_1d, array[cardinality(i_ele_1d) / i_cnt_per_grp, i_cnt_per_grp])
    ;
  elsif i_dim_new = 1 and i_if_dim_pin_ele_on_from is false
    or i_dim_new = 2 and i_if_dim_pin_ele_on_from is true
  then 
    return 
      |^~| sm_sc.fv_opr_reshape_py(i_ele_1d, array[i_cnt_per_grp, cardinality(i_ele_1d) / i_cnt_per_grp])
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_ele_1d_2_2d_py
--   (
--     array[1, 2, 3, 4, 5, 6, 7, 8, 9]
--     , 3
--   );
-- -- select sm_sc.fv_mx_ele_1d_2_2d_py
-- --   (
-- --     array[array[1, 2, 3, 4, 5, 6, 7, 8, 9]]
-- --     , 3
-- --   );
-- -- select sm_sc.fv_mx_ele_1d_2_2d_py
-- --   (
-- --     array[array[1], array[2], array[3], array[4], array[5], array[6]]
-- --     , 3
-- --   );
-- -- -- -- select sm_sc.fv_mx_ele_1d_2_2d_py
-- -- -- --   (
-- -- -- --     array[array[1], array[2], array[3], array[4], array[5]]
-- -- -- --     , 2
-- -- -- --   );