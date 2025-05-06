-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_mx_pow(float[], int);
create or replace function sm_sc.fv_opr_prod_mx_pow
(
  i_left     float[]    ,
  i_right    int
)
returns float[]
as
$$
declare -- here
  v_right_log_2   int;
  v_arr_pow_part  float[];
begin
    -- i_left 必须方阵，否则报错
    if array_length(i_left, array_ndims(i_left) - 1) <> array_length(i_left, array_ndims(i_left))
    then 
      raise exception 'i_left must be a square. ';
    end if;

    if i_right = 0
    then 
      return sm_sc.fv_eye_unit(array_length(i_left, array_ndims(i_left)), 1.0);
    elsif i_right < 0
    then 
      raise exception 'i_right should be >= 0. ';
    end if;

    -- 算法时间复杂度优化：log 递归
    v_right_log_2   :=  floor(log(2, i_right));

    if v_right_log_2 = 0    -- 此时，v_right = 1
    then
      return i_left;
    else   -- 此时，v_right_log_2 >= 1
      v_arr_pow_part := sm_sc.fv_opr_prod_mx_pow(i_left, power(v_right_log_2 - 1, 2) :: int);
      return v_arr_pow_part |**| v_arr_pow_part |**| sm_sc.fv_opr_prod_mx_pow(i_left, i_right - power(v_right_log_2, 2) :: int);
    end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_prod_mx_pow
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     4   -- 1, 2, 3, 4, 5, 6, 7, 8, 9
--   );