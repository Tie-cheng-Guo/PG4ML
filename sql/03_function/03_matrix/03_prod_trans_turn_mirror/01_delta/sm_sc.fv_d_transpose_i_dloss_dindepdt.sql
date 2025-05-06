-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_transpose_i_dloss_dindepdt(anyarray);
create or replace function sm_sc.fv_d_transpose_i_dloss_dindepdt
(
  i_dloss_ddepdt     anyarray
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
    
  if array_ndims(i_dloss_ddepdt) is null
  then 
    return i_dloss_ddepdt;
  elsif array_ndims(i_dloss_ddepdt) between 2 and 6
  then
    return 	
      sm_sc.fv_opr_transpose_i(i_dloss_ddepdt)
    ;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_dloss_ddepdt);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_transpose_i_dloss_dindepdt
--   (
--     array[array[1, 2], array[3, 4]]
--   );
-- select sm_sc.fv_d_transpose_i_dloss_dindepdt
--   (
--     array[array[1, 2], array[3, 4], array[5, 6]]
--   );