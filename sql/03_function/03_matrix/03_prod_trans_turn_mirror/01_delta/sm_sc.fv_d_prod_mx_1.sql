-- drop function if exists sm_sc.fv_d_prod_mx_1(float[][], int[]);
create or replace function sm_sc.fv_d_prod_mx_1
(
  i_co_value    float[], 
  i_indepdt_len int[]    default null
)
returns float[]
as
$$
declare 
begin
  if i_indepdt_len is null 
  then 
    return i_co_value;
  elsif array_ndims(i_co_value) = 2
  then 
    if array_length(i_indepdt_len, 1) = 3
    then 
      return i_co_value *` i_indepdt_len[1] :: float;
    elsif array_length(i_indepdt_len, 1) = 4
    then
      return i_co_value *` (i_indepdt_len[1] * i_indepdt_len[2]) :: float;
    else  -- array_length(i_indepdt_len, 1) = 2
      return i_co_value;
    end if;
  elsif array_ndims(i_co_value) = 3
  then 
    if array_length(i_indepdt_len, 1) = 4
    then 
      return i_co_value *` i_indepdt_len[1] :: float;
    elsif array_length(i_indepdt_len, 1) = 2
    then 
      return 
        sm_sc.fv_mx_slice_3d_2_2d
        (
          sm_sc.fv_aggr_slice_sum_py(i_co_value, array[array_length(i_co_value, 1), 1, 1])
        , 1
        , 1
        )
      ;
    else -- array_length(i_indepdt_len, 1) = 3
      return i_co_value;
    end if;
  elsif array_ndims(i_co_value) = 4
  then 
    if array_length(i_indepdt_len, 1) = 2
    then 
      return 
        sm_sc.fv_mx_slice_4d_2_2d
        (
          sm_sc.fv_aggr_slice_sum_py(i_co_value, array[array_length(i_co_value, 1), array_length(i_co_value, 2), 1, 1])
        , array[1, 2]
        , array[1, 1]
        )
      ;
    elsif array_length(i_indepdt_len, 1) = 3
    then 
      return 
        sm_sc.fv_mx_slice_4d_2_3d
        (
          sm_sc.fv_aggr_slice_sum_py(i_co_value, array[array_length(i_co_value, 1), 1, 1, 1])
        , 1
        , 1
        )
      ;
    else -- array_length(i_indepdt_len, 1) = 4
      return i_co_value;
    end if;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_prod_mx_1
--   (
--     sm_sc.fv_new_rand(array[3, 2, 5])
--   , array[6, 5]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_1
--   (
--     sm_sc.fv_new_rand(array[3, 2, 5])
--   , array[3, 6, 5]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_1
--   (
--     sm_sc.fv_new_rand(array[4, 3, 2, 5])
--   , array[6, 5]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_1
--   (
--     sm_sc.fv_new_rand(array[4, 3, 2, 5])
--   , array[3, 6, 5]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_1
--   (
--     sm_sc.fv_new_rand(array[4, 3, 2, 5])
--   , array[4, 3, 6, 5]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_1
--   (
--     sm_sc.fv_new_rand(array[2, 5])
--   , array[6, 5]
--   )