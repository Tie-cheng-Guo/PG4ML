-- drop function if exists sm_sc.fv_activate_swish(float[]);
create or replace function sm_sc.fv_activate_swish
(
  i_array     float[]
)
returns float[]
as
$$
-- -- declare -- here
-- --   v_x_cur   int  := 1  ;
-- --   v_y_cur   int  := 1  ;
begin
-- --   -- log(null :: float[][], float) = null :: float[][]
-- --   if array_length(i_array, array_ndims(i_array)) is null
-- --   then 
-- --     return i_array;
-- --   end if;
-- -- 
-- --   -- sm_sc.fv_swish([][], )
-- --   if array_ndims(i_array) =  2
-- --   then
-- --     while v_y_cur <= array_length(i_array, 1)
-- --     loop 
-- --       v_x_cur := 1  ;
-- --       while v_x_cur <= array_length(i_array, 2)
-- --       loop
-- --         i_array[v_y_cur][v_x_cur] := sm_sc.fv_swish(i_array[v_y_cur][v_x_cur]);
-- --         v_x_cur := v_x_cur + 1;
-- --       end loop;
-- --       v_y_cur := v_y_cur + 1;
-- --     end loop;
-- --     return i_array;
-- -- 
-- --   -- sm_sc.fv_swish [],
-- --   elsif array_ndims(i_array) = 1
-- --   then
-- --     while v_y_cur <= array_length(i_array, 1)
-- --     loop
-- --       i_array[v_y_cur] := sm_sc.fv_swish(i_array[v_y_cur]);
-- --       v_y_cur := v_y_cur + 1;
-- --     end loop;
-- --     return i_array;
-- -- 
-- --   else
-- --     raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
-- --   end if;

  return i_array /` (1.0 :: float +` (^` (-` i_array)));
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_activate_swish(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- select sm_sc.fv_activate_swish(array[[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- select sm_sc.fv_activate_swish(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- select sm_sc.fv_activate_swish(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_activate_swish(array[]::float[])
-- select sm_sc.fv_activate_swish(array[array[], array []]::float[])