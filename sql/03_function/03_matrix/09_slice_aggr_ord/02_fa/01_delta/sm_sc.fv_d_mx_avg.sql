-- drop function if exists sm_sc.fv_d_mx_avg(int, int[]);
create or replace function sm_sc.fv_d_mx_avg
(
  i_mx_cnt             int,
  i_depdt_var_len    int[]
)
returns float[][]
as
$$
declare 
begin
  return array_fill(1.0 :: float/ i_mx_cnt, i_depdt_var_len);
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_mx_avg(3, array[2, 3])