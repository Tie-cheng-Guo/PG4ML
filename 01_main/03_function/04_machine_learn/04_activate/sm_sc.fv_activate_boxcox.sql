-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_activate_boxcox(float[], float);
create or replace function sm_sc.fv_activate_boxcox
(
  i_array     float[],
  i_lambda    float
)
returns float[]
as
$$
-- declare 

begin
  -- fn(null :: double precision[][], double precision) = null :: double precision[][]
  if array_ndims(i_array) is null
  then 
    return array[] :: float[];
  elsif i_lambda = 0.0
  then
    return ^!` i_array;
  else
    return ((i_array ^` i_lambda) -` 1.0 :: float) /` i_lambda;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_activate_boxcox
--   (
--     array[array[12.5, -9.3], array[5.6, 32.4]]::float[]
--     , 2
--   )
-- ;
-- select sm_sc.fv_activate_boxcox
--   (
--     array[10.3, -1.9, 88.6, 1001.6]::float[]
--     , 0.0
--   )
-- ;