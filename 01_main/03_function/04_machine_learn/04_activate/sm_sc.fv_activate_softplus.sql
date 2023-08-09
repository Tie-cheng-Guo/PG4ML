-- drop function if exists sm_sc.fv_activate_softplus(float[]);
create or replace function sm_sc.fv_activate_softplus
(
  i_array     float[]
)
returns float[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;

  -- sm_sc.fv_softplus([][], )
  if array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        i_array[v_y_cur][v_x_cur] := sm_sc.fv_softplus(i_array[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  -- sm_sc.fv_softplus [],
  elsif array_ndims(i_array) = 1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
      i_array[v_y_cur] := sm_sc.fv_softplus(i_array[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_array;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_activate_softplus(array[array[1.0 :: float, -2.0], array[3.0, 4.0]])
-- select sm_sc.fv_activate_softplus(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_activate_softplus(array[]::float[])
-- select sm_sc.fv_activate_softplus(array[array[], array []]::float[])