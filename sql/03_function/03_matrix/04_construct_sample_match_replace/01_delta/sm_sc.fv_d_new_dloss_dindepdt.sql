-- drop function if exists sm_sc.fv_d_new_dloss_dindepdt(float[], int);
create or replace function sm_sc.fv_d_new_dloss_dindepdt
(
  i_dloss_ddepdt             float[]    ,
  i_dims_times               int[]
)
returns float[]    -- 返回值为 2d
as
$$
declare 
  v_depdt_var_len_y   int;
  v_depdt_var_len_x   int;
  v_depdt_var_len_x3  int;
  v_depdt_var_len_x4  int;
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dims_times) <> 1
    then 
      raise exception 'unsupport ndims of i_dims_times.';
    elsif array_ndims(i_dloss_ddepdt) <> array_length(i_dims_times, 1)
    then 
      raise exception 'unmatch between ndims of i_dloss_ddepdt and length of i_dims_times.';
    elsif array_ndims(i_dloss_ddepdt) not between 1 and 4
    then
      raise exception 'no method for ndims of this i_dloss_ddepdt!';
    elsif 0 < any(select array_agg(array_length(i_dloss_ddepdt, a_ndim) / i_dims_times order by a_ndim)
                  from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a_ndims(a_ndim))
    then 
      raise exception 'i_dims_times is unperfect for len of indepdt_var.';
    end if;
  end if;
  
  if array_ndims(i_dloss_ddepdt) is null
  then 
    return array[] :: i_dloss_ddepdt % type;
  elsif array_length(i_dims_times, 1) = 1
  then
    v_depdt_var_len_y := array_length(i_dloss_ddepdt, 1) / i_dims_times[1];
    return 
    (
      select 
        sm_sc.fa_mx_sum
        (
          i_dloss_ddepdt
          [v_depdt_var_len_y * (a_y_no - 1) + 1 : v_depdt_var_len_y * a_y_no]
        ) 
      from generate_series(1, i_dims_times[1]) tb_a_y(a_y_no)
    );
  elsif array_length(i_dims_times, 1) = 2
  then
    v_depdt_var_len_y := array_length(i_dloss_ddepdt, 1) / i_dims_times[1];
    v_depdt_var_len_x := array_length(i_dloss_ddepdt, 2) / i_dims_times[2];
    return 
    (
      select 
        sm_sc.fa_mx_sum
        (
          i_dloss_ddepdt
          [v_depdt_var_len_y * (a_y_no - 1) + 1 : v_depdt_var_len_y * a_y_no]
          [v_depdt_var_len_x * (a_x_no - 1) + 1 : v_depdt_var_len_x * a_x_no]
        ) 
      from generate_series(1, i_dims_times[1]) tb_a_y(a_y_no)
        , generate_series(1, i_dims_times[2]) tb_a_x(a_x_no)
    );
  elsif array_length(i_dims_times, 1) = 3
  then
    v_depdt_var_len_y  := array_length(i_dloss_ddepdt, 1) / i_dims_times[1];
    v_depdt_var_len_x  := array_length(i_dloss_ddepdt, 2) / i_dims_times[2];
    v_depdt_var_len_x3 := array_length(i_dloss_ddepdt, 3) / i_dims_times[3];
    return 
    (
      select 
        sm_sc.fa_mx_sum
        (
          i_dloss_ddepdt
          [v_depdt_var_len_y * (a_y_no - 1) + 1 : v_depdt_var_len_y * a_y_no]
          [v_depdt_var_len_x * (a_x_no - 1) + 1 : v_depdt_var_len_x * a_x_no]
          [v_depdt_var_len_x3 * (a_x3_no - 1) + 1 : v_depdt_var_len_x3 * a_x3_no]
        ) 
      from generate_series(1, i_dims_times[1]) tb_a_y(a_y_no)
        , generate_series(1, i_dims_times[2]) tb_a_x(a_x_no)
        , generate_series(1, i_dims_times[3]) tb_a_x3(a_x3_no)
    );
  elsif array_length(i_dims_times, 1) = 4
  then
    v_depdt_var_len_y   := array_length(i_dloss_ddepdt, 1) / i_dims_times[1];
    v_depdt_var_len_x   := array_length(i_dloss_ddepdt, 2) / i_dims_times[2];
    v_depdt_var_len_x3  := array_length(i_dloss_ddepdt, 3) / i_dims_times[3];
    v_depdt_var_len_x4  := array_length(i_dloss_ddepdt, 4) / i_dims_times[4];
    return 
    (
      select 
        sm_sc.fa_mx_sum
        (
          i_dloss_ddepdt
          [v_depdt_var_len_y * (a_y_no - 1) + 1 : v_depdt_var_len_y * a_y_no]
          [v_depdt_var_len_x * (a_x_no - 1) + 1 : v_depdt_var_len_x * a_x_no]
          [v_depdt_var_len_x3 * (a_x3_no - 1) + 1 : v_depdt_var_len_x3 * a_x3_no]
          [v_depdt_var_len_x4 * (a_x4_no - 1) + 1 : v_depdt_var_len_x4 * a_x4_no]
        ) 
      from generate_series(1, i_dims_times[1]) tb_a_y(a_y_no)
        , generate_series(1, i_dims_times[2]) tb_a_x(a_x_no)
        , generate_series(1, i_dims_times[3]) tb_a_x3(a_x3_no)
        , generate_series(1, i_dims_times[4]) tb_a_x4(a_x4_no)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_new_dloss_dindepdt
--   (
--     array[[0.5 :: float, -0.2, 0.25, 1.3, -0.9, -0.1], [-0.5 :: float, -0.2, -0.25, 1.3, 0.9, 0.1], [0.5 :: float, 0.2, 0.25, -1.3, 0.9, 0.05]],
--     array[1, 3]
--   );
-- select sm_sc.fv_d_new_dloss_dindepdt
--   (
--     array[[0.5 :: float, -0.2, 0.25, 1.3, -0.9], [-0.5 :: float, -0.2, -0.25, 1.3, 0.9], [0.5 :: float, 0.2, 0.25, -1.3, 0.9], [0.2, 0.25, -1.3, 0.9, 0.05]],
--     array[2, 1]
--   );
-- select sm_sc.fv_d_new_dloss_dindepdt
--   (
--     array[[0.5 :: float, -0.2, 0.25, 1.3, -0.9, -0.25], [-0.5 :: float, -0.2, -0.25, 1.3, 0.9, -0.75], [0.5 :: float, 0.2, 0.25, -1.3, 0.9, -0.65], [0.9, -1.3, -0.25, 1.3, 0.9, 0.75]],
--     array[2, 3]
--   );
-- select sm_sc.fv_d_new_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[4, 6, 9])
--   , array[2, 2, 3]
--   );
-- select sm_sc.fv_d_new_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[10, 4, 6, 9])
--   , array[5, 2, 2, 3]
--   );