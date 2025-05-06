-- drop function if exists sm_sc.fv_opr_is_less_py(float[], float[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     float[]    ,
  i_right    float[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(float, float[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     float    ,
  i_right    float[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(float[], float);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     float[]    ,
  i_right    float
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select sm_sc.fv_opr_is_less_py(array[1,2,3], array[2,2,3])
-- select sm_sc.fv_opr_is_less_py(3, array[2,2,3])
-- select sm_sc.fv_opr_is_less_py(array[1,2,3], 2)

-- ------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_less_py(bigint[], bigint[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     bigint[]    ,
  i_right    bigint[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(bigint, bigint[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     bigint    ,
  i_right    bigint[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(bigint[], bigint);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     bigint[]    ,
  i_right    bigint
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- ------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_less_py(int[], int[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     int[]    ,
  i_right    int[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(int, int[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     int    ,
  i_right    int[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(int[], int);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     int[]    ,
  i_right    int
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- ------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_less_py(decimal[], decimal[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     decimal[]    ,
  i_right    decimal[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(decimal, decimal[]);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     decimal    ,
  i_right    decimal[]
)
returns boolean[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_is_less_py(decimal[], decimal);
create or replace function sm_sc.fv_opr_is_less_py
(
  i_left     decimal[]    ,
  i_right    decimal
)
returns boolean[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    return np.less(np.array(i_left), np.array(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select
--   sm_sc.fv_opr_is_less_py(array[[12,9,18]],array[[3,3,2]]::bigint[])
-- , sm_sc.fv_opr_is_less_py(array[[12,9,18]],array[[3,3,2]]::int[])
-- , sm_sc.fv_opr_is_less_py(              12,array[[3,3,2]]::bigint[])
-- , sm_sc.fv_opr_is_less_py(array[[12,9,18]],             3::bigint)
-- , sm_sc.fv_opr_is_less_py(              12,array[[3,3,2]]::   int[])
-- , sm_sc.fv_opr_is_less_py(array[[12,9,18]],             3::   int)