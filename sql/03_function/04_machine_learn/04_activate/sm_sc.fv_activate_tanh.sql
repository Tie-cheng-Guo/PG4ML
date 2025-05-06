-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_activate_tanh(float[]);
create or replace function sm_sc.fv_activate_tanh
(
  i_array     float[]
)
returns float[]
as
$$
-- declare 

begin
  -- -- -- fn(null :: double precision[][], double precision) = null :: double precision[][]
  -- -- if array_ndims(i_array) is null
  -- -- then 
  -- --   return array[] :: float[];
  -- -- end if;
  -- -- 
  -- -- if version() > 'PostgreSQL 12'
  -- -- then
  -- --   return sm_sc.fv_tanh(i_array);
  -- -- else
  -- --   -- tanh([][]) pg11及以下版本本支持 tanh 函数，需要自然指数运算
  -- --   i_array := ^` (2.0  :: float *` i_array);
  -- --   return (i_array -` 1.0 :: float) /` (i_array +` 1.0 :: float);
  -- -- end if;
  
  return sm_sc.fv_tanh(i_array);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_activate_tanh
--   (
--     array[[pi(), -pi()], [pi() / 2, pi() / 4]]::float[]
--   )
-- ;
-- select sm_sc.fv_activate_tanh
--   (
--     array[[[pi(), -pi()], [pi() / 2, pi() / 4]]]::float[]
--   )
-- ;
-- select sm_sc.fv_activate_tanh
--   (
--     array[[[[pi(), -pi()], [pi() / 2, pi() / 4]]]]::float[]
--   )
-- ;
-- select sm_sc.fv_activate_tanh
--   (
--     array[pi(), -pi(), pi() / 2, pi() / 4]::float[]
--   )
-- ;