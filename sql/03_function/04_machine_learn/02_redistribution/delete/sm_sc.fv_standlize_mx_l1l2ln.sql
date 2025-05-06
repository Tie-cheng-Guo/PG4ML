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
  v_norm_l1l2ln     float   :=   coalesce(nullif(sm_sc.fv_aggr_slice_sum_py((@|`  i_array) ^` i_n) ^ (1.0 :: float/ i_n), 0.0 :: float), 'NaN' :: float);


begin
  if array_ndims(i_array) is null
  then 
    return array[] :: float[];
  elsif array_ndims(i_array) <= 4
  then
    return i_array /` v_norm_l1l2ln ;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_mx_l1l2ln(array[[12.3, 25.1], [2.56, 3.25]], 2.0 :: float)
-- select sm_sc.fv_standlize_mx_l1l2ln(array[[[12.3, 25.1], [2.56, 3.25]]], 2.0 :: float)
-- select sm_sc.fv_standlize_mx_l1l2ln(array[[[[12.3, 25.1], [2.56, 3.25]]]], 2.0 :: float)
-- select sm_sc.fv_standlize_mx_l1l2ln(array[12.3, 25.1, 28.33], 1)
-- select sm_sc.fv_standlize_mx_l1l2ln(array[]::float[])
-- select sm_sc.fv_standlize_mx_l1l2ln(array[[],  []]::float[])