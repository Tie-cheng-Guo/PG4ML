-- drop function if exists sm_sc.fv_d_prod_mx_dloss_dindepdt_1(float[], float[], int[]);
create or replace function sm_sc.fv_d_prod_mx_dloss_dindepdt_1
(
  i_dloss_ddepdt   float[]   ,
  i_co_value       float[]   ,
  i_indepdt_len    int[]    default null
)
returns float[]
as
$$
declare 
begin
  -- return i_dloss_ddepdt |**| (|^~| sm_sc.fv_d_prod_mx_1(i_co_value));
  if i_indepdt_len is null 
  then 
    return i_dloss_ddepdt |**| (|^~| i_co_value);
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    if array_length(i_indepdt_len, 1) = 3
    then 
      return 
        sm_sc.fv_mx_slice_4d_2_3d
        (
          sm_sc.fv_aggr_slice_sum
          (
            i_dloss_ddepdt |**| (|^~| i_co_value)
          , array[array_length(i_dloss_ddepdt, 1), 1, 1, 1]
          )
        , 1
        , 1
        )
      ;
    elsif array_length(i_indepdt_len, 1) = 2
    then
      return 
        sm_sc.fv_mx_slice_4d_2_2d
        (
          sm_sc.fv_aggr_slice_sum
          (
            i_dloss_ddepdt |**| (|^~| i_co_value)
          , array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2), 1, 1]
          )
        , array[1, 2]
        , array[1, 1]
        )
      ;
    else -- array_length(i_indepdt_len, 1) = 4
      return i_dloss_ddepdt |**| (|^~| i_co_value);
    end if;
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    if array_length(i_indepdt_len, 1) = 2
    then 
      return 
        sm_sc.fv_mx_slice_3d_2_2d
        (
          sm_sc.fv_aggr_slice_sum
          (
            i_dloss_ddepdt |**| (|^~| i_co_value)
          , array[array_length(i_dloss_ddepdt, 1), 1, 1]
          )
        , 1
        , 1
        )
      ;
    else -- array_length(i_indepdt_len, 1) = 3
      return i_dloss_ddepdt |**| (|^~| i_co_value);
    end if;
  else 
    return i_dloss_ddepdt |**| (|^~| i_co_value);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[3, 4])     ,
--     array[2, 3]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[5, 2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[3, 4])     ,
--     array[5, 2, 3]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[5, 2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[5, 3, 4])     ,
--     array[2, 3]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[5, 6, 2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[5, 6, 3, 4])     ,
--     array[2, 3]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[5, 6, 2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[3, 4])     ,
--     array[5, 6, 2, 3]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[5, 6, 2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[5, 6, 3, 4])     ,
--     array[6, 2, 3]
--   )

-- select 
--   sm_sc.fv_d_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[5, 6, 2, 4])     ,    -- dloss_ddepdt
--     sm_sc.fv_new_rand(array[6, 3, 4])     ,
--     array[5, 6, 2, 3]
--   )