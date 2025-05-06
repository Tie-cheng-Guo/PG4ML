-- drop function if exists sm_sc.fv_d_transpose_nd_dloss_dindepdt(float[], int[]);
create or replace function sm_sc.fv_d_transpose_nd_dloss_dindepdt
(
  i_dloss_ddepdt_nd      float[]      ,
  i_dims                 int[]
)
returns float[]
as
$$
-- declare

begin 
  if array_ndims(i_dloss_ddepdt_nd) = 2
  then 
    return 
      sm_sc.fv_opr_transpose_nd_py
      (
        i_dloss_ddepdt_nd
      , array 
        [
          array_position(i_dims, 1)
        , array_position(i_dims, 2)
        ]
      )
    ;
  elsif array_ndims(i_dloss_ddepdt_nd) = 3
  then 
    return 
      sm_sc.fv_opr_transpose_nd_py
      (
        i_dloss_ddepdt_nd
      , array 
        [
          array_position(i_dims, 1)
        , array_position(i_dims, 2)
        , array_position(i_dims, 3)
        ]
      )
    ;
  elsif array_ndims(i_dloss_ddepdt_nd) = 4
  then 
    return 
      sm_sc.fv_opr_transpose_nd_py
      (
        i_dloss_ddepdt_nd
      , array 
        [
          array_position(i_dims, 1)
        , array_position(i_dims, 2)
        , array_position(i_dims, 3)
        , array_position(i_dims, 4)
        ]
      )
    ;
  elsif array_ndims(i_dloss_ddepdt_nd) = 5
  then 
    return 
      sm_sc.fv_opr_transpose_nd_py
      (
        i_dloss_ddepdt_nd
      , array 
        [
          array_position(i_dims, 1)
        , array_position(i_dims, 2)
        , array_position(i_dims, 3)
        , array_position(i_dims, 4)
        , array_position(i_dims, 5)
        ]
      )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- with 
-- cte_arr as 
-- (
--   select 
--     array[2, 3] as a_dims
--   , sm_sc.fv_new_rand(array[2, 3]) as a_arr
--   , array[1, 2] as a_asso
--   union all
--   select 
--     array[2, 3, 4] as a_dims
--   , sm_sc.fv_new_rand(array[2, 3, 4]) as a_arr
--   , array[2, 3, 1] as a_asso
--   union all
--   select 
--     array[2, 3, 4, 5] as a_dims
--   , sm_sc.fv_new_rand(array[2, 3, 4, 5]) as a_arr
--   , array[2, 4, 1, 3] as a_asso
-- )
-- select 
--   a_dims
-- , sm_sc.fv_d_transpose_nd_dloss_dindepdt
--   (
--     sm_sc.fv_opr_transpose_nd(a_arr, a_asso)
--   , a_asso
--   ) = a_arr
-- from cte_arr