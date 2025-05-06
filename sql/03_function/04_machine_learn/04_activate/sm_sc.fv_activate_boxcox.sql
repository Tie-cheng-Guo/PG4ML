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
  -- 审计：不支持负值
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if true = any(i_array <=` 0.0 :: float)
    then 
      raise exception 'unsupport negative value in i_array.';
    end if;
  end if;
  
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
--     array[[12.5, 9.3], [5.6, 32.4]]::float[]
--     , 2
--   )
-- ;
-- select sm_sc.fv_activate_boxcox
--   (
--     array[[[12.5, 9.3], [5.6, 32.4]]]::float[]
--     , 2
--   )
-- ;
-- select sm_sc.fv_activate_boxcox
--   (
--     array[[[[12.5, 9.3], [5.6, 32.4]]]]::float[]
--     , 2
--   )
-- ;
-- select sm_sc.fv_activate_boxcox
--   (
--     array[10.3, 1.9, 88.6, 1001.6]::float[]
--     , 0.0
--   )
-- ;