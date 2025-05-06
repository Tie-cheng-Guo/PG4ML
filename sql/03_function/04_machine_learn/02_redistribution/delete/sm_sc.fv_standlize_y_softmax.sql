-- drop function if exists sm_sc.fv_standlize_y_softmax(float[]);
create or replace function sm_sc.fv_standlize_y_softmax
(
  i_array     float[]
)
returns float[]
as
$$
-- declare 
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) = 2
  then
    i_array := ^` i_array;
    return i_array /` sm_sc.fv_ele_replace(sm_sc.fv_aggr_slice_sum_py(i_array, array[array_length(i_array, 1), 1]), array[0.0 :: float], 'NaN' :: float);
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_y_softmax(array[array[12.3, 25.1], array[2.56, 56.4], array[3.25, 56.4]]) ~=` 6
-- -- select sm_sc.fv_standlize_y_softmax(array[12.3, 25.1, 28.33]) ~=` 6
-- select sm_sc.fv_standlize_y_softmax(array[]::float[]) ~=` 6
-- select sm_sc.fv_standlize_y_softmax(array[array[], array []]::float[]) ~=` 6

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_standlize_y_softmax(float[], int);
create or replace function sm_sc.fv_standlize_y_softmax
(
  i_array          float[],
  i_cnt_per_grp    int
)
returns float[]
as
$$
-- declare 
begin
  if array_length(i_array, 1) % i_cnt_per_grp <> 0 
    or i_cnt_per_grp <= 0
  then 
    raise exception 'imperfect length_1 of i_array of this cnt_per_grp';
  end if;
  
  return 
  (
    select 
      sm_sc.fa_mx_concat_y(sm_sc.fv_standlize_y_softmax(i_array[a_cur : a_cur + i_cnt_per_grp - 1][ : ]) order by a_cur)
    from generate_series(1, array_length(i_array, 1), i_cnt_per_grp) tb_a_cur(a_cur)
  )
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_y_softmax(array[[12.3, 25.1, 2.56, 3.33], [4.25, 2.64, 5.64, -2.65], [1.23, 2.51, 2.26, -3.33], [3.5, 6.4, 6.4, -1.65], [-2.3, -12.1, 7.56, 6.33], [3.2, -6.4, 7.4, 2.65]], 3) :: decimal[] ~=` 6