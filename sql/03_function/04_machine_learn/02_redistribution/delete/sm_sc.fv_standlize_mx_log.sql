-- drop function if exists sm_sc.fv_standlize_mx_log(float[]);
create or replace function sm_sc.fv_standlize_mx_log
(
  i_array     float[]
)
returns float[]
as
$$
declare -- here
  v_ln_max     float   :=   coalesce(nullif(ln(sm_sc.fv_aggr_slice_max(i_array)), 0.0 :: float), 'NaN' :: float);       

begin
  if array_ndims(i_array) is null
  then 
    return array[] :: float[];
  elsif array_ndims(i_array) <= 4
  then
    return (^!` i_array) /` v_ln_max ;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_mx_log(array[[12.3, 25.1], [2.56, 3.25]])
-- select sm_sc.fv_standlize_mx_log(array[[[12.3, 25.1], [2.56, 3.25]]])
-- select sm_sc.fv_standlize_mx_log(array[[[[12.3, 25.1], [2.56, 3.25]]]])
-- select sm_sc.fv_standlize_mx_log(array[12.3, 25.1, 28.33])
-- select sm_sc.fv_standlize_mx_log(array[]::float[])
-- select sm_sc.fv_standlize_mx_log(array[[],  []]::float[])