-- drop function if exists sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(float[], int);
create or replace function sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt
(
  i_dloss_dindepdt         float[]  ,
  i_ascend_time            int
)
returns float[]
as
$$
-- declare
begin
  -- 审计维度数量
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_dindepdt) > 4
    then 
      raise exception 'unsupport dim > 4.';
    end if;
  end if;
  
  if array_ndims(i_dloss_dindepdt) = 4
  then 
    if i_ascend_time = 1
    then 
      return sm_sc.fv_mx_slice_4d_2_3d(i_dloss_dindepdt, 1, 1);
    elsif i_ascend_time = 2
    then 
      return sm_sc.fv_mx_slice_4d_2_2d(i_dloss_dindepdt, array[1, 2], array[1, 1]);
    elsif i_ascend_time = 3
    then 
      return sm_sc.fv_mx_ele_2d_2_1d(sm_sc.fv_mx_slice_4d_2_2d(i_dloss_dindepdt, array[1, 2], array[1, 1]), 2);
    end if;
  elsif array_ndims(i_dloss_dindepdt) = 3
  then 
    if i_ascend_time = 1
    then 
      return sm_sc.fv_mx_slice_3d_2_2d(i_dloss_dindepdt, 1, 1);
    elsif i_ascend_time = 2
    then 
      return sm_sc.fv_mx_ele_2d_2_1d(sm_sc.fv_mx_slice_3d_2_2d(i_dloss_dindepdt, 1, 1), 2);
    end if;
  elsif array_ndims(i_dloss_dindepdt) = 2  -- and i_ascend_time = 1
  then 
    return sm_sc.fv_mx_ele_2d_2_1d(i_dloss_dindepdt, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(array[[[[1, 2]]]], 1)
-- select sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(array[[[[1, 2]]]], 2)
-- select sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(array[[[[1, 2]]]], 3)
-- select sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(array[[[1, 2]]], 1)
-- select sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(array[[[1, 2]]], 2)
-- select sm_sc.fv_d_mx_ascend_dim_dloss_dindepdt(array[[1, 2]], 1)