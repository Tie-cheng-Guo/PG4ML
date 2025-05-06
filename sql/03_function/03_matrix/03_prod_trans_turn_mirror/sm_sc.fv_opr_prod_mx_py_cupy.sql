-- drop function if exists sm_sc.fv_opr_prod_mx_py_cupy(float[], float[]);
create or replace function sm_sc.fv_opr_prod_mx_py_cupy
(
  i_left      float[]  ,
  i_right     float[]
)
returns float[]
as
$$
  import cupy as cp
  with cp.cuda.Device(0):
    return (cp.float64(i_left) @ cp.float64(i_right)).tolist()
$$
language plpython3u stable
parallel safe
;

-- select 
--   sm_sc.fv_opr_prod_mx_py_cupy
--   (
--     array[array[1, 2, 3], array[1, 2, 3]] :: float[],
--     array[array[1, 2], array[3, 1], array[2, 3]] :: float[]
--   )
-- select -- 2.328
--   sm_sc.fv_opr_prod_mx_py_cupy
--   (
--     sm_sc.fv_new_rand(array[70, 28 * 28]),
--     sm_sc.fv_new_rand(array[28 * 28, 25 * 6])
--   )
-- select -- 2.849
--   sm_sc.fv_opr_prod_mx_py_cupy
--   (
--     sm_sc.fv_new_rand(array[70, 10 * 10]),
--     sm_sc.fv_new_rand(array[10 * 10, 25 * 60])
--   )
-- select -- 0.990
--   sm_sc.fv_opr_prod_mx_py_cupy
--   (
--     sm_sc.fv_new_rand(array[70, 25 * 16]),
--     sm_sc.fv_new_rand(array[25 * 16, 120])
--   )
-- select -- 0.088
--   sm_sc.fv_opr_prod_mx_py_cupy
--   (
--     sm_sc.fv_new_rand(array[70, 120]),
--     sm_sc.fv_new_rand(array[120, 10])
--   )