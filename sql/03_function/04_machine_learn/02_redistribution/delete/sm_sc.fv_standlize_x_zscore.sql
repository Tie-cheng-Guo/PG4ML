-- drop function if exists sm_sc.fv_standlize_x_zscore(float[]);
-- create or replace function sm_sc.fv_standlize_x_zscore
-- (
--   i_array     float[]
-- )
-- returns float[]
-- as
-- $$
-- -- declare -- here
--   -- v_avg_x             float[]   :=   sm_sc.fv_aggr_slice_avg_py(i_array, array[1, array_length(i_array, 2)]) ;
--   -- v_stddev_samp_x     float[]   :=   sm_sc.fv_ele_replace(sm_sc.fv_aggr_slice_stddev_samp(i_array, array[1, array_length(i_array, 2)]), array[0.0 :: float], 'NaN' :: float);
-- begin
--   -- log(null :: float[][], float) = null :: float[][]
--   if array_ndims(i_array) is null
--   then 
--     return array[] :: float[];
--   elsif array_ndims(i_array) = 2
--   then
--     return (i_array -` sm_sc.fv_aggr_slice_avg_py(i_array, array[1, array_length(i_array, 2)])) /` sm_sc.fv_ele_replace(sm_sc.fv_aggr_slice_stddev_samp(i_array, array[1, array_length(i_array, 2)]), array[0.0 :: float], 'NaN' :: float);
--   else
--     raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
--   end if;
-- end
-- $$
-- language plpgsql stable
-- parallel safe
-- cost 100;
-- -- select sm_sc.fv_standlize_x_zscore(array[array[12.3, 25.1, 17.8], array[2.56, 3.25, 56.4]]) ~=` 6
-- -- -- select sm_sc.fv_standlize_x_zscore(array[12.3, 25.1, 28.33]) ~=` 6
-- -- select sm_sc.fv_standlize_x_zscore(array[]::float[]) ~=` 6
-- -- select sm_sc.fv_standlize_x_zscore(array[array[], array []]::float[]) ~=` 6
-- 
-- -- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_standlize_x_zscore(float[], int);
-- create or replace function sm_sc.fv_standlize_x_zscore
-- (
--   i_array          float[],
--   i_cnt_per_grp    int
-- )
-- returns float[]
-- as
-- $$
-- -- declare 
-- begin
--   if array_length(i_array, 2) % i_cnt_per_grp <> 0 
--     or i_cnt_per_grp <= 0
--   then 
--     raise exception 'imperfect length_2 of i_array of this cnt_per_grp';
--   end if;
--   
--   return 
--   (
--     select 
--       sm_sc.fa_mx_concat_x(sm_sc.fv_standlize_x_zscore(i_array[ : ][a_cur : a_cur + i_cnt_per_grp - 1]) order by a_cur)
--     from generate_series(1, array_length(i_array, 2), i_cnt_per_grp) tb_a_cur(a_cur)
--   )
--   ;
-- end
-- $$
-- language plpgsql stable
-- parallel safe
-- cost 100;
-- -- select sm_sc.fv_standlize_x_zscore(array[[12.3, 25.1, 8.2, 2.56, 3.33, -1.9], [3.25, 26.4, 6.6, 56.4, -2.65, -4.6]], 3) :: decimal[] ~=` 6