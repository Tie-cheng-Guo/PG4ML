-- drop function if exists sm_sc.fv_ele_replace(anyarray, anyarray, anyelement);
create or replace function sm_sc.fv_ele_replace
(
  i_array            anyarray,
  i_old_elements     anyarray,
  i_new_element      anyelement
)
returns anyarray
as
$$
declare -- here
  v_x_cur                 int  := 1  ;
  v_y_cur                 int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  -- pg 尚未支持 is not distinct from any(anyarray) 语法。
  v_if_null_old_element   boolean  := (select true from unnest(i_old_elements) tb_a(a_ele) where a_ele is null);
begin
  -- ele_replace(null :: float[][], float) = null :: float[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;

  -- ele_replace([][])
  if array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        if i_array[v_y_cur][v_x_cur] = any(i_old_elements) 
          or i_array[v_y_cur][v_x_cur] is null and v_if_null_old_element
        then
          i_array[v_y_cur][v_x_cur] := i_new_element;
        end if;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- ele_replace []
  elsif array_ndims(i_array) = 1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
        if i_array[v_y_cur] = any(i_old_elements)
          or i_array[v_y_cur] is null and v_if_null_old_element
        then
          i_array[v_y_cur] := i_new_element;
        end if;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- ele_replace [][][]
  elsif array_ndims(i_array) = 3
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop
          if i_array[v_y_cur][v_x_cur][v_x3_cur] = any(i_old_elements)
            or i_array[v_y_cur][v_x_cur][v_x3_cur] is null and v_if_null_old_element
          then
            i_array[v_y_cur][v_x_cur][v_x3_cur] := i_new_element;
          end if;
        end loop;    
      end loop;
    end loop;
    return i_array;
    
  -- ele_replace [][][][]
  elsif array_ndims(i_array) = 4
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_array, 4)
          loop
            if i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = any(i_old_elements)
              or i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] is null and v_if_null_old_element
            then
              i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] := i_new_element;
            end if;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_array;

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_ele_replace(array[array[12.3, 25.1], array[3.25, 6.1]], array[12.3, 3.25], 1.111)
-- select sm_sc.fv_ele_replace(array[[[12.3, 25.1], [3.25, 6.1]]], array[12.3, 3.25], 1.111)
-- select sm_sc.fv_ele_replace(array[[[[12.3, 25.1], [3.25, 6.1]]]], array[12.3, 3.25], 1.111)
-- select sm_sc.fv_ele_replace(array[12.3, 25.1, 28.33], array[25.1, 12.3], 2.222)
-- select sm_sc.fv_ele_replace(array[]::float[], array[25.1, 12.3], 2.222)
-- select sm_sc.fv_ele_replace(array[null, 25.1, 28.33], array[null, 12.3], 2.222) 
-- select sm_sc.fv_ele_replace(array[12.3, 25.1, 28.33], array[25.1, 12.3], null)   -- 相当于 slice_nullif
-- select sm_sc.fv_ele_replace(array[array[], array []]::float[], array[25.1, 12.3], 2.222)