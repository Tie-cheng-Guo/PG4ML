-- drop function if exists sm_sc.fv_d_atan(float[][]);
create or replace function sm_sc.fv_d_atan
(
  i_indepdt_var float[][]
)
returns float[][]
as
$$
declare 
begin
  return
     /` (1.0 :: float+` (i_indepdt_var ^` 2.0 :: float))
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_atan(array[[0.8, 0.6], [0.4, -0.6]])