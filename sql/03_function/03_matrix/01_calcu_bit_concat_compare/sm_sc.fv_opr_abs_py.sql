-- drop function if exists sm_sc.fv_opr_abs_py(float[]);
create or replace function sm_sc.fv_opr_abs_py
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
    return (np.abs(np.float32(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_opr_abs_py(array[0.4, 1.5, 2.7, 8.2] :: float[])
-- select sm_sc.fv_opr_abs_py(null :: decimal[])
-- select sm_sc.fv_opr_abs_py(array[] :: decimal[])

-- drop function if exists sm_sc.fv_opr_abs_py(decimal[]);
create or replace function sm_sc.fv_opr_abs_py
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
    return (np.abs(np.float32(i_right).astype(float))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_opr_abs_py(array[0.4, 1.5, 2.7, 8.2])
-- select sm_sc.fv_opr_abs_py(null :: decimal[])