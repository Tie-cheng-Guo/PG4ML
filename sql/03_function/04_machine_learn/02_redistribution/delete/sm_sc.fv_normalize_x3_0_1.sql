-- drop function if exists sm_sc.fv_normalize_x3_0_1(float[]);
create or replace function sm_sc.fv_normalize_x3_0_1
(
  i_array     float[]
)
returns float[]
as
$$
declare -- here
  v_min_x3      float[] ;
  v_x3_lens     int[]   ;
  v_ptp_x3      float[] ;
begin
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) between 3 and 4
  then
    v_x3_lens  :=   
      (
        select 
          array_agg
          (
            case when a_cur_ndim = 3 then 1 else array_length(i_array, a_cur_ndim) end
              order by a_cur_ndim
          ) 
        from generate_series(1, array_ndims(i_array)) tb_a_cur_ndim(a_cur_ndim)
      );
    v_min_x3   := sm_sc.fv_aggr_slice_min(i_array, v_x3_lens);
    v_ptp_x3   := sm_sc.fv_aggr_slice_max(i_array, v_x3_lens) -` v_min_x3;
      -- sm_sc.fv_ele_replace(sm_sc.fv_aggr_slice_max(i_array, v_x3_lens) -` v_min_x3, array[0.0 :: float], 'NaN' :: float);      
    return (i_array -` sm_sc.fv_new(v_min_x3, v_x3_lens)) /` sm_sc.fv_new(v_ptp_x3, v_x3_lens);
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- select sm_sc.fv_normalize_x3_0_1(sm_sc.fv_new_rand(array[4])) :: decimal[] ~=` 3
-- -- select sm_sc.fv_normalize_x3_0_1(sm_sc.fv_new_rand(array[2, 3])) :: decimal[] ~=` 3
-- select sm_sc.fv_normalize_x3_0_1(sm_sc.fv_new_rand(array[2, 3, 5])) :: decimal[] ~=` 3
-- select sm_sc.fv_normalize_x3_0_1(sm_sc.fv_new_rand(array[2, 3, 5, 6])) :: decimal[] ~=` 3
-- select sm_sc.fv_normalize_x3_0_1(array[]::float[])
-- select sm_sc.fv_normalize_x3_0_1(array[[],  []]::float[])