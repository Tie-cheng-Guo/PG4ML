-- drop function if exists sm_sc.fv_activate_sigmoid(float[]);
create or replace function sm_sc.fv_activate_sigmoid
(
  i_array     float[]
)
returns float[]
as
$$
-- declare 
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_ndims(i_array) is null
  then 
    return array[] :: float[];
  else
    return 1.0 :: float/` (1.0 :: float+` (^` ( -` i_array)));
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_activate_sigmoid(array[array[12.3, 25.1], array[2.56, 3.25]]) ~=` 6
-- select sm_sc.fv_activate_sigmoid(array[12.3, 25.1, 28.33]) ~=` 6
-- select sm_sc.fv_activate_sigmoid(array[]::float[]) ~=` 6
-- select sm_sc.fv_activate_sigmoid(array[array[], array []]::float[]) ~=` 6