-- drop function if exists sm_sc.fv_standlize_x4_l1l2ln(float[], float);
create or replace function sm_sc.fv_standlize_x4_l1l2ln
(
  i_array     float[]   ,
  i_n         float
)
returns float[]
as
$$
declare -- here
  v_x3_lens     int[]   ;
begin
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) = 4
  then
    v_x3_lens  :=   
      (
        select 
          array_agg
          (
            case when a_cur_ndim = 4 then 1 else array_length(i_array, a_cur_ndim) end
              order by a_cur_ndim
          ) 
        from generate_series(1, array_ndims(i_array)) tb_a_cur_ndim(a_cur_ndim)
      );
    return i_array /` sm_sc.fv_new(sm_sc.fv_aggr_slice_sum_py((@|`  i_array) ^` i_n, v_x3_lens) ^` (1.0 :: float/ i_n), v_x3_lens);
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- select sm_sc.fv_standlize_x4_l1l2ln(sm_sc.fv_new_rand(array[4]), 3) :: decimal[] ~=` 3
-- -- select sm_sc.fv_standlize_x4_l1l2ln(sm_sc.fv_new_rand(array[2, 3]), 3) :: decimal[] ~=` 3
-- -- select sm_sc.fv_standlize_x4_l1l2ln(sm_sc.fv_new_rand(array[2, 3, 5]), 3) :: decimal[] ~=` 3
-- select sm_sc.fv_standlize_x4_l1l2ln(sm_sc.fv_new_rand(array[2, 3, 5, 6]), 3) :: decimal[] ~=` 3
-- select sm_sc.fv_standlize_x4_l1l2ln(array[]::float[], 3)
-- select sm_sc.fv_standlize_x4_l1l2ln(array[[],  []]::float[], 3)