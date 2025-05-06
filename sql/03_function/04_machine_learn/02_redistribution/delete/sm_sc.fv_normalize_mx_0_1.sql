-- drop function if exists sm_sc.fv_normalize_mx_0_1(float[]);
create or replace function sm_sc.fv_normalize_mx_0_1
(
  i_array     float[]
)
returns float[]
as
$$
declare -- here
  v_max     float   :=   sm_sc.fv_aggr_slice_max(i_array) ;
  v_min     float   :=   sm_sc.fv_aggr_slice_min(i_array) ;
  v_ptp     float   :=   coalesce(nullif(v_max - v_min, 0.0 :: float), 'NaN' :: float);      
begin
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) <= 4
  then
    return (i_array -` v_min) /` v_ptp;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_normalize_mx_0_1(array[[12.3, 25.1], [2.56, 3.25]])
-- select sm_sc.fv_normalize_mx_0_1(array[[[12.3, 25.1], [2.56, 3.25]]])
-- select sm_sc.fv_normalize_mx_0_1(array[[[[12.3, 25.1], [2.56, 3.25]]]])
-- select sm_sc.fv_normalize_mx_0_1(array[12.3, 25.1, 28.33])
-- select sm_sc.fv_normalize_mx_0_1(array[]::float[])
-- select sm_sc.fv_normalize_mx_0_1(array[array[], array []]::float[])