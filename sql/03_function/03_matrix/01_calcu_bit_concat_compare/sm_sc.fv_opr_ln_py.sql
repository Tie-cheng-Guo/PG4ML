-- drop function if exists sm_sc.fv_opr_ln_py(float[]);
create or replace function sm_sc.fv_opr_ln_py
(
  i_right    float[]
)
returns float[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return (np.log(np.array(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_ln_py(decimal[]);
create or replace function sm_sc.fv_opr_ln_py
(
  i_right    decimal[]
)
returns decimal[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return (np.log(np.array(i_right).astype(float))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_opr_ln_py(array[0.4, 1.5, 2.7, 8.2])