-- drop function if exists sm_sc.fv_d_mx_sum(int[]);
create or replace function sm_sc.fv_d_mx_sum
(
  i_depdt_var_len    int[]
)
returns float[][]
as
$$
declare 
begin
  return array_fill(1.0 :: float, i_depdt_var_len);
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_mx_sum(array[2, 3])