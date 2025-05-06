-- drop function if exists sm_sc.fv_opr_exp_py(float[]);
create or replace function sm_sc.fv_opr_exp_py
(
  i_right    float[]
)
returns float[]
as
$$
  import numpy as np
  if i_right is None :
    return i_right
  else :
    return (np.exp(1) ** np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- select 
--   sm_sc.fv_opr_exp_py
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5])
--   )