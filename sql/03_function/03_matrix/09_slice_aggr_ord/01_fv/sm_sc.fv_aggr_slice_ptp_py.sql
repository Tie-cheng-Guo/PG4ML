-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_ptp_py(float[]);
create or replace function sm_sc.fv_aggr_slice_ptp_py
(
  i_array          float[]
)
returns float
as
$$
begin 
  return sm_sc.fv_aggr_slice_max_py(i_array) - sm_sc.fv_aggr_slice_min_py(i_array);
end 
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]::float[]
--   );

-- select sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[1,2,3,4,5,6]::float[]
--   );

-- select sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[[[1,2,3,4,25,6],[-1,-2,-3,4,5,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,5,6]]]::float[]
--   );

-- select sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[[[[1,2,3,4,25,6],[-1,-2,-3,4,35,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,25,6]]],[[[1,12,3,4,25,6],[-1,-42,-3,4,5,6]],[[1,2,13,-4,-5,-36],[1,12,3,14,5,6]]]]::float[]
--   );

-- select sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[]::float[]
--   );

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_aggr_slice_ptp_py(float[], int[]);
create or replace function sm_sc.fv_aggr_slice_ptp_py
(
  i_array          float[],
  i_cnt_per_grp    int[]
)
returns float[]
as
$$
begin 
  return sm_sc.fv_aggr_slice_max_py(i_array, i_cnt_per_grp) - sm_sc.fv_aggr_slice_min_py(i_array, i_cnt_per_grp);
end 
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--     , array[3]
--   ) :: decimal[] ~=` 6
-- select 
--   sm_sc.fv_aggr_slice_ptp_py
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6

-- select
--   sm_sc.fv_aggr_slice_ptp_py
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15])
--   , array[2, 3, 3]
--   )

-- select
--   sm_sc.fv_aggr_slice_ptp_py
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15, 8])
--   , array[2, 3, 3, 4]
--   )

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3,5*7]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_ptp_py(a_arr, array[3,7]) :: decimal[] ~=` 3
-- = sm_sc.fv_aggr_slice_ptp(a_arr, array[3,7]) :: decimal[] ~=` 3
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_ptp_py(a_arr, array[3,7,1]) :: decimal[] ~=` 3
-- = sm_sc.fv_aggr_slice_ptp(a_arr, array[3,7,1]) :: decimal[] ~=` 3
-- from cte_arr

-- with 
-- cte_arr as 
-- (
--   select sm_sc.fv_new_rand(array[2*3, 5*7, 4*6, 3*5]) as a_arr
-- )
-- select 
--   sm_sc.fv_aggr_slice_ptp_py(a_arr, array[3,1,1,5]) :: decimal[] ~=` 3
-- = sm_sc.fv_aggr_slice_ptp(a_arr, array[3,1,1,5]) :: decimal[] ~=` 3
-- from cte_arr