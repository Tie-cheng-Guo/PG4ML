-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_opr_prod_mx_py(float[], float[]);
create or replace function sm_sc.fv_opr_prod_mx_py
(
  i_left      float[]  ,
  i_right     float[]
)
returns float[]
as
$$
  import numpy as np
  return np.matmul(np.float64(i_left), np.float64(i_right)).tolist()
$$
language plpython3u stable
parallel safe
;

-- select 
--   sm_sc.fv_opr_prod_mx_py
--   (
--     array[array[1, 2, 3], array[1, 2, 3]] :: float[],
--     array[array[1, 2], array[3, 1], array[2, 3]] :: float[]
--   )
-- select -- 2.328
--   sm_sc.fv_opr_prod_mx_py
--   (
--     sm_sc.fv_new_rand(array[70, 28 * 28]),
--     sm_sc.fv_new_rand(array[28 * 28, 25 * 6])
--   )
-- select -- 2.849
--   sm_sc.fv_opr_prod_mx_py
--   (
--     sm_sc.fv_new_rand(array[70, 10 * 10]),
--     sm_sc.fv_new_rand(array[10 * 10, 25 * 60])
--   )
-- select -- 0.990
--   sm_sc.fv_opr_prod_mx_py
--   (
--     sm_sc.fv_new_rand(array[70, 25 * 16]),
--     sm_sc.fv_new_rand(array[25 * 16, 120])
--   )
-- select -- 0.088
--   sm_sc.fv_opr_prod_mx_py
--   (
--     sm_sc.fv_new_rand(array[70, 120]),
--     sm_sc.fv_new_rand(array[120, 10])
--   )