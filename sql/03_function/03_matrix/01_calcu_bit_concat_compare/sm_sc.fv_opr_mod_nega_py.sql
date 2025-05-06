-- drop function if exists sm_sc.fv_opr_mod_nega_py(decimal(32, 4)[], decimal(32, 4)[]);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     decimal(32, 4)[]    ,
  i_right    decimal(32, 4)[]
)
returns decimal(32, 4)[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mod_nega_py(decimal(32, 4)[], decimal(32, 4));
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     decimal(32, 4)[]    ,
  i_right    decimal(32, 4)
)
returns decimal(32, 4)[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mod_nega_py(decimal(32, 4), decimal(32, 4)[]);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     decimal(32, 4)    ,
  i_right    decimal(32, 4)[]
)
returns decimal(32, 4)[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_opr_mod_nega_py
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5])  :: decimal(32, 4)[]
--   , sm_sc.fv_new_rand(array[   1, 4, 5])  :: decimal(32, 4)[]
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]] :: decimal(32, 4)[],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[32.5], array[-9.1]] :: decimal(32, 4)[],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]] :: decimal(32, 4)[],
--     array[array[12.5], array[-19.1]] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[32.5, -9.1] :: decimal(32, 4)[],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]] :: decimal(32, 4)[],
--     array[12.5, -19.1] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[32.5, -9.1]] :: decimal(32, 4)[],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]] :: decimal(32, 4)[],
--     array[array[12.5, -19.1]] :: decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[]::decimal(32, 4)[] :: decimal(32, 4)[],
--     array[array[], array []]::decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[], array []]::decimal(32, 4)[],
--     array[]::decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[array[], array []]::decimal(32, 4)[],
--     array[array[], array []]::decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py
--   (
--     array[1.2, 2.3]::decimal(32, 4)[],
--     array[2.1, 3.2]::decimal(32, 4)[]
--   );
-- select sm_sc.fv_opr_mod_nega_py(array[1], array[1,2,3]) :: decimal(32, 4)[];
-- select sm_sc.fv_opr_mod_nega_py(array[1], array[array[1,2,3]]) :: decimal(32, 4)[];
-- select sm_sc.fv_opr_mod_nega_py(array[array[1]], array[1,2,3]) :: decimal(32, 4)[];
-- select sm_sc.fv_opr_mod_nega_py(array[array[1]], array[array[1,2,3]]) :: decimal(32, 4)[];

-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_mod_nega_py
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]] :: decimal(32, 4)[]
--   , array[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]] :: decimal(32, 4)[]
--   )
-- select 
--   sm_sc.fv_opr_mod_nega_py
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]] :: decimal(32, 4)[]
--   , array[[[[1.2,2.3,3.4],[0.3,0.4,0.7]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]],[[[1.6,2.7,3.4],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[1.4,2.2,0.8]]]] :: decimal(32, 4)[]
--   )

-- select 
--   sm_sc.fv_opr_mod_nega_py
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5])  :: decimal(32, 4)[]
--   , sm_sc.fv_new_rand(array[   1, 4, 5])  :: decimal(32, 4)[]
--   )


-- select sm_sc.fv_opr_mod_nega_py(array[array[12.3, 25.1], array[2.56, 3.25]] :: decimal(32, 4)[], 8.8)
-- select sm_sc.fv_opr_mod_nega_py(array[]::decimal(32, 4)[], 8.8)
-- select sm_sc.fv_opr_mod_nega_py(array[]::decimal(32, 4)[], null)
-- select sm_sc.fv_opr_mod_nega_py(array[1.2, 2.3]::decimal(32, 4)[], 8.8)
-- select sm_sc.fv_opr_mod_nega_py(array[array[], array []]::decimal(32, 4)[], 8.8)
-- select sm_sc.fv_opr_mod_nega_py(array[1.2, 2.3]::decimal(32, 4)[], null::decimal(32, 4))
-- select 
--   sm_sc.fv_opr_mod_nega_py
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]] :: decimal(32, 4)[]
--   , 2.2
--   )
-- select 
--   sm_sc.fv_opr_mod_nega_py
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]] :: decimal(32, 4)[]
--   , 2.2
--   )


-- select sm_sc.fv_opr_mod_nega_py(8.8, array[array[12.3, 25.1], array[2.56, 3.25]] :: decimal(32, 4)[])
-- select sm_sc.fv_opr_mod_nega_py(8.8, array[]::decimal(32, 4)[] )
-- select sm_sc.fv_opr_mod_nega_py(null, array[]::decimal(32, 4)[])
-- select sm_sc.fv_opr_mod_nega_py(8.8, array[1.2, 2.3]::decimal(32, 4)[] )
-- select sm_sc.fv_opr_mod_nega_py(8.8, array[array[], array []]::decimal(32, 4)[])
-- select sm_sc.fv_opr_mod_nega_py(null::decimal(32, 4), array[1.2, 2.3]::decimal(32, 4)[] )
-- select 
--   sm_sc.fv_opr_mod_nega_py
--   (
--     2.2
--   , array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]] :: decimal(32, 4)[]
--   )
-- select 
--   sm_sc.fv_opr_mod_nega_py
--   (
--     2.2
--   , array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]] :: decimal(32, 4)[]
--   )

-- ---------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_mod_nega_py(bigint[], bigint[]);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     bigint[]    ,
  i_right    bigint[]
)
returns bigint[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mod_nega_py(bigint[], bigint);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     bigint[]    ,
  i_right    bigint
)
returns bigint[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mod_nega_py(bigint, bigint[]);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     bigint    ,
  i_right    bigint[]
)
returns bigint[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- ---------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_mod_nega_py(int[], int[]);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     int[]    ,
  i_right    int[]
)
returns int[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mod_nega_py(int[], int);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     int[]    ,
  i_right    int
)
returns int[]
as
$$
  import numpy as np
  if i_left is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_mod_nega_py(int, int[]);
create or replace function sm_sc.fv_opr_mod_nega_py
(
  i_left     int    ,
  i_right    int[]
)
returns int[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    v_mod = np.array(i_left) % np.array(i_right)
    return (v_mod - (np.greater(np.sign(v_mod), 0.0) * np.abs(i_right))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select
--   sm_sc.fv_opr_mod_nega_py(array[[12,9,18]],array[[3,3,2]]::bigint[])
-- , sm_sc.fv_opr_mod_nega_py(array[[12,9,18]],array[[3,3,2]]::int[])
-- , sm_sc.fv_opr_mod_nega_py(              12,array[[3,3,2]]::bigint[])
-- , sm_sc.fv_opr_mod_nega_py(array[[12,9,18]],             3::bigint)
-- , sm_sc.fv_opr_mod_nega_py(              12,array[[3,3,2]]::   int[])
-- , sm_sc.fv_opr_mod_nega_py(array[[12,9,18]],             3::   int)