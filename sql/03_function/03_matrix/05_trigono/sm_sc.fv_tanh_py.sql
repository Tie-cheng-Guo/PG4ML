-- drop function if exists sm_sc.fv_tanh_py(float[]);
create or replace function sm_sc.fv_tanh_py
(
  i_right    float[]
)
returns float[]
as
$$
  import numpy as np
  return (np.tanh(np.array(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_tanh_py(array[-0.4, 1.5, -2.7, 8.2, 0.0])