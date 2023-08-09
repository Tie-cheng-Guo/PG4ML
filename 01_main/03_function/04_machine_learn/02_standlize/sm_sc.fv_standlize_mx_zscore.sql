-- drop function if exists sm_sc.fv_standlize_mx_zscore(float[]);
create or replace function sm_sc.fv_standlize_mx_zscore
(
  i_array     float[]
)
returns float[]
as
$$
declare -- here
  v_avg             float   :=   sm_sc.fv_aggr_slice_avg(i_array) ;
  v_stddev_samp     float   :=   coalesce(nullif(sm_sc.fv_aggr_slice_stddev_samp(i_array), 0.0 :: float), 1e-128 :: float) ;     -- -- -- 全局 eps = 1e-128 :: float
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_ndims(i_array) is null
  then 
    return array[] :: float[];
  elsif array_ndims(i_array) <= 2
  then
    return (i_array -` v_avg) /` v_stddev_samp;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_mx_zscore(array[array[12.3, 25.1], array[2.56, 3.25]]) ~=` 6
-- select sm_sc.fv_standlize_mx_zscore(array[12.3, 25.1, 28.33]) ~=` 6
-- select sm_sc.fv_standlize_mx_zscore(array[]::float[]) ~=` 6
-- select sm_sc.fv_standlize_mx_zscore(array[array[], array []]::float[]) ~=` 6