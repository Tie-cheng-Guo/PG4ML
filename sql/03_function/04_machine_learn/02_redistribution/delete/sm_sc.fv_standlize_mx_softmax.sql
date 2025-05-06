-- -- 同 sm_sc.fv_d_softmax
-- drop function if exists sm_sc.fv_standlize_mx_softmax(float[]);
create or replace function sm_sc.fv_standlize_mx_softmax
(
  i_array     float[]
)
returns float[]
as
$$
-- declare 
begin
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) <= 4
  then
    i_array := ^` i_array;
    return i_array /` coalesce(nullif(sm_sc.fv_aggr_slice_sum_py(i_array), 0.0 :: float), 'NaN' :: float);
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_standlize_mx_softmax(array[array[12.3, 25.1], array[2.56, 3.25]]) ~=` 6
-- select sm_sc.fv_standlize_mx_softmax(array[12.3, 25.1, 28.33]) ~=` 6
-- select sm_sc.fv_standlize_mx_softmax(array[]::float[]) ~=` 6
-- select sm_sc.fv_standlize_mx_softmax(array[array[], array []]::float[]) ~=` 6

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_standlize_mx_softmax(float[], int[2]);
create or replace function sm_sc.fv_standlize_mx_softmax
(
  i_array          float[],
  i_cnt_per_grp    int[2]
)
returns float[]
as
$$
-- declare 
begin
  if array_length(i_array, 1) % i_cnt_per_grp[1] <> 0 
    or i_cnt_per_grp[1] <= 0
  then 
    raise exception 'imperfect length_1 of i_array of this cnt_per_grp';
  elsif array_length(i_array, 2) % i_cnt_per_grp[2] <> 0 
    or i_cnt_per_grp[2] <= 0
  then 
    raise exception 'imperfect length_2 of i_array of this cnt_per_grp';
  end if;
  
  return 
  (
    with
    cte_slice_x as 
    (
      select 
        a_cur_y,
        sm_sc.fa_mx_concat_x
        (
          sm_sc.fv_standlize_mx_softmax(i_array[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]) 
          order by a_cur_x
        ) as a_slice_x
      from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_array, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
      group by a_cur_y
    )
    select 
      sm_sc.fa_mx_concat_y(a_slice_x order by a_cur_y)
    from cte_slice_x
  )
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_standlize_mx_softmax
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6