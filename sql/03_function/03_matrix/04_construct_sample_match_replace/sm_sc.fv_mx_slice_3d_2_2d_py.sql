-- drop function if exists sm_sc.fv_mx_slice_3d_2_2d_py(float[], int, int);
create or replace function sm_sc.fv_mx_slice_3d_2_2d_py
(
  i_array_3d        float[],  
  i_dim_sliced      int     ,               -- 被切片维度
  i_slice_pos       int     default  1      -- 被切片位置序号
)
returns float[]
as
$$
  import numpy as np
  if i_dim_sliced == 1 :
    return np.array(i_array_3d)[i_slice_pos - 1, :: , ::].tolist()
  elif i_dim_sliced == 2 :
    return np.array(i_array_3d)[:: , i_slice_pos - 1, ::].tolist()
  elif i_dim_sliced == 3 :
    return np.array(i_array_3d)[:: , :: , i_slice_pos - 1].tolist()

$$
language plpython3u stable
parallel safe;

-- -- set search_path to sm_sc;
-- select 
-- sm_sc.fv_mx_slice_3d_2_2d_py
-- (
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4, 5]     ,
--         [11, 12, 13, 14, 15],
--         [21, 22, 23, 24, 25], 
--         [31, 32, 33, 34, 35] 
--       ],
--       [
--         [41, 42, 43, 44, 45]     ,
--         [51, 52, 53, 54, 55],
--         [61, 62, 63, 64, 65], 
--         [71, 72, 73, 74, 75] 
--       ],
--       [
--         [81, 82, 83, 84, 85]     ,
--         [91, 92, 93, 94, 95],
--         [101, 102, 103, 104, 105], 
--         [111, 112, 113, 114, 115] 
--       ]
--     ]
--   )
--   , 
-- 1
-- )