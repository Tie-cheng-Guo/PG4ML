-- drop function if exists sm_sc.fv_opr_abs(anyarray);
create or replace function sm_sc.fv_opr_abs
(
  i_right     anyarray
)
returns float[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     float[]   := case array_ndims(i_right) when 2 then array_fill(null::float, array[array_length(i_right, 1), array_length(i_right, 2)]) when 1 then array_fill(null::float, array[array_length(i_right, 1)]) else null::float[] end;

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

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
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