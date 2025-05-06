-- drop function if exists sm_sc.fv_cosh_py(float[]);
create or replace function sm_sc.fv_cosh_py
(
  i_right    float[]
)
returns float[]
as
$$
  import numpy as np
  return (np.cosh(np.array(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_cosh_py(array[-0.4, 1.5, -2.7, 8.2, 0.0])