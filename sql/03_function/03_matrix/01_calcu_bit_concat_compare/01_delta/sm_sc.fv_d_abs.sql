-- drop function if exists sm_sc.fv_d_abs(float[]);
create or replace function sm_sc.fv_d_abs
(
  i_indepdt_var float[]
)
returns float[]
as
$$
declare 
begin
  return
    (<>` i_indepdt_var) :: float[]
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_abs(array[1.8, -4.6])
-- select 
--   sm_sc.fv_d_abs(array[[1.8, -4.6], [1.4, 3.6]])
-- select 
--   sm_sc.fv_d_abs(array[[[1.8, -4.6], [1.4, 3.6]],[[1.8, -4.6], [1.4, 3.6]]])
-- select 
--   sm_sc.fv_d_abs(array[[[[1.8, -4.6], [1.4, 3.6]],[[1.8, -4.6], [1.4, 3.6]]],[[[1.8, -4.6], [1.4, 3.6]],[[1.8, -4.6], [1.4, 3.6]]]])
