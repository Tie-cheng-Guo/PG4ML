-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_rand_slice_x4(anyarray, int);
create or replace function sm_sc.fv_rand_slice_x4
(
  i_array          anyarray          ,
  i_select_cnt     int
)
returns anyarray
as
$$
-- declare

begin
  -- set search_path to sm_sc;
  if array_ndims(i_array) is null
  then 
    return i_array;
  -- -- elsif array_ndims(i_array) = 2 and i_select_cnt <= array_length(i_array, 2)
  -- -- then
  -- --   return
  -- --   (
  -- --     select
  -- --       sm_sc.fa_mx_concat_x(i_array[ : ][a_cur : a_cur]) as o_slices
  -- --     from unnest(sm_sc.fv_rand_1d_ele(array_length(i_array, 4), i_select_cnt)) tb_a_cur(a_cur)
  -- --   )
  -- --   ;
  -- -- elsif array_ndims(i_array) = 3 and i_select_cnt <= array_length(i_array, 2)
  -- -- then
  -- --   return
  -- --   (
  --        select
  -- --       sm_sc.fa_mx_concat_x3(i_array[ : ][ : ][a_cur : a_cur]) as o_slices
  -- --     from unnest(sm_sc.fv_rand_1d_ele(array_length(i_array, 4), i_select_cnt)) tb_a_cur(a_cur)
  -- --   )
  -- --   ;
  elsif array_ndims(i_array) = 4
  then
    return 
    (
      select
        sm_sc.fa_mx_concat_x4(i_array[ : ][ : ][ : ][a_cur : a_cur]) as o_slices
      from unnest(sm_sc.fv_rand_1d_ele(array_length(i_array, 4), i_select_cnt)) tb_a_cur(a_cur)
    )
    ;
  else
    raise exception 'no method for such length!  Dim: %; select_cnt: %;', array_dims(i_array), i_select_cnt;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- -- select sm_sc.fv_rand_slice_x4
-- --   (
-- --     array[[1, 2, 3, 4, 5, 6], [7, 8, 9, 10, 11, 12]]
-- --     , 9
-- --     -- , true
-- --   );
-- -- select sm_sc.fv_rand_slice_x4
-- --   (
-- --     array[[[1, 2, 3], [11, 21, 31], [12, 22, 32], [13, 23, 33], [14, 24, 34], [15, 25, 35]]
-- --         , [[16, 26, 36], [17, 27, 37], [18, 28, 38], [19, 29, 39], [61, 62, 63], [81, 82, 83]]]
-- --     , 5
-- --     -- , true
-- --   );
-- select sm_sc.fv_rand_slice_x4
--   (
--     array[[[[1, -1], [2, -2], [3, -3]], [[11, -11], [21, -21], [31, -31]], [[12, -12], [22, -22], [32, -32]], [[13, -13], [23, -23], [33, -33]], [[14, -14], [24, -24], [34, -34]], [[15, -15], [25, -25], [35, -35]]]
--         , [[[16, -16], [26, -26], [36, -36]], [[17, -17], [27, -27], [37, -37]], [[18, -18], [28, -28], [38, -38]], [[19, -19], [29, -29], [39, -39]], [[61, -61], [62, -62], [63, -63]], [[81, -81], [82, -82], [83, -83]]]]
--     , 7
--     -- , true
--   );