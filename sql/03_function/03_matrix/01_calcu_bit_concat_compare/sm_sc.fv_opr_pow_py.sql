-- drop function if exists sm_sc.fv_opr_pow_py(float[], float[]);
create or replace function sm_sc.fv_opr_pow_py
(
  i_left     float[]    ,
  i_right    float[]
)
returns float[]
as
$$
  from numpy import array as arr  
  if i_left is None or i_right is None :
    return None
  else :
    return (arr(i_left) ** arr(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_pow_py(float[], float);
create or replace function sm_sc.fv_opr_pow_py
(
  i_left     float[]    ,
  i_right    float
)
returns float[]
as
$$
  from numpy import array as arr  
  if i_left is None :
    return None
  else :
    return (arr(i_left) ** i_right).tolist()
$$
language plpython3u stable
parallel safe
cost 100;


-- drop function if exists sm_sc.fv_opr_pow_py(float, float[]);
create or replace function sm_sc.fv_opr_pow_py
(
  i_left     float    ,
  i_right    float[]
)
returns float[]
as
$$
  from numpy import array as arr 
  if i_right is None :
    return None
  else :
    return (i_left ** arr(i_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_opr_pow_py
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5]) 
--   , sm_sc.fv_new_rand(array[   1, 4, 5]) 
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[32.5], array[-9.1]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[12.5], array[-19.1]]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[32.5, -9.1],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[12.5, -19.1]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[32.5, -9.1]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[12.5, -19.1]]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_pow_py
--   (
--     array[1.2, 2.3]::float[],
--     array[2.1, 3.2]::float[]
--   );
-- select sm_sc.fv_opr_pow_py(array[1], array[1,2,3]);
-- select sm_sc.fv_opr_pow_py(array[1], array[array[1,2,3]]);
-- select sm_sc.fv_opr_pow_py(array[array[1]], array[1,2,3]);
-- select sm_sc.fv_opr_pow_py(array[array[1]], array[array[1,2,3]]);

-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_pow_py
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   , array[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]
--   )
-- select 
--   sm_sc.fv_opr_pow_py
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   , array[[[[1.2,2.3,3.4],[0.3,0.4,0.7]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]],[[[1.6,2.7,3.4],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[1.4,2.2,0.8]]]]
--   )

-- select 
--   sm_sc.fv_opr_pow_py
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5]) 
--   , sm_sc.fv_new_rand(array[   1, 4, 5]) 
--   )


-- select sm_sc.fv_opr_pow_py(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_pow_py(array[]::float[], 8.8)
-- select sm_sc.fv_opr_pow_py(array[]::float[], null)
-- select sm_sc.fv_opr_pow_py(array[1.2, 2.3]::float[], 8.8)
-- select sm_sc.fv_opr_pow_py(array[array[], array []]::float[], 8.8)
-- select sm_sc.fv_opr_pow_py(array[1.2, 2.3]::float[], null::float)
-- select 
--   sm_sc.fv_opr_pow_py
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   , 2.2
--   )
-- select 
--   sm_sc.fv_opr_pow_py
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   , 2.2
--   )


-- select sm_sc.fv_opr_pow_py(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_pow_py(8.8, array[]::float[] )
-- select sm_sc.fv_opr_pow_py(null, array[]::float[])
-- select sm_sc.fv_opr_pow_py(8.8, array[1.2, 2.3]::float[] )
-- select sm_sc.fv_opr_pow_py(8.8, array[array[], array []]::float[])
-- select sm_sc.fv_opr_pow_py(null::float, array[1.2, 2.3]::float[] )
-- select 
--   sm_sc.fv_opr_pow_py
--   (
--     2.2
--   , array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   )
-- select 
--   sm_sc.fv_opr_pow_py
--   (
--     2.2
--   , array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   )