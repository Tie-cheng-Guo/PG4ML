-- drop function if exists sm_sc.fv_d_tan(float[][]);
create or replace function sm_sc.fv_d_tan
(
  i_indepdt_var float[][]
)
returns float[][]
as
$$
declare 
begin
  return
    /` (sm_sc.fv_cos(i_indepdt_var)::float[][] ^` 2.0 :: float)
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_tan(array[[1.8, 4.6], [1.4, 3.6]])