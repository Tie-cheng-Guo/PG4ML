-- drop function if exists sm_sc.fv_opr_abs(anyarray);
create or replace function sm_sc.fv_opr_abs
(
  i_right     anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     i_right%type   := case array_ndims(i_right) when 2 then array_fill(i_right[0], array[array_length(i_right, 1), array_length(i_right, 2)]) when 1 then array_fill(null::float, array[array_length(i_right, 1)]) else null end;

begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- abs([][])
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := abs(i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- abs []
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := abs(i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- abs [][][]
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            abs(i_right[v_y_cur][v_x_cur][v_x3_cur])
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- abs [][][][]
  elsif array_ndims(i_right) = 4
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              abs(i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_abs(array[array[12.3, -25.1], array[-2.56, 3.25]])
-- select sm_sc.fv_opr_abs(array[12.3, -25.1, 28.33])
-- select sm_sc.fv_opr_abs(array[]::float[])
-- select sm_sc.fv_opr_abs(array[array[], array []]::float[])
-- select 
--   sm_sc.fv_opr_abs
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   )
-- select 
--   sm_sc.fv_opr_abs
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   )