-- drop function if exists sm_sc.fv_d_asin(float[][]);
create or replace function sm_sc.fv_d_asin
(
  i_indepdt_var float[][]
)
returns float[][]
as
$$
declare 
begin
  return
     /` ((1.0 :: float-` (i_indepdt_var ^` 2.0 :: float)) ^` 0.5 :: float)
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_asin(array[[0.8, 0.6], [0.4, -0.6]])