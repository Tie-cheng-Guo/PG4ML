-- drop function if exists sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(float[], int);
create or replace function sm_sc.fv_d_mx_descend_dim_dloss_dindepdt
(
  i_dloss_dindepdt         float[]  ,
  i_descend_time            int
)
returns float[]
as
$$
-- declare
begin
  -- 审计维度数量
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_dindepdt) + i_descend_time > 4
    then 
      raise exception 'unsupport dim > 4.';
    end if;
  end if;
  
  if i_descend_time = 3
  then 
    return array[[[i_dloss_dindepdt]]];
  elsif i_descend_time = 2
  then 
    return array[[i_dloss_dindepdt]];
  elsif i_descend_time = 1
  then 
    return array[i_dloss_dindepdt];
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(array[1, 2]::float[], 1)
-- select sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(array[1, 2]::float[], 2)
-- select sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(array[1, 2]::float[], 3)
-- select sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(array[[1, 2]]::float[], 1)
-- select sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(array[[1, 2]]::float[], 2)
-- select sm_sc.fv_d_mx_descend_dim_dloss_dindepdt(array[[[1, 2]]]::float[], 1)