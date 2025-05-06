-- drop function if exists sm_sc.fv_mx_ele_3d_2_2d(anyarray, int[2], int);
create or replace function sm_sc.fv_mx_ele_3d_2_2d
(
  i_array_3d        anyarray,  
  i_dims_from_to    int[2]  ,  -- 合并维度的原来两个维度。合并后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
                               -- 枚举项包括，[1, 2] === [2, 1]; [2, 3] === [3, 2]; [1, 3]; [3, 1];
  i_dim_pin_ele     int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
)
returns anyarray
as
$$
declare
  v_ret     i_array_3d%type;
  v_cur_y   int            ;
  v_cur_x   int            ;
  v_cur_x3  int            ;

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
    v_ret := array_fill(i_array_3d[0], array[array_length(i_array_3d, 1) * array_length(i_array_3d, 2), array_length(i_array_3d, 3)]);
    if i_dim_pin_ele = 1
    then 
      for v_cur_x3 in 1 .. array_length(i_array_3d, 3)
      loop 
        for v_cur_x in 1 .. array_length(i_array_3d, 2)
        loop 
          v_ret[(v_cur_x - 1) * array_length(i_array_3d, 1) + 1 : v_cur_x * array_length(i_array_3d, 1)][v_cur_x3 : v_cur_x3]
            := i_array_3d[ : ][v_cur_x : v_cur_x][v_cur_x3 : v_cur_x3]
          ;
        end loop;
      end loop;
    elsif i_dim_pin_ele = 2
    then
      for v_cur_x3 in 1 .. array_length(i_array_3d, 3)
      loop 
        for v_cur_y in 1 .. array_length(i_array_3d, 1)
        loop 
          v_ret[(v_cur_y - 1) * array_length(i_array_3d, 2) + 1 : v_cur_y * array_length(i_array_3d, 2)][v_cur_x3 : v_cur_x3]
            := i_array_3d[v_cur_y : v_cur_y][ : ][v_cur_x3 : v_cur_x3]
          ;
        end loop;
      end loop;
    end if;
  elsif i_dims_from_to = array[1, 3]
  then
    v_ret := array_fill(i_array_3d[0], array[array_length(i_array_3d, 2), array_length(i_array_3d, 1) * array_length(i_array_3d, 3)]);
    if i_dim_pin_ele = 1
    then 
      for v_cur_x in 1 .. array_length(i_array_3d, 2)
      loop 
        for v_cur_x3 in 1 .. array_length(i_array_3d, 3)
        loop 
          v_ret[v_cur_x : v_cur_x][(v_cur_x3 - 1) * array_length(i_array_3d, 1) + 1 : v_cur_x3 * array_length(i_array_3d, 1)] 
            := i_array_3d[ : ][v_cur_x : v_cur_x][v_cur_x3 : v_cur_x3]
          ;
        end loop;
      end loop;
    elsif i_dim_pin_ele = 3
    then      
      for v_cur_x in 1 .. array_length(i_array_3d, 2)
      loop 
        for v_cur_y in 1 .. array_length(i_array_3d, 1)
        loop 
          v_ret[v_cur_x : v_cur_x][(v_cur_y - 1) * array_length(i_array_3d, 3) + 1 : v_cur_y * array_length(i_array_3d, 3)]
            := i_array_3d[v_cur_y : v_cur_y][v_cur_x : v_cur_x][ : ]
          ;
        end loop;
      end loop;
    end if;
  elsif i_dims_from_to = array[3, 1]
  then
    v_ret := array_fill(i_array_3d[0], array[array_length(i_array_3d, 1) * array_length(i_array_3d, 3), array_length(i_array_3d, 2)]);
    if i_dim_pin_ele = 1
    then 
      for v_cur_x in 1 .. array_length(i_array_3d, 2)
      loop 
        for v_cur_x3 in 1 .. array_length(i_array_3d, 3)
        loop 
          v_ret[(v_cur_x3 - 1) * array_length(i_array_3d, 1) + 1 : v_cur_x3 * array_length(i_array_3d, 1)][v_cur_x : v_cur_x]
            := i_array_3d[ : ][v_cur_x : v_cur_x][v_cur_x3 : v_cur_x3]
          ;
        end loop;
      end loop;
    elsif i_dim_pin_ele = 3
    then      
      for v_cur_x in 1 .. array_length(i_array_3d, 2)
      loop 
        for v_cur_y in 1 .. array_length(i_array_3d, 1)
        loop 
          v_ret[(v_cur_y - 1) * array_length(i_array_3d, 3) + 1 : v_cur_y * array_length(i_array_3d, 3)][v_cur_x : v_cur_x]
            := i_array_3d[v_cur_y : v_cur_y][v_cur_x : v_cur_x][ : ]
          ;
        end loop;
      end loop;
    end if;
  elsif i_dims_from_to in (array[2, 3], array[3, 2])
  then
    v_ret := array_fill(i_array_3d[0], array[array_length(i_array_3d, 1), array_length(i_array_3d, 2) * array_length(i_array_3d, 3)]);
    if i_dim_pin_ele = 2
    then 
      for v_cur_y in 1 .. array_length(i_array_3d, 1)
      loop 
        for v_cur_x3 in 1 .. array_length(i_array_3d, 3)
        loop 
          v_ret[v_cur_y : v_cur_y][(v_cur_x3 - 1) * array_length(i_array_3d, 2) + 1 : v_cur_x3 * array_length(i_array_3d, 2)] 
            := i_array_3d[v_cur_y : v_cur_y][ : ][v_cur_x3 : v_cur_x3]
          ;
        end loop;
      end loop;
    elsif i_dim_pin_ele = 3
    then
      for v_cur_y in 1 .. array_length(i_array_3d, 1)
      loop 
        for v_cur_x in 1 .. array_length(i_array_3d, 2)
        loop 
          v_ret[v_cur_y : v_cur_y][(v_cur_x - 1) * array_length(i_array_3d, 3) + 1 : v_cur_x * array_length(i_array_3d, 3)]
            := i_array_3d[v_cur_y : v_cur_y][v_cur_x : v_cur_x][ : ]
          ;
        end loop;
      end loop;
    end if;
  end if;
  return v_ret; 
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
--         [1, 2, 3, 4]
--       , [5, 6, 7, 8]
--       , [9, 10, 11, 12]
--       ]
--     , [
--         [21, 22, 23, 24]
--       , [25, 26, 27, 28]
--       , [29, 30, 31, 32]
--       ]
--     ]
--     as a_arr
-- )
-- select 
--   a_dims_from_to, a_dim_pin_ele,
--   sm_sc.fv_mx_ele_3d_2_2d(a_arr, a_dims_from_to, a_dim_pin_ele) as a_out
-- from cte_arr
--   , (
--                 select array[1, 2]  
--       union all select array[2, 3] 
--       union all select array[2, 1]  
--       union all select array[3, 2] 
--       union all select array[1, 3] 
--       union all select array[3, 1]
--     ) tb_a_dims_from_to(a_dims_from_to)
--   , generate_series(1, 3) tb_a_dim_pin_ele(a_dim_pin_ele)
-- where a_dim_pin_ele = any(a_dims_from_to)
-- order by least(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dims_from_to[1]
--   , greatest(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dim_pin_ele