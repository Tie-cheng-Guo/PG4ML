-- drop function if exists sm_sc.fv_atan(double precision[]);
create or replace function sm_sc.fv_atan
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

  -- atan([][])
  if array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        i_array[v_y_cur][v_x_cur] := atan(i_array[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- atan []
  elsif array_ndims(i_array) = 1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
      i_array[v_y_cur] := atan(i_array[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- atan([][][])
  elsif array_ndims(i_array) = 3
  then
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop
          i_array[v_y_cur][v_x_cur][v_x3_cur] = 
            atan(i_array[v_y_cur][v_x_cur][v_x3_cur])
          ;
        end loop;    
      end loop;
    end loop;
    return i_array;
    
  -- atan([][][][])
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
              atan(i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur])
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
-- select sm_sc.fv_atan
--   (
--     array[array[1, -1], array[1.0 :: float/ 2, 1.0 :: float/ 4], array['-Infinity', 'Infinity']]::double precision[]
--   )
-- ;
-- select sm_sc.fv_atan
--   (
--     array[1, -1, 1.0 :: float/ 2, 1.0 :: float/ 4, '-Infinity', 'Infinity']::double precision[]
--   )
-- ;
-- select sm_sc.fv_atan
--   (
--     array[[[1, -1, 1.0 :: float/ 2, 1.0 :: float/ 4, '-Infinity', 'Infinity']]]::double precision[]
--   )
-- ;
-- select sm_sc.fv_atan
--   (
--     array[[[[1, -1, 1.0 :: float/ 2, 1.0 :: float/ 4, '-Infinity', 'Infinity']]]]::double precision[]
--   )
-- ;