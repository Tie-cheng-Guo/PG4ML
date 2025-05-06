-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_reshape(float[], int[]);
create or replace function sm_sc.fv_opr_reshape_py
(
  i_arr           float[]
, i_new_shape     int[]
)
returns float[]
as
$$
  import numpy as np
  return np.reshape(i_arr, i_new_shape).tolist()
$$
language plpython3u stable
parallel safe
;

-- select 
--   sm_sc.fv_opr_reshape_py
--   (
--     array[[1.2, 2.4, 3.5], [1.6, 2.5, 3.9]] :: float[]
--   , array[2, 3]
--   )

-- select 
--   array_dims
--   (
--     sm_sc.fv_opr_reshape_py
--     (
--       sm_sc.fv_new_rand(array[2, 3, 4])
--     , array[2, 1, 6, 2]  -- array[4, 2, 3]
--     )
--   )

-- select 
--   array_dims
--   (
--     sm_sc.fv_opr_reshape_py
--     (
--       sm_sc.fv_new_rand(array[2, 3, 4, 5])
--     , array[5, 4, 3, 2]   -- array[4, 10, 3]
--     )
--   )
