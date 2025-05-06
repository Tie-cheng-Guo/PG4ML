-- drop function if exists sm_sc.fv_mx_ele_4d_2_3d_py(float[], int[2], int);
create or replace function sm_sc.fv_mx_ele_4d_2_3d_py
(
  i_array_4d        float[],  
  i_dims_from_to    int[2]  ,  -- 合并维度的原来两个维度。合并后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
                               -- 枚举项包括，[1, 2] === [2, 1]; [2, 3] === [3, 2]; [3, 4] === [4, 3]; [1, 3]; [3, 1]; [1, 4]; [4, 1]; [2, 4]; [4, 2]
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
    if array_ndims(i_array_4d) <> 4
    then 
      raise exception 'ndims should be 4.';
    end if;
    
    if i_dim_pin_ele <> all(i_dims_from_to)
    then 
      raise exception 'the pin_ele dim must be one of from_to dims.';
    end if;
    
    if i_dims_from_to[1] not between 1 and 4 
      or i_dims_from_to[2] not between 1 and 4
      or i_dims_from_to[1] = i_dims_from_to[2]
    then 
      raise exception 'unsupport this i_dims_from_to.';
    end if;
  end if;

  if i_array_4d is null 
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
          i_array_4d |^~| array[1, 2]
        , array
          [
            array_length(i_array_4d, 1) * array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3)
          , array_length(i_array_4d, 4)
          ]
          )
      ;
      
    elsif i_dim_pin_ele = 2
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d
        , array
          [
            array_length(i_array_4d, 1) * array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3)
          , array_length(i_array_4d, 4)
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
          i_array_4d |^~| array[1, 2] |^~| array[2, 3]
        , array
          [
            array_length(i_array_4d, 2)
          , array_length(i_array_4d, 1) * array_length(i_array_4d, 3)
          , array_length(i_array_4d, 4)
          ]
        )
      ;      
      
    elsif i_dim_pin_ele = 3
    then      
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[1, 2]
        , array
          [
            array_length(i_array_4d, 2)
          , array_length(i_array_4d, 1) * array_length(i_array_4d, 3)
          , array_length(i_array_4d, 4)
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
          i_array_4d |^~| array[3, 2] |^~| array[2, 1]
        , array
          [
            array_length(i_array_4d, 1) * array_length(i_array_4d, 3)
          , array_length(i_array_4d, 2)
          , array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 3
    then      
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[2, 3]
        , array
          [
            array_length(i_array_4d, 1) * array_length(i_array_4d, 3)
          , array_length(i_array_4d, 2)
          , array_length(i_array_4d, 4)
          ]
        )
      ;   
      
    end if;
  elsif i_dims_from_to = array[1, 4]
  then
    if i_dim_pin_ele = 1
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[1, 2] |^~| array[2, 3] |^~| array[3, 4]
        , array
          [
            array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3)
          , array_length(i_array_4d, 1) * array_length(i_array_4d, 4)
          ]
        )
      ;      
      
    elsif i_dim_pin_ele = 4
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[1, 2] |^~| array[2, 3]
        , array
          [
            array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3)
          , array_length(i_array_4d, 1) * array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    end if;
  elsif i_dims_from_to = array[4, 1]
  then
    if i_dim_pin_ele = 1
    then  
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[4, 3] |^~| array[3, 2] |^~| array[2, 1]
        , array
          [
            array_length(i_array_4d, 1) * array_length(i_array_4d, 4)
          , array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 4
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[4, 3] |^~| array[3, 2]
        , array
          [
            array_length(i_array_4d, 1) * array_length(i_array_4d, 4)
          , array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3)
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
          i_array_4d |^~| array[2, 3]
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 2) * array_length(i_array_4d, 3)
          , array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 3
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 2) * array_length(i_array_4d, 3)
          , array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    end if;
  elsif i_dims_from_to = array[2, 4]
  then
    if i_dim_pin_ele = 2
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[2, 3] |^~| array[3, 4]
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 3)
          , array_length(i_array_4d, 2) * array_length(i_array_4d, 4)
          ]
        )
      ;      
      
    elsif i_dim_pin_ele = 4
    then      
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[2, 3]
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 3)
          , array_length(i_array_4d, 2) * array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    end if;
  elsif i_dims_from_to = array[4, 2]
  then
    if i_dim_pin_ele = 2
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[4, 3] |^~| array[3, 2]
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 2) * array_length(i_array_4d, 4)
          , array_length(i_array_4d, 3)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 4
    then      
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[3, 4]
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 2) * array_length(i_array_4d, 4)
          , array_length(i_array_4d, 3)
          ]
        )
      ;   
      
    end if;
  elsif i_dims_from_to in (array[3, 4], array[4, 3])
  then
    if i_dim_pin_ele = 3
    then 
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d |^~| array[3, 4]
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3) * array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    elsif i_dim_pin_ele = 4
    then
      return 
        sm_sc.fv_opr_reshape_py
        (
          i_array_4d
        , array
          [
            array_length(i_array_4d, 1)
          , array_length(i_array_4d, 2)
          , array_length(i_array_4d, 3) * array_length(i_array_4d, 4)
          ]
        )
      ;       
      
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- with cte_arr as
-- (
--   select 
--     array
--     [
--       [
--         [
--           [1, 2, 3, 4]
--         , [5, 6, 7, 8]
--         , [9, 10, 11, 12]
--         ]
--       , [
--           [21, 22, 23, 24]
--         , [25, 26, 27, 28]
--         , [29, 30, 31, 32]
--         ]
--       ]
--     , [
--         [
--           [-1, -2, -3, -4]
--         , [-5, -6, -7, -8]
--         , [-9, -10, -11, -12]
--         ]
--       , [
--           [-21, -22, -23, -24]
--         , [-25, -26, -27, -28]
--         , [-29, -30, -31, -32]
--         ]
--       ]
--     ] as a_arr
-- )
-- select 
--   a_dims_from_to, a_dim_pin_ele,
--   sm_sc.fv_mx_ele_4d_2_3d_py(a_arr, a_dims_from_to, a_dim_pin_ele) as a_out
-- from cte_arr
--   , (
--                 select array[1, 2]  
--       union all select array[2, 3] 
--       union all select array[3, 4]
--       union all select array[2, 1]  
--       union all select array[3, 2] 
--       union all select array[4, 3]
--       union all select array[1, 3] 
--       union all select array[3, 1]
--       union all select array[1, 4]
--       union all select array[4, 1]
--       union all select array[2, 4]
--       union all select array[4, 2]
--     ) tb_a_dims_from_to(a_dims_from_to)
--   , generate_series(1, 4) tb_a_dim_pin_ele(a_dim_pin_ele)
-- where a_dim_pin_ele = any(a_dims_from_to)
-- order by least(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dims_from_to[1]
--   , greatest(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dim_pin_ele

-- with 
-- cte_arr as 
-- (
--   -- select (sm_sc.fv_new_rand(array[2,3,5]) :: decimal[] ~=` 3) :: float[] as a_arr
--   select 
--     array
--     [[[[  0,  1,  2,  3,  4,  5,  6]
--       ,[  7,  8,  9, 10, 11, 12, 13]
--       ,[ 14, 15, 16, 17, 18, 19, 20]
--       ,[ 21, 22, 23, 24, 25, 26, 27]
--       ,[ 28, 29, 30, 31, 32, 33, 34]]
--      ,[[ 35, 36, 37, 38, 39, 40, 41]
--       ,[ 42, 43, 44, 45, 46, 47, 48]
--       ,[ 49, 50, 51, 52, 53, 54, 55]
--       ,[ 56, 57, 58, 59, 60, 61, 62]
--       ,[ 63, 64, 65, 66, 67, 68, 69]]
--      ,[[ 70, 71, 72, 73, 74, 75, 76]
--       ,[ 77, 78, 79, 80, 81, 82, 83]
--       ,[ 84, 85, 86, 87, 88, 89, 90]
--       ,[ 91, 92, 93, 94, 95, 96, 97]
--       ,[ 98, 99,100,101,102,103,104]]]
--     ,[[[105,106,107,108,109,110,111]
--       ,[112,113,114,115,116,117,118]
--       ,[119,120,121,122,123,124,125]
--       ,[126,127,128,129,130,131,132]
--       ,[133,134,135,136,137,138,139]]
--      ,[[140,141,142,143,144,145,146]
--       ,[147,148,149,150,151,152,153]
--       ,[154,155,156,157,158,159,160]
--       ,[161,162,163,164,165,166,167]
--       ,[168,169,170,171,172,173,174]]
--      ,[[175,176,177,178,179,180,181]
--       ,[182,183,184,185,186,187,188]
--       ,[189,190,191,192,193,194,195]
--       ,[196,197,198,199,200,201,202]
--       ,[203,204,205,206,207,208,209]]]] :: float[]
--     as a_arr
-- ),
-- cte_dims as 
-- (
--   select array[1,2] as a_dims union all
--   select array[2,1]           union all
--   select array[1,3]           union all
--   select array[3,1]           union all
--   select array[1,4]           union all
--   select array[4,1]           union all
--   select array[2,3]           union all
--   select array[3,2]           union all
--   select array[2,4]           union all
--   select array[4,2]           union all
--   select array[3,4]           union all
--   select array[4,3]
-- ),
-- cte_pin as 
-- (
--   select 1 as a_pin union all select 2
-- )
-- select a_dims, a_pin
-- , sm_sc.fv_mx_ele_4d_2_3d_py(a_arr, a_dims, a_dims[a_pin]) = sm_sc.fv_mx_ele_4d_2_3d(a_arr, a_dims, a_dims[a_pin])
-- , sm_sc.fv_mx_ele_4d_2_3d_py(a_arr, a_dims, a_dims[a_pin])
-- , sm_sc.fv_mx_ele_4d_2_3d(a_arr, a_dims, a_dims[a_pin])
-- from cte_arr, cte_dims, cte_pin
-- order by a_dims, a_pin