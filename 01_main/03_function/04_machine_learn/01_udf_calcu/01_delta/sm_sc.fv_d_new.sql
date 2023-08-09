-- drop function if exists sm_sc.fv_d_new(float[], int);
create or replace function sm_sc.fv_d_new
(
  i_indepdt_var            float[]    ,
  i_yx_times               int[]
)
returns float[]    -- 返回值为 2d
as
$$
declare 
  v_depdt_var_len_y   int    :=    array_length(i_indepdt_var, 1) / i_yx_times[1];
  v_depdt_var_len_x   int    :=    array_length(i_indepdt_var, 2) / i_yx_times[2];
begin
  -- set search_path to sm_sc;
  if array_ndims(i_indepdt_var) <> 2
  then
    raise exception 'no method!';
  elsif array_length(i_indepdt_var, 1) % i_yx_times[1] <> 0
    or array_length(i_indepdt_var, 2) % i_yx_times[2] <> 0
  then 
    raise exception 'yx_times is not intact at the tail of len of indepdt_var.';
  elsif array_ndims(i_indepdt_var) is null
  then 
    return array[] :: i_indepdt_var%type;
  else
    return 
    (
      select 
        sm_sc.fa_mx_sum(i_indepdt_var[v_depdt_var_len_y * (a_y_no - 1) + 1 :  + v_depdt_var_len_y * a_y_no][v_depdt_var_len_x * (a_x_no - 1) + 1 :  + v_depdt_var_len_x * a_x_no]) 
      from generate_series(1, i_yx_times[1]) tb_a_y(a_y_no)
        , generate_series(1, i_yx_times[2]) tb_a_x(a_x_no)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_new
--   (
--     array[array[0.5 :: float, -0.2, 0.25, 1.3, -0.9, -0.1], array[-0.5 :: float, -0.2, -0.25, 1.3, 0.9, 0.1], array[0.5 :: float, 0.2, 0.25, -1.3, 0.9, 0.05]],
--     array[1, 3]
--   );
-- select sm_sc.fv_d_new
--   (
--     array[array[0.5 :: float, -0.2, 0.25, 1.3, -0.9], array[-0.5 :: float, -0.2, -0.25, 1.3, 0.9], array[0.5 :: float, 0.2, 0.25, -1.3, 0.9], array[0.2, 0.25, -1.3, 0.9, 0.05]],
--     array[2, 1]
--   );
-- select sm_sc.fv_d_new
--   (
--     array[array[0.5 :: float, -0.2, 0.25, 1.3, -0.9, -0.25], array[-0.5 :: float, -0.2, -0.25, 1.3, 0.9, -0.75], array[0.5 :: float, 0.2, 0.25, -1.3, 0.9, -0.65], array[0.9, -1.3, -0.25, 1.3, 0.9, 0.75]],
--     array[2, 3]
--   );