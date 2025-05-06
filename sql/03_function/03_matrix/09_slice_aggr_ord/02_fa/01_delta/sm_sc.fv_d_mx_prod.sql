-- drop function if exists sm_sc.fv_d_mx_prod(float[], float[]);
create or replace function sm_sc.fv_d_mx_prod
(
  i_indepdt_var      float[],
  i_depdt_var        float[]
)
returns float[][]
as
$$
declare 
begin
  return i_depdt_var /` i_indepdt_var;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_mx_prod
--   (
--     array[[1.2, -2.3, 3.3], [1.4, -2.3, 3.8]],
--     array[[1.3, -2.3, 3.8], [1.5, 2.3, 3.9]]
--   )