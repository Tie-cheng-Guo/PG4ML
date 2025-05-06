-- drop function if exists sm_sc.fv_mx_ascend_dim(anyarray, int);
create or replace function sm_sc.fv_mx_ascend_dim
(
  i_array        anyarray  ,
  i_ascend_time  int       default   1
)
returns anyarray
as
$$
-- declare
begin
  -- 审计维度数量
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array) + i_ascend_time > 4
    then 
      raise exception 'unsupport dim > 4.';
    end if;
  end if;
  
  if i_ascend_time = 1
  then 
    return array[i_array];
  elsif i_ascend_time = 2
  then 
    return array[[i_array]];
  elsif i_ascend_time = 3
  then 
    return array[[[i_array]]];
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_ascend_dim(array[1, 2])
-- select sm_sc.fv_mx_ascend_dim(array[1, 2], 1)
-- select sm_sc.fv_mx_ascend_dim(array[1, 2], 2)
-- select sm_sc.fv_mx_ascend_dim(array[1, 2], 3)
-- select sm_sc.fv_mx_ascend_dim(array[[1, 2]])
-- select sm_sc.fv_mx_ascend_dim(array[[1, 2]], 1)
-- select sm_sc.fv_mx_ascend_dim(array[[1, 2]], 2)
-- -- select sm_sc.fv_mx_ascend_dim(array[[1, 2]], 3)
-- select sm_sc.fv_mx_ascend_dim(array[[[1, 2]]])
-- select sm_sc.fv_mx_ascend_dim(array[[[1, 2]]], 1)
-- --select sm_sc.fv_mx_ascend_dim(array[[[1, 2]]], 2)
-- --select sm_sc.fv_mx_ascend_dim(array[[[1, 2]]], 3)