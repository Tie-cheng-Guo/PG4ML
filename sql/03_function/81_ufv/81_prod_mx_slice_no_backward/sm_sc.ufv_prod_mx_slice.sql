-- drop function if exists sm_sc.ufv_prod_mx_slice(float[], float[]);
create or replace function sm_sc.ufv_prod_mx_slice
(
  i_left                            float[]
, i_right                           float[]
)
returns float[]
as
$$
declare
  v_w_h   int   :=  least(array_length(i_left, array_ndims(i_left)), array_length(i_right, array_ndims(i_right) - 1));
begin
  if array_ndims(i_left) = 2
  then 
    if array_ndims(i_right) = 2
    then 
      return i_left[ : ][ : v_w_h] |**| i_right[ : v_w_h][ : ];
    elsif array_ndims(i_right) = 3
    then 
      return i_left[ : ][ : v_w_h] |**| i_right[ : ][ : v_w_h][ : ];
    elsif array_ndims(i_right) = 4
    then 
      return i_left[ : ][ : v_w_h] |**| i_right[ : ][ : ][ : v_w_h][ : ];
    end if;
  elsif array_ndims(i_left) = 3
  then 
    if array_ndims(i_right) = 2
    then 
      return i_left[ : ][ : ][ : v_w_h] |**| i_right[ : v_w_h][ : ];
    elsif array_ndims(i_right) = 3
    then 
      return i_left[ : ][ : ][ : v_w_h] |**| i_right[ : ][ : v_w_h][ : ];
    elsif array_ndims(i_right) = 4
    then 
      return i_left[ : ][ : ][ : v_w_h] |**| i_right[ : ][ : ][ : v_w_h][ : ];
    end if;
  elsif array_ndims(i_left) = 4
  then 
    if array_ndims(i_right) = 2
    then 
      return i_left[ : ][ : ][ : ][ : v_w_h] |**| i_right[ : v_w_h][ : ];
    elsif array_ndims(i_right) = 3
    then 
      return i_left[ : ][ : ][ : ][ : v_w_h] |**| i_right[ : ][ : v_w_h][ : ];
    elsif array_ndims(i_right) = 4
    then 
      return i_left[ : ][ : ][ : ][ : v_w_h] |**| i_right[ : ][ : ][ : v_w_h][ : ];
    end if;
  
  end if;
end
$$
language plpgsql stable
parallel safe
;

-- select 
--   (
--     sm_sc.ufv_prod_mx_slice
--     (
--       sm_sc.fv_new_randn(0.0, 1.1, array[5,3])
--     , sm_sc.fv_new_randn(0.0, 1.1, array[8,7])
--     ) :: decimal[] ~=` 6
--   )

-- select 
--   (
--     sm_sc.ufv_prod_mx_slice
--     (
--       sm_sc.fv_new_randn(0.0, 1.1, array[5,8])
--     , sm_sc.fv_new_randn(0.0, 1.1, array[4,7])
--     ) :: decimal[] ~=` 6
--   )

-- select 
--   (
--     sm_sc.ufv_prod_mx_slice
--     (
--       sm_sc.fv_new_randn(0.0, 1.1, array[3,5,8])
--     , sm_sc.fv_new_randn(0.0, 1.1, array[4,7])
--     ) :: decimal[] ~=` 6
--   )

-- select 
--   (
--     sm_sc.ufv_prod_mx_slice
--     (
--       sm_sc.fv_new_randn(0.0, 1.1, array[5,8])
--     , sm_sc.fv_new_randn(0.0, 1.1, array[5,4,7])
--     ) :: decimal[] ~=` 6
--   )

-- select 
--   (
--     sm_sc.ufv_prod_mx_slice
--     (
--       sm_sc.fv_new_randn(0.0, 1.1, array[3,5,8])
--     , sm_sc.fv_new_randn(0.0, 1.1, array[6,3,4,7])
--     ) :: decimal[] ~=` 6
--   )

-- select 
--   (
--     sm_sc.ufv_prod_mx_slice
--     (
--       sm_sc.fv_new_randn(0.0, 1.1, array[5,8])
--     , sm_sc.fv_new_randn(0.0, 1.1, array[6,5,4,7])
--     ) :: decimal[] ~=` 6
--   )