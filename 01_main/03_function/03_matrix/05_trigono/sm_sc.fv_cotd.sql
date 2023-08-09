-- drop function if exists sm_sc.fv_cotd(double precision[]);
create or replace function sm_sc.fv_cotd
(
  i_array     double precision[]
)
returns double precision[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     double precision[] := case array_ndims(i_array) when 2 then array_fill(null::double precision, array[array_length(i_array, 1), array_length(i_array, 2)]) when 1 then array_fill(null::double precision, array[array_length(i_array, 1)]) else null::double precision[] end;
begin
  -- fn(null :: double precision[][], double precision) = null :: double precision[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;

  -- cotd([][])
  if array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := cotd(i_array[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- cotd []
  elsif array_ndims(i_array) = 1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
      v_ret[v_y_cur] := cotd(i_array[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_cotd
--   (
--     array[array[180, -180], array[90, 45]]::double precision[]
--   )
-- ;
-- select sm_sc.fv_cotd
--   (
--     array[180, -180, 90, 45]::double precision[]
--   )
-- ;