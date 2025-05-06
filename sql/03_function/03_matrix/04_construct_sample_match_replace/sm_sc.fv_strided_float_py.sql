-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_strided_float_py(float[], int[], int[]);
create or replace function sm_sc.fv_strided_float_py
(
  i_arr            float[]
, i_shape          int[]   -- 如果是要获得 2d-卷积 的滑动窗口驻留痕迹，那么返回卷积块儿矩阵的维数，比 i_arr 的维数多 2
, i_ele_strides    int[]   -- 以二维 i_arr[i_arr_heigh][i_arr_width], 
                           -- 窗口高宽 [i_window_height, i_window_width]
                           -- 步长高宽 = [i_stride_height, i_stride_width]，
                           -- 间隔卷积的间隔(空洞)高宽 = [i_hole_heigh, i_hole_width] 为例子，
                           -- 以 float 元素类型长度为单位：
                           -- i_ele_strides int[4] = 
                           --   array
                           --   [
                           --     i_stride_height * i_arr_width
                           --   , i_stride_width
                           --   , (1 + i_hole_heigh) * i_arr_width
                           --   , 1 + i_hole_width
                           --   ]
)
returns float[]
as
$$
  from numpy.lib.stride_tricks import as_strided
  from numpy import array

  v_len_ele = array(i_arr[0]).dtype.itemsize    # python float64 dtype.itemsize = 8
  return as_strided(array(i_arr), shape = i_shape, strides = v_len_ele * array(i_ele_strides)).tolist()
$$
language plpython3u stable
parallel safe
;

-- select 
--   sm_sc.fv_strided_float_py
--   (
--     array[[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]  -- sm_sc.fv_new_rand(array[5, 7])
--   , array[2, 2, 3, 3]                                      -- array[3, 5, 3, 3]
--   , array[4, 1, 4, 1]
--   )