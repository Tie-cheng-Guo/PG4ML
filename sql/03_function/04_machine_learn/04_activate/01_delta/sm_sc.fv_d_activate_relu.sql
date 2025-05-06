-- drop function if exists sm_sc.fv_d_activate_relu(float[]);
create or replace function sm_sc.fv_d_activate_relu
(
  i_indepdt     float[]
)
returns float[]
as
$$
-- -- declare -- here
-- --   v_x_cur   int  := 1  ;
-- --   v_y_cur   int  := 1  ;
begin
-- --   -- log(null :: float[][], float) = null :: float[][]
-- --   if array_length(i_indepdt, array_ndims(i_indepdt)) is null
-- --   then 
-- --     return i_indepdt;
-- --   end if;
-- -- 
-- --   -- sm_sc.fv_d_relu([][], )
-- --   if array_ndims(i_indepdt) =  2
-- --   then
-- --     while v_y_cur <= array_length(i_indepdt, 1)
-- --     loop 
-- --       v_x_cur := 1  ;
-- --       while v_x_cur <= array_length(i_indepdt, 2)
-- --       loop
-- --         i_indepdt[v_y_cur][v_x_cur] := sm_sc.fv_d_relu(i_indepdt[v_y_cur][v_x_cur]);
-- --         v_x_cur := v_x_cur + 1;
-- --       end loop;
-- --       v_y_cur := v_y_cur + 1;
-- --     end loop;
-- --     return i_indepdt;
-- -- 
-- --   -- sm_sc.fv_d_relu [],
-- --   elsif array_ndims(i_indepdt) = 1
-- --   then
-- --     while v_y_cur <= array_length(i_indepdt, 1)
-- --     loop
-- --       i_indepdt[v_y_cur] := sm_sc.fv_d_relu(i_indepdt[v_y_cur]);
-- --       v_y_cur := v_y_cur + 1;
-- --     end loop;
-- --     return i_indepdt;
-- -- 
-- --   else
-- --     raise exception 'no method for such length!  Dim: %;', array_dims(i_indepdt);
-- --   end if;

  return (i_indepdt >` 0.0 :: float) :: int[] :: float[];
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_d_activate_relu(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- select sm_sc.fv_d_activate_relu(array[[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- select sm_sc.fv_d_activate_relu(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- select sm_sc.fv_d_activate_relu(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_d_activate_relu(array[]::float[])
-- select sm_sc.fv_d_activate_relu(array[[], []]::float[])