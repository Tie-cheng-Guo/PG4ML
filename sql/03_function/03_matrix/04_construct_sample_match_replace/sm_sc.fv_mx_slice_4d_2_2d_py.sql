-- drop function if exists sm_sc.fv_mx_slice_4d_2_2d_py(float[], int[], int[]);
create or replace function sm_sc.fv_mx_slice_4d_2_2d_py
(
  i_array_4d        float[],  
  i_dim_sliced      int[]     ,          -- 被切片维度
  i_slice_pos       int[]                -- 被切片在 i_dim_sliced 各对应维度的位置序号。
)
returns float[]
as
$$
  import numpy as np
  if i_dim_sliced[0] == 1 :
    v_ret_3d = np.array(i_array_4d)[i_slice_pos[0] - 1, :: , :: , ::]
  elif i_dim_sliced[0] == 2 :
    v_ret_3d = np.array(i_array_4d)[:: , i_slice_pos[0] - 1, ::, ::]
  elif i_dim_sliced[0] == 3 :
    v_ret_3d = np.array(i_array_4d)[:: , :: , i_slice_pos[0] - 1, ::]
  elif i_dim_sliced[0] == 4 :
    v_ret_3d = np.array(i_array_4d)[:: , :: , :: , i_slice_pos[0] - 1]

  if i_dim_sliced[0] < i_dim_sliced[1] :
    i_dim_sliced[1] = i_dim_sliced[1] - 1

  if i_dim_sliced[1] == 1 :
    return v_ret_3d[i_slice_pos[1] - 1, :: , ::].tolist()
  elif i_dim_sliced[1] == 2 :
    return v_ret_3d[:: , i_slice_pos[1] - 1, ::].tolist()
  elif i_dim_sliced[1] == 3 :
    return v_ret_3d[:: , :: , i_slice_pos[1] - 1].tolist()
$$
language plpython3u stable
parallel safe;

-- -- set search_path to sm_sc;
-- select 
-- sm_sc.fv_mx_slice_4d_2_2d_py
-- (
--   (
--     array
--     [
--       [
--         [
--           [1, 2, 3, 4, 5]     ,
--           [11, 12, 13, 14, 15],
--           [21, 22, 23, 24, 25], 
--           [31, 32, 33, 34, 35] 
--         ],
--         [
--           [41, 42, 43, 44, 45]     ,
--           [51, 52, 53, 54, 55],
--           [61, 62, 63, 64, 65], 
--           [71, 72, 73, 74, 75] 
--         ],
--         [
--           [81, 82, 83, 84, 85]     ,
--           [91, 92, 93, 94, 95],
--           [101, 102, 103, 104, 105], 
--           [111, 112, 113, 114, 115] 
--         ]
--       ],
--       [
--         [
--           [-1, -2, -3, -4, -5]     ,
--           [-11, -12, -13, -14, -15],
--           [-21, -22, -23, -24, -25], 
--           [-31, -32, -33, -34, -35] 
--         ],
--         [
--           [-41, -42, -43, -44, -45]     ,
--           [-51, -52, -53, -54, -55],
--           [-61, -62, -63, -64, -65], 
--           [-71, -72, -73, -74, -75] 
--         ],
--         [
--           [-81, -82, -83, -84, -85]     ,
--           [-91, -92, -93, -94, -95],
--           [-101, -102, -103, -104, -105], 
--           [-111, -112, -113, -114, -115] 
--         ]
--       ]
--     ]
--   )
--   , array[4, 3]
--   , array[1, 2]
-- )