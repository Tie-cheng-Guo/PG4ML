-- py 版本的矩阵乘法
-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com

-- -- 需要安装扩展
--   create extension plpython3u;
-- --   create extension pltclu;  -- or pltcl

-- drop function if exists sm_sc.fv_mx_ele_3d_2_2d_py(float[], int[], int);
create or replace function sm_sc.fv_mx_ele_3d_2_2d_py
(
  i_array_3d        float[]  ,
  i_dims_from_to    int[2]  ,  -- 合并维度的原来两个维度。合并后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
                               -- 枚举项包括，[1, 2] === [2, 1]; [2, 3] === [3, 2]; [1, 3]; [3, 1];
  i_dim_pin_ele     int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
)
returns float[]
as
$$
-- declare
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array_3d) <> 3
    then 
      raise exception 'ndims should be 3.';
    end if;
    
    if i_dim_pin_ele <> all(i_dims_from_to)
    then 
      raise exception 'the pin_ele dim must be one of from_to dims.';
    end if;
    
    if i_dims_from_to[1] not between 1 and 3 
      or i_dims_from_to[2] not between 1 and 3
      or i_dims_from_to[1] = i_dims_from_to[2]
    then 
      raise exception 'unsupport this i_dims_from_to.';
    end if;
  end if;

  if i_array_3d is null 
  then 
    return null;
  end if;  
  
  if i_dims_from_to in (array[1, 2], array[2, 1])
  then
    if i_dim_pin_ele = 1
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d |^~| array[1, 2]
        , array
          [
            array_length(i_array_3d, 1) * array_length(i_array_3d, 2)
          , array_length(i_array_3d, 3)
          ]
        )
      ;
      
    elsif i_dim_pin_ele = 2
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d
        , array
          [
            array_length(i_array_3d, 1) * array_length(i_array_3d, 2)
          , array_length(i_array_3d, 3)
          ]
          )
      ;
      
    end if;
  elsif i_dims_from_to = array[1, 3]
  then
    if i_dim_pin_ele = 1
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d |^~| array[1, 2] |^~| array[2, 3]
        , array
          [
            array_length(i_array_3d, 2)
          , array_length(i_array_3d, 1) * array_length(i_array_3d, 3)
          ]
        )
      ;      
      
    elsif i_dim_pin_ele = 3
    then     
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d |^~| array[1, 2]
        , array
          [
            array_length(i_array_3d, 2)
          , array_length(i_array_3d, 1) * array_length(i_array_3d, 3)
          ]
        )
      ;       
      
      
    end if;
  elsif i_dims_from_to = array[3, 1]
  then
    if i_dim_pin_ele = 1
    then     
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d |^~| array[3, 2] |^~| array[2, 1]
        , array
          [
            array_length(i_array_3d, 1) * array_length(i_array_3d, 3)
          , array_length(i_array_3d, 2)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 3
    then      
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d |^~| array[3, 2]
        , array
          [
            array_length(i_array_3d, 1) * array_length(i_array_3d, 3)
          , array_length(i_array_3d, 2)
          ]
        )
      ;   
      
    end if;
  elsif i_dims_from_to in (array[2, 3], array[3, 2])
  then
    if i_dim_pin_ele = 2
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d |^~| array[2, 3]
        , array
          [
            array_length(i_array_3d, 1)
          , array_length(i_array_3d, 2) * array_length(i_array_3d, 3)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 3
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_3d
        , array
          [
            array_length(i_array_3d, 1)
          , array_length(i_array_3d, 2) * array_length(i_array_3d, 3)
          ]
        )
      ;       
      
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
;

-- select 
--   sm_sc.fv_mx_ele_3d_2_2d_py
--   (
--     array[array[1, 2, 3], array[1, 2, 3]] :: float[],
--     array[array[1, 2], array[3, 1], array[2, 3]] :: float[]
--   )

-- with 
-- cte_arr as 
-- (
--   -- select (sm_sc.fv_new_rand(array[2,3,5]) :: decimal[] ~=` 3) :: float[] as a_arr
--   select 
--     array
--     [[[ 0, 1, 2, 3, 4]
--      ,[ 5, 6, 7, 8, 9]
--      ,[10,11,12,13,14]]
--     ,
--      [[15,16,17,18,19]
--      ,[20,21,22,23,24]
--      ,[25,26,27,28,29]]] :: float[]
--     as a_arr
-- ),
-- cte_dims as 
-- (
--   select array[1,2] as a_dims union all
--   select array[2,1]           union all
--   select array[1,3]           union all
--   select array[3,1]           union all
--   select array[2,3]           union all
--   select array[3,2]
-- ),
-- cte_pin as 
-- (
--   select 1 as a_pin union all select 2
-- )
-- select a_dims, a_pin
-- , sm_sc.fv_mx_ele_3d_2_2d_py(a_arr, a_dims, a_dims[a_pin]) = sm_sc.fv_mx_ele_3d_2_2d(a_arr, a_dims, a_dims[a_pin])
-- , sm_sc.fv_mx_ele_3d_2_2d_py(a_arr, a_dims, a_dims[a_pin])
-- , sm_sc.fv_mx_ele_3d_2_2d(a_arr, a_dims, a_dims[a_pin])
-- from cte_arr, cte_dims, cte_pin
-- order by a_dims, a_pin