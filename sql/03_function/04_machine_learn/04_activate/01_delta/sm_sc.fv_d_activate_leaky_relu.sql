-- drop function if exists sm_sc.fv_d_activate_leaky_relu(float[], float);
create or replace function sm_sc.fv_d_activate_leaky_relu
(
  i_indepdt            float[]        ,
  i_asso_value       float    -- 
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
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_indepdt, array_ndims(i_indepdt)) is null
  then 
    return i_indepdt;
  end if;
  
  return 
    ((1.0 :: float - i_asso_value) *` (@` (@` i_indepdt))) +` i_asso_value
  ;

  -- -- sm_sc.fv_d_leaky_relu([][], )
  -- if array_ndims(i_indepdt) =  2
  -- then
  --   while v_y_cur <= array_length(i_indepdt, 1)
  --   loop 
  --     v_x_cur := 1  ;
  --     while v_x_cur <= array_length(i_indepdt, 2)
  --     loop
  --       i_indepdt[v_y_cur][v_x_cur] := sm_sc.fv_d_leaky_relu_asso(i_indepdt[v_y_cur][v_x_cur], i_asso_value);
  --       v_x_cur := v_x_cur + 1;
  --     end loop;
  --     v_y_cur := v_y_cur + 1;
  --   end loop;
  --   return i_indepdt;
  -- 
  -- -- sm_sc.fv_d_leaky_relu [],
  -- elsif array_ndims(i_indepdt) = 1
  -- then
  --   while v_y_cur <= array_length(i_indepdt, 1)
  --   loop
  --     i_indepdt[v_y_cur] := sm_sc.fv_d_leaky_relu_asso(i_indepdt[v_y_cur], i_asso_value);
  --     v_y_cur := v_y_cur + 1;
  --   end loop;
  --   return i_indepdt;
  -- 
  -- -- sm_sc.fv_d_leaky_relu_asso([][][])
  -- elsif array_ndims(i_indepdt) = 3
  -- then
  --   for v_y_cur in 1 .. array_length(i_indepdt, 1)
  --   loop
  --     for v_x_cur in 1 .. array_length(i_indepdt, 2)
  --     loop
  --       for v_x3_cur in 1 .. array_length(i_indepdt, 3)
  --       loop
  --         i_indepdt[v_y_cur][v_x_cur][v_x3_cur] = 
  --           sm_sc.fv_d_leaky_relu_asso(i_indepdt[v_y_cur][v_x_cur][v_x3_cur], i_asso_value)
  --         ;
  --       end loop;    
  --     end loop;
  --   end loop;
  --   return i_indepdt;
  --   
  -- -- sm_sc.fv_d_leaky_relu_asso([][][][])
  -- elsif array_ndims(i_indepdt) = 4
  -- then
  --   for v_y_cur in 1 .. array_length(i_indepdt, 1)
  --   loop
  --     for v_x_cur in 1 .. array_length(i_indepdt, 2)
  --     loop
  --       for v_x3_cur in 1 .. array_length(i_indepdt, 3)
  --       loop
  --         for v_x4_cur in 1 .. array_length(i_indepdt, 4)
  --         loop
  --           i_indepdt[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
  --             sm_sc.fv_d_leaky_relu_asso(i_indepdt[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_asso_value)
  --           ;
  --         end loop;
  --       end loop;    
  --     end loop;
  --   end loop;
  --   return i_indepdt;
  --   
  -- else
  --   raise exception 'no method for such length!  Dim: %;', array_dims(i_indepdt);
  -- end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_d_activate_leaky_relu(array[[1.0 :: float, -2.0], [3.0, 4.0]], 0.2)
-- select sm_sc.fv_d_activate_leaky_relu(array[[[1.0 :: float, -2.0], [3.0, 4.0]]], 0.2)
-- select sm_sc.fv_d_activate_leaky_relu(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]], 0.2)
-- select sm_sc.fv_d_activate_leaky_relu(array[1.5, -2.5, 3.5], 0.2)
-- select sm_sc.fv_d_activate_leaky_relu(array[]::float[], 0.2)
-- select sm_sc.fv_d_activate_leaky_relu(array[array[], array []]::float[], 0.3)