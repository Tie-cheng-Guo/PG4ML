-- drop function if exists sm_sc.fv_d_nn_none_dloss_dindepdt(anyarray);
create or replace function sm_sc.fv_d_nn_none_dloss_dindepdt
(
  i_dloss_ddepdt    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  return i_dloss_ddepdt;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_nn_none_dloss_dindepdt
--   (
--     array[[1, 2, 3], [4, 5, 6]]
--   )