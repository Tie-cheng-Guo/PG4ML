-- drop function if exists sm_sc.fv_d_cos(float[][]);
create or replace function sm_sc.fv_d_cos
(
  i_indepdt_var float[][]
)
returns float[][]
as
$$
declare 
begin
  return
    -` sm_sc.fv_sin(i_indepdt_var)::float[]
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_cos(array[[1.8, 4.6], [1.4, 3.6]])