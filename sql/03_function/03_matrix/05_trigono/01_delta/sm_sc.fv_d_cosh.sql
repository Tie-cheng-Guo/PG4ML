-- drop function if exists sm_sc.fv_d_cosh(float[][]);
create or replace function sm_sc.fv_d_cosh
(
  i_indepdt_var float[][]
)
returns float[][]
as
$$
declare 
begin
  return
     sm_sc.fv_sinh(i_indepdt_var)::float[]
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_cosh(array[[1.8, 3.6], [2.4, 1.6]])