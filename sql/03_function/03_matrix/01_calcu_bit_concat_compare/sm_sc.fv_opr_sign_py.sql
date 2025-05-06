-- drop function if exists sm_sc.fv_opr_sign_py(decimal[]);
create or replace function sm_sc.fv_opr_sign_py
(
  i_right    decimal[]
)
returns int[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.int8((np.sign(np.array(i_right)))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_opr_sign_py(array[-0.4, 1.5, -2.7, 8.2, 0.0])

-- ---------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_sign_py(float[]);
create or replace function sm_sc.fv_opr_sign_py
(
  i_right    float[]
)
returns int[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.int8((np.sign(np.array(i_right)))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_opr_sign_py(array[-0.4, 1.5, -2.7, 8.2, 0.0])

-- ---------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_sign_py(bigint[]);
create or replace function sm_sc.fv_opr_sign_py
(
  i_right    bigint[]
)
returns int[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.int8((np.sign(np.array(i_right)))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- ---------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_sign_py(int[]);
create or replace function sm_sc.fv_opr_sign_py
(
  i_right    int[]
)
returns int[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.int8((np.sign(np.array(i_right)))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select
--   sm_sc.fv_opr_sign_py(array[[3,3,2]]::bigint[])
-- , sm_sc.fv_opr_sign_py(array[[3,3,2]]::int[])