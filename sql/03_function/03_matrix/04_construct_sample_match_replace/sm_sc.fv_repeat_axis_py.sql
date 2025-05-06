-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_repeat_axis_py(float[], int, int);
create or replace function sm_sc.fv_repeat_axis_py
(
  i_arr             float[]
, i_dim             int
, i_repeat          int
)
returns float[]
as
$$
  from numpy import array
  return array(i_arr).repeat(i_repeat, i_dim if i_dim < 0 else i_dim - 1).tolist()
$$
language plpython3u stable
parallel safe
;

-- drop function if exists sm_sc.fv_repeat_axis_py(int[], int, int);
create or replace function sm_sc.fv_repeat_axis_py
(
  i_arr             int[]
, i_dim             int
, i_repeat          int
)
returns int[]
as
$$
  from numpy import array
  return array(i_arr).repeat(i_repeat, i_dim if i_dim < 0 else i_dim - 1).tolist()
$$
language plpython3u stable
parallel safe
;

-- select 
--   sm_sc.fv_repeat_axis_py
--   (
--     array[[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]
--   , 1
--   , 3
--   )

-- -----------------------------------------------------------------------------------------------------------------------
-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_repeat_axis_py(float[], int[], int[]);
create or replace function sm_sc.fv_repeat_axis_py
(
  i_arr              float[]
, i_dims             int[]   -- 规约: 维度顺序从 1 开始递增，从 -1 开始递减，不支持第 0 维度。
, i_repeats          int[]
)
returns float[]
as
$$
  from numpy import array
  if len(i_dims) == 1 :
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1).tolist()
  elif len(i_dims) == 2 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1).tolist()
  elif len(i_dims) == 3 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1) \
                       .repeat(i_repeats[2], i_dims[2] if i_dims[2] < 0 else i_dims[2] - 1).tolist()
  elif len(i_dims) == 4 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1) \
                       .repeat(i_repeats[2], i_dims[2] if i_dims[2] < 0 else i_dims[2] - 1) \
                       .repeat(i_repeats[3], i_dims[3] if i_dims[3] < 0 else i_dims[3] - 1).tolist()
  elif len(i_dims) == 5 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1) \
                       .repeat(i_repeats[2], i_dims[2] if i_dims[2] < 0 else i_dims[2] - 1) \
                       .repeat(i_repeats[3], i_dims[3] if i_dims[3] < 0 else i_dims[3] - 1) \
                       .repeat(i_repeats[4], i_dims[4] if i_dims[4] < 0 else i_dims[4] - 1).tolist()
$$
language plpython3u stable
parallel safe
;

-- drop function if exists sm_sc.fv_repeat_axis_py(int[], int[], int[]);
create or replace function sm_sc.fv_repeat_axis_py
(
  i_arr              int[]
, i_dims             int[]   -- 规约: 维度顺序从 1 开始递增，从 -1 开始递减，不支持第 0 维度。
, i_repeats          int[]
)
returns int[]
as
$$
  from numpy import array
  if len(i_dims) == 1 :
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1).tolist()
  if len(i_dims) == 2 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1).tolist()
  if len(i_dims) == 3 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1) \
                       .repeat(i_repeats[2], i_dims[2] if i_dims[2] < 0 else i_dims[2] - 1).tolist()
  if len(i_dims) == 4 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1) \
                       .repeat(i_repeats[2], i_dims[2] if i_dims[2] < 0 else i_dims[2] - 1) \
                       .repeat(i_repeats[3], i_dims[3] if i_dims[3] < 0 else i_dims[3] - 1).tolist()
  if len(i_dims) == 5 :                            
    return array(i_arr).repeat(i_repeats[0], i_dims[0] if i_dims[0] < 0 else i_dims[0] - 1) \
                       .repeat(i_repeats[1], i_dims[1] if i_dims[1] < 0 else i_dims[1] - 1) \
                       .repeat(i_repeats[2], i_dims[2] if i_dims[2] < 0 else i_dims[2] - 1) \
                       .repeat(i_repeats[3], i_dims[3] if i_dims[3] < 0 else i_dims[3] - 1) \
                       .repeat(i_repeats[4], i_dims[4] if i_dims[4] < 0 else i_dims[4] - 1).tolist()
$$
language plpython3u stable
parallel safe
;

-- select 
--   sm_sc.fv_repeat_axis_py
--   (
--     array[[[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]]
--   , array[1,0]
--   , array[2,3]
--   )