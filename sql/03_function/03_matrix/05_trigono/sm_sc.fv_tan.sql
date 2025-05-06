-- drop function if exists sm_sc.fv_tan(double precision[]);
create or replace function sm_sc.fv_tan
(
  i_array     double precision[]
)
returns double precision[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- fn(null :: double precision[][], double precision) = null :: double precision[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;

  -- tan([][])
  if array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        i_array[v_y_cur][v_x_cur] := tan(i_array[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- tan []
  elsif array_ndims(i_array) = 1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
      i_array[v_y_cur] := tan(i_array[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- tan([][][])
  elsif array_ndims(i_array) = 3
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop
          i_array[v_y_cur][v_x_cur][v_x3_cur] = 
            tan(i_array[v_y_cur][v_x_cur][v_x3_cur])
          ;
        end loop;    
      end loop;
    end loop;
    return i_array;
    
  -- tan([][][][])
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
            i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              tan(i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur])
            ;
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
-- -- set search_path to sm_sc;
-- select sm_sc.fv_tan
--   (
--     array[array[pi(), -pi()], array[pi() / 2, pi() / 4]]::double precision[]
--   )
-- ;
-- select sm_sc.fv_tan
--   (
--     array[pi(), -pi(), pi() / 2, pi() / 4]::double precision[]
--   )
-- ;
-- select sm_sc.fv_tan
--   (
--     array[[[pi(), -pi(), pi() / 2, pi() / 4]]]::double precision[]
--   )
-- ;
-- select sm_sc.fv_tan
--   (
--     array[[[[pi(), -pi(), pi() / 2, pi() / 4]]]]::double precision[]
--   )
-- ;