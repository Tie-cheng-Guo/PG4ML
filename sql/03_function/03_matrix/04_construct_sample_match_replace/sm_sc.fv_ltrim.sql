-- drop function if exists sm_sc.fv_ltrim(anyarray, anyelement);
create or replace function sm_sc.fv_ltrim
(
  i_array               anyarray,
  i_trim_element        anyelement
)
returns anyarray
as
$$
declare -- here
  v_x_cur                 int  ;
  v_y_cur                 int  ;
  v_x3_cur                int  ;
  v_x4_cur                int  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;

  -- ([][])
  if array_ndims(i_array) =  2
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop 
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop 
        if i_array[v_y_cur][v_x_cur] <> i_trim_element
        then 
          exit;
        else 
          i_array[v_y_cur][v_x_cur] = null;
        end if;
      end loop;
    end loop;
    return i_array;

  -- []
  elsif array_ndims(i_array) = 1
  then
    for v_x_cur in 1 .. array_length(i_array, 1)
    loop 
      if i_array[v_x_cur] <> i_trim_element
      then 
        exit;
      else 
        i_array[v_x_cur] = null;
      end if;
    end loop;
    return i_array;

  -- ([][][])
  elsif array_ndims(i_array) =  3
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop 
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop 
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop 
          if i_array[v_y_cur][v_x_cur][v_x3_cur] <> i_trim_element
          then 
            exit;
          else 
            i_array[v_y_cur][v_x_cur][v_x3_cur] := null;
          end if;
        end loop;
      end loop;
    end loop;
    return i_array;

  -- ([][][][])
  elsif array_ndims(i_array) =  4
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop 
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop 
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop 
          for v_x4_cur in 1 .. array_length(i_array, 4)
          loop 
            if i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] <> i_trim_element
            then 
              exit;
            else 
              i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] := null;
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
-- select sm_sc.fv_ltrim(array[[0,1,2,3,4,5], [0,0,1,2,0,4], [0,0,0,1,2,3], [0,0,0,0,1,2], [0,0,1,0,0,3]], 0)
-- select sm_sc.fv_ltrim(array[0,1,2,3,4,5], 0)