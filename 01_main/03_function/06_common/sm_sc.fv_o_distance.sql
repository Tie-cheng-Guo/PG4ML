drop function if exists sm_sc.fv_o_distance(float[2][], int);
create or replace function sm_sc.fv_o_distance
(
  i_points_arr               float[2][]     ,
  i_dimension_cnt            int    default null
)
returns float
as
$$
begin
  return
  (
    select
      power(sum(power(i_points_arr[1][a_dimension_no] - i_points_arr[2][a_dimension_no], 2)), 0.5 :: float)
    from generate_series(1, coalesce(i_dimension_cnt, array_length(i_points_arr, 2))) tb_a_dimension_no(a_dimension_no)
  )
  ;
end;
$$
  language plpgsql volatile
  cost 100;
-- select sm_sc.fv_o_distance(array[array[22.2, 77.7], array[55.5, 33.3]], 2)
-- select sm_sc.fv_o_distance(array[array[22.2, 77.7], array[55.5, 33.3]])

-- --------------------------------
drop function if exists sm_sc.fv_o_distance(float[], float[], int);
create or replace function sm_sc.fv_o_distance
(
  i_host_points_arr               float[]     ,
  i_guest_points_arr               float[]     ,
  i_dimension_cnt            int   default null
)
returns float
as
$$
begin
  return
  (
    select
      power(sum(power(i_host_points_arr[a_dimension_no] - i_guest_points_arr[a_dimension_no], 2)), 0.5 :: float)
    from generate_series(1, coalesce(i_dimension_cnt, least(array_length(i_host_points_arr, 1), array_length(i_guest_points_arr, 1)))) tb_a_dimension_no(a_dimension_no)
  )
  ;
end;
$$
  language plpgsql volatile
  cost 100;
-- select sm_sc.fv_o_distance(array[22.2, 77.7], array[55.5, 33.3], 2)
-- select sm_sc.fv_o_distance(array[22.2, 77.7], array[55.5, 33.3])