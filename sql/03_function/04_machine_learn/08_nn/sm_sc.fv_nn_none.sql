-- drop function if exists sm_sc.fv_nn_none(anyarray);
create or replace function sm_sc.fv_nn_none
(
  i_indepdt    anyarray
)
returns anyarray
as
$$
-- declare 
begin
  return i_indepdt;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select sm_sc.fv_nn_none(array[1.0])