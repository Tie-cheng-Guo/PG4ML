-- drop function if exists sm_sc.fv_normalize_x_0_1(float[]);
create or replace function sm_sc.fv_normalize_x_0_1
(
  i_array     float[]
)
returns float[]
as
$$
declare -- here
  -- v_max_x   float[] :=   sm_sc.fv_aggr_x_max(i_array) ;
  v_min_x   float[] :=   sm_sc.fv_aggr_x_min(i_array) ;
  -- v_delta_x float[] :=   sm_sc.fv_ele_replace(v_max_x -` v_min_x, array[0.0 :: float], 1e-128 :: float);      -- -- -- 全局 eps = 1e-128 :: float
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) = 2
  then
    return (i_array -` v_min_x) /` sm_sc.fv_ele_replace(sm_sc.fv_aggr_x_max(i_array) -` v_min_x, array[0.0 :: float], 1e-128 :: float);
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_normalize_x_0_1(array[array[12.3, 25.1, 17.8], array[2.56, 3.25, 56.4]]) ~=` 6
-- -- select sm_sc.fv_normalize_x_0_1(array[12.3, 25.1, 28.33]) ~=` 6
-- select sm_sc.fv_normalize_x_0_1(array[]::float[]) ~=` 6
-- select sm_sc.fv_normalize_x_0_1(array[array[], array []]::float[]) ~=` 6