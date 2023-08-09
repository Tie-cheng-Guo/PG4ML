-- drop function if exists sm_sc.fv_activate_relu(float[]);
create or replace function sm_sc.fv_activate_relu  
(
  i_array     float[]
)
returns float[]
as
$$
-- declare 

begin
  return i_array @>` (0.0 :: float);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_activate_relu(array[array[12.3, -25.1], array[-2.56, 3.25]]) ~=` 6
-- select sm_sc.fv_activate_relu(array[12.3, 25.1, -28.33]) ~=` 6
-- select sm_sc.fv_activate_relu(array[]::float[]) ~=` 6
-- select sm_sc.fv_activate_relu(array[array[], array []]::float[]) ~=` 6