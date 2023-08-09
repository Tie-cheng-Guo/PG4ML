-- drop function if exists sm_sc.fv_opr_exp(anyarray);
create or replace function sm_sc.fv_opr_exp
(
  i_right     anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- exp([][])
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := case when i_right[v_y_cur][v_x_cur] = '-inf' :: float then 0.0 else exp(i_right[v_y_cur][v_x_cur]) end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- exp []
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := case when i_right[v_y_cur] = '-inf' :: float then 0.0 else exp(i_right[v_y_cur]) end;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_exp(array[array[12.3, 25.1], array[2.56, '-inf' :: float]])
-- select sm_sc.fv_opr_exp(array[12.3, 25.1, 28.33, '-inf' :: float])
-- select sm_sc.fv_opr_exp(array[]::float[])
-- select sm_sc.fv_opr_exp(array[array[], array []]::float[])