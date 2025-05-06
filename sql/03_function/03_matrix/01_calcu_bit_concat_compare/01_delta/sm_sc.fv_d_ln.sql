-- drop function if exists sm_sc.fv_d_ln(float[]);
create or replace function sm_sc.fv_d_ln
(
  i_indepdt_var float[]
)
returns float[]
as
$$
declare 
begin
  return
    /` i_indepdt_var
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_ln(array[1.8, 4.6])
-- select 
--   sm_sc.fv_d_ln(array[[1.8, 4.6], [1.4, 3.6]])
-- select 
--   sm_sc.fv_d_ln(array[[[1.8, 4.6], [1.4, 3.6]],[[1.8, 4.6], [1.4, 3.6]]])
-- select 
--   sm_sc.fv_d_ln(array[[[[1.8, 4.6], [1.4, 3.6]],[[1.8, 4.6], [1.4, 3.6]]],[[[1.8, 4.6], [1.4, 3.6]],[[1.8, 4.6], [1.4, 3.6]]]])