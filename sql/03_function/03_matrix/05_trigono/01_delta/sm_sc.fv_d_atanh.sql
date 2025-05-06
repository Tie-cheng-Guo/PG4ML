-- drop function if exists sm_sc.fv_d_atanh(float[][]);
create or replace function sm_sc.fv_d_atanh
(
  i_indepdt_var float[][]
)
returns float[][]
as
$$
declare 
begin
  return
     /` (1.0 :: float-` (i_indepdt_var ^` 2.0 :: float))
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_atanh(array[[1.8, 1.6], [1.4, 2.6]])