-- drop function if exists sm_sc.fv_standlize_mx_l1l2ln(float[], float);
create or replace function sm_sc.fv_standlize_mx_l1l2ln
(
  i_array     float[]   ,
  i_n         float
)
returns float[]
as
$$
declare -- here
  v_norm_l1l2ln     float   :=   coalesce(nullif(sm_sc.fv_aggr_slice_sum((@` i_array) ^` i_n) ^ (1.0 :: float/ i_n), 0.0 :: float), 1e-128 :: float);


begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_ndims(i_array) is null
  then 
    return array[] :: float[];
  elsif array_ndims(i_array) <= 2
  then
    return i_array /` v_norm_l1l2ln ;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_mx_l1l2ln(array[array[12.3, 25.1], array[2.56, 3.25]], 2.0 :: float) ~=` 6
-- select sm_sc.fv_standlize_mx_l1l2ln(array[12.3, 25.1, 28.33], 1) ~=` 6
-- select sm_sc.fv_standlize_mx_l1l2ln(array[]::float[]) ~=` 6
-- select sm_sc.fv_standlize_mx_l1l2ln(array[array[], array []]::float[]) ~=` 6