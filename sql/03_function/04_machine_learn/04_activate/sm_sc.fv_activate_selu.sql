-- drop function if exists sm_sc.fv_activate_selu(float[]);
create or replace function sm_sc.fv_activate_selu
(
  i_array     float[]
)
returns float[]
as
$$
-- -- declare -- here
-- --   v_x_cur   int  := 1  ;
-- --   v_y_cur   int  := 1  ;
-- --   v_x3_cur      int  := 1  ;
-- --   v_x4_cur      int  := 1  ;
begin
  -- selu(null :: float[][], float) = null :: float[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;
  
  return 
    (i_array >=` 0.0 :: float) :: int[] :: float[] *` (0.0 :: float @>` i_array) *` 1.0507009873554804934193349852946 :: float
    +`
    (i_array <` 0.0 :: float) :: int[] :: float[] *` 1.75809934084737685994021752081231934206024580891220830977098282 :: float *` ((^` (0.0 :: float @<` i_array)) -` 1.0 :: float)
  ;
  
  -- -- -- sm_sc.fv_selu([][], )
  -- -- if array_ndims(i_array) =  2
  -- -- then
  -- --   while v_y_cur <= array_length(i_array, 1)
  -- --   loop 
  -- --     v_x_cur := 1  ;
  -- --     while v_x_cur <= array_length(i_array, 2)
  -- --     loop
  -- --       i_array[v_y_cur][v_x_cur] := sm_sc.fv_selu(i_array[v_y_cur][v_x_cur]);
  -- --       v_x_cur := v_x_cur + 1;
  -- --     end loop;
  -- --     v_y_cur := v_y_cur + 1;
  -- --   end loop;
  -- --   return i_array;
  -- -- 
  -- -- -- sm_sc.fv_selu [],
  -- -- elsif array_ndims(i_array) = 1
  -- -- then
  -- --   while v_y_cur <= array_length(i_array, 1)
  -- --   loop
  -- --     i_array[v_y_cur] := sm_sc.fv_selu(i_array[v_y_cur]);
  -- --     v_y_cur := v_y_cur + 1;
  -- --   end loop;
  -- --   return i_array;
  -- -- 
  -- -- -- sm_sc.fv_selu([][][])
  -- -- elsif array_ndims(i_array) = 3
  -- -- then
  -- --   for v_y_cur in 1 .. array_length(i_array, 1)
  -- --   loop
  -- --     for v_x_cur in 1 .. array_length(i_array, 2)
  -- --     loop
  -- --       for v_x3_cur in 1 .. array_length(i_array, 3)
  -- --       loop
  -- --         i_array[v_y_cur][v_x_cur][v_x3_cur] = 
  -- --           sm_sc.fv_selu(i_array[v_y_cur][v_x_cur][v_x3_cur])
  -- --         ;
  -- --       end loop;    
  -- --     end loop;
  -- --   end loop;
  -- --   return i_array;
  -- --   
  -- -- -- sm_sc.fv_selu([][][][])
  -- -- elsif array_ndims(i_array) = 4
  -- -- then
  -- --   for v_y_cur in 1 .. array_length(i_array, 1)
  -- --   loop
  -- --     for v_x_cur in 1 .. array_length(i_array, 2)
  -- --     loop
  -- --       for v_x3_cur in 1 .. array_length(i_array, 3)
  -- --       loop
  -- --         for v_x4_cur in 1 .. array_length(i_array, 4)
  -- --         loop
  -- --           i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
  -- --             sm_sc.fv_selu(i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur])
  -- --           ;
  -- --         end loop;
  -- --       end loop;    
  -- --     end loop;
  -- --   end loop;
  -- --   return i_array;
  -- -- else
  -- --   raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  -- -- end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_activate_selu(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- select sm_sc.fv_activate_selu(array[[[1.0 :: float, -2.0], [3.0, 4.0]],[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- select sm_sc.fv_activate_selu(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- select sm_sc.fv_activate_selu(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_activate_selu(array[]::float[])
-- select sm_sc.fv_activate_selu(array[array[], array []]::float[])