-- drop function if exists sm_sc.fv_opr_log_py(float[], float[]);
create or replace function sm_sc.fv_opr_log_py
(
  i_left     float[]    ,
  i_right    float[]
)
returns float[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    return (np.log(np.array(i_right)) / np.log(np.array(i_left))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_log_py(decimal[], decimal[]);
create or replace function sm_sc.fv_opr_log_py
(
  i_left     decimal[]    ,
  i_right    decimal[]
)
returns decimal[]
as
$$
  import numpy as np
  if i_left is None or i_right is None :
    return None
  else :
    return (np.log(np.array(i_right).astype(float)) / np.log(np.array(i_left).astype(float))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_log_py(float[], float);
create or replace function sm_sc.fv_opr_log_py
(
  i_left     float[]    ,
  i_right    float
)
returns float[]
as
$$
  import numpy as np 
  if i_left is None :
    return None
  else :
    return (np.log(np.array(i_right)) / np.log(np.array(i_left))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_log_py(decimal[], decimal);
create or replace function sm_sc.fv_opr_log_py
(
  i_left     decimal[]    ,
  i_right    decimal
)
returns decimal[]
as
$$
  import numpy as np 
  if i_left is None :
    return None
  else :
    return (np.log(np.array(i_right).astype(float)) / np.log(np.array(i_left).astype(float))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_log_py(float, float[]);
create or replace function sm_sc.fv_opr_log_py
(
  i_left     float    ,
  i_right    float[]
)
returns float[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return (np.log(np.array(i_right)) / np.log(np.array(i_left))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- drop function if exists sm_sc.fv_opr_log_py(decimal, decimal[]);
create or replace function sm_sc.fv_opr_log_py
(
  i_left     decimal    ,
  i_right    decimal[]
)
returns decimal[]
as
$$
  import numpy as np
  if i_right is None :
    return None
  else :
    return (np.log(np.array(i_right).astype(float)) / np.log(np.array(i_left).astype(float))).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_opr_log_py
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5]) 
--   , sm_sc.fv_new_rand(array[   1, 4, 5]) 
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[1.3, 52.3], array[5.6, 45.6]]
--   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[32.5], array[9.1]],
--     array[array[12.3, 2.3], array[45.6, 25.6]]
--   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[12.3, 32.3], array[45.6, 15.6]],
--     array[array[12.5], array[19.1]]
--   );
-- -- select sm_sc.fv_opr_log_py
-- --   (
-- --     array[3.5, 9.1],
-- --     array[array[2.3, 12.3], array[45.6, 4.6]]
-- --   );
-- -- select sm_sc.fv_opr_log_py
-- --   (
-- --     array[array[12.3, 2.3], array[45.6, 5.6]],
-- --     array[12.5, 19.1]
-- --   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[3.5, 9.1]],
--     array[array[2.3, 12.3], array[45.6, 4.6]]
--   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[12.5, 19.1]]
--   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_log_py
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_log_py(array[12.3], array[45.6, 5.6]);
-- select sm_sc.fv_opr_log_py(array[12.3], array[array[45.6, 5.6]]);
-- select sm_sc.fv_opr_log_py(array[array[12.3]], array[45.6, 5.6]);
-- select sm_sc.fv_opr_log_py(array[array[12.3]], array[array[45.6, 5.6]]);
-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_log_py
--   (
--     array[[[1.1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   , array[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[0.5,1.7,0.8],[2.3,0.4,2.7]]]
--   )
-- select 
--   sm_sc.fv_opr_log_py
--   (
--     array[[[[1.1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[0.5,1.7,0.8],[2.3,0.4,2.7]]]]
--   , array[[[[1.2,2.3,3.4],[0.3,0.4,0.7]],[[0.5,1.7,0.8],[2.3,0.4,2.7]]],[[[1.6,2.7,3.4],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[1.4,2.2,0.8]]]]
--   )

-- select sm_sc.fv_opr_log_py(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_log_py(array[]::float[], 8.8::float)
-- select sm_sc.fv_opr_log_py(array[array[], array []]::float[], 8.8::float)
-- select 
--   sm_sc.fv_opr_log_py
--   (
--     array[[[1.1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   , 2.2
--   )
-- select 
--   sm_sc.fv_opr_log_py
--   (
--     array[[[[1.1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[0.5,1.7,0.8],[2.3,0.4,2.7]]]]
--   , 2.2
--   )

-- select sm_sc.fv_opr_log_py(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_log_py(8.8, array[]::float[] )
-- select sm_sc.fv_opr_log_py(8.8, array[array[], array []]::float[])
-- select 
--   sm_sc.fv_opr_log_py
--   (
--     2.2
--   , array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   )
-- select 
--   sm_sc.fv_opr_log_py
--   (
--     2.2
--   , array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[0.5,1.7,0.8],[2.3,0.4,2.7]]]]
--   )
