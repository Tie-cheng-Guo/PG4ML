-- drop function if exists sm_sc.fv_mx_ele_2d_2_1d_py(float[], int);
create or replace function sm_sc.fv_mx_ele_2d_2_1d_py
(
  i_ele_2d        float[]  ,
  i_dim_pin_ele   int    default  2    -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 1 或 2，不能为其他值。
)
returns float[]
as
$$
-- declare
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计二维长度
    if array_ndims(i_ele_2d) <> 2
    then 
      raise exception 'no method for such i_ele_2d ndims!';
    end if;
  end if;

  if i_ele_2d is null 
  then 
    return null;
  elsif i_dim_pin_ele = 2
  then
    return sm_sc.fv_opr_reshape_py(i_ele_2d, array[cardinality(i_ele_2d)]);

  else 
    return sm_sc.fv_opr_reshape_py(|^~| i_ele_2d, array[cardinality(i_ele_2d)]);
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_ele_2d_2_1d_py
--   (  
--     array[array[1, 2, 3, 4]]
--   );
-- select sm_sc.fv_mx_ele_2d_2_1d_py
--   (
--     array[array[1], array[2], array[3], array[4]]
--   );
-- select sm_sc.fv_mx_ele_2d_2_1d_py
--   (
--     array[[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]
--     , 1
--   );