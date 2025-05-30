-- drop function if exists sm_sc.fv_activate_absqrt(float[], float[]);
-- -- create or replace function sm_sc.fv_activate_absqrt
-- -- (
-- --   i_array         float[]
-- -- , i_asso_value    float[]   default  array[0.5, 0.0]    -- array[v_beta, v_gamma]
-- --                             -- 要求 0 < v_beta < 1, 用于控制正半轴压制程度，
-- --                             --     当 v_beta 靠近 1.0，则压制小；
-- --                             --     当 v_beta 靠近0.0 则压制大；
-- --                             -- 要求 0 < v_gamma <= 1, 在正半轴压制确定的基础上，用于控制负半轴压制程度，
-- --                             --     当 v_gamma = 0.0，则负半轴压制与正半轴一致，此时函数为中心对称；
-- --                             --     当 v_gamma = v_beta，则导数仍保持为正，自变量为负无穷时，因变量趋近于下限为 v_beta ^ (v_beta / (v_beta - 1.0))；
-- --                             --     当 v_gamma = 1.0，则会出现负导数，自变量为负无穷时，因变量趋近于 - 0.0
-- -- )
-- -- returns float[]
-- -- as
-- -- $$
-- -- declare -- here
-- -- --   v_x_cur   int  := 1  ;
-- -- --   v_y_cur   int  := 1  ;
-- -- --   v_x3_cur      int  := 1  ;
-- -- --   v_x4_cur      int  := 1  ;
-- --   v_alpha                 float     ;
-- --   v_basic                 float[]   ;
-- --   v_sign_flag_val         float[]   ;
-- --   v_sign_flag_gamma       float[]   ;
-- --   v_a_p_a                 float[]   ;
-- -- begin
-- --   -- selu(null :: float[][], float) = null :: float[][]
-- --   if array_length(i_array, array_ndims(i_array)) is null
-- --   then 
-- --     return i_array;
-- --   end if;
-- --   
-- --   v_alpha         :=    i_asso_value[1] ^ (1.0 :: float / (1.0 :: float - i_asso_value[1]));
-- --   v_sign_flag_val :=    (<>`(<>` i_array +` 0.5 :: float)) :: float[];   -- >=0 则为 1.0， <0 则为 -1.0
-- --   v_a_p_a         :=    (@` i_array) +` v_alpha;
-- --   v_basic         :=
-- --     v_sign_flag_val
-- --     *`
-- --     (
-- --       (
-- --         v_a_p_a
-- --         ^`
-- --         i_asso_value[1]
-- --       )
-- --       -`
-- --       ((v_alpha ^ i_asso_value[1]) :: float)
-- --     )
-- --   ;
-- -- 
-- --   if i_asso_value[2] = 0.0
-- --   then 
-- --     return 
-- --       v_basic
-- --     ;
-- --     
-- --   elsif i_asso_value[2] = 1.0
-- --   then 
-- --     return 
-- --       v_basic 
-- --       /`
-- --       (
-- --         1.0 :: float 
-- --         -` 
-- --         (
-- --           ((@` i_array) /` v_alpha) 
-- --           *` 
-- --           ((1.0 :: float -` v_sign_flag_val) /` 2.0 :: float)    -- >=0 则为 0.0， <0 则为 1.0
-- --         )
-- --       )
-- --     ;
-- --     
-- --   else 
-- --     v_sign_flag_gamma := 
-- --       i_asso_value[2]
-- --       *` 
-- --       ((1.0 :: float -` v_sign_flag_val) /` 2.0 :: float)    -- >=0 则为 0.0， <0 则为 1.0
-- --     ;
-- --     
-- --     return 
-- --       v_basic 
-- --       /`
-- --       (
-- --         ((v_a_p_a /` v_alpha) ^` v_sign_flag_gamma)
-- --       )
-- --     ;
-- --   end if;
-- -- 
-- --   -- -- -- sm_sc.fv_absqrt([][], )
-- --   -- -- if array_ndims(i_array) =  2
-- --   -- -- then
-- --   -- --   while v_y_cur <= array_length(i_array, 1)
-- --   -- --   loop 
-- --   -- --     v_x_cur := 1  ;
-- --   -- --     while v_x_cur <= array_length(i_array, 2)
-- --   -- --     loop
-- --   -- --       i_array[v_y_cur][v_x_cur] := sm_sc.fv_absqrt(i_array[v_y_cur][v_x_cur], i_asso_value[1], i_asso_value[2]);
-- --   -- --       v_x_cur := v_x_cur + 1;
-- --   -- --     end loop;
-- --   -- --     v_y_cur := v_y_cur + 1;
-- --   -- --   end loop;
-- --   -- --   return i_array;
-- --   -- -- 
-- --   -- -- -- sm_sc.fv_absqrt [],
-- --   -- -- elsif array_ndims(i_array) = 1
-- --   -- -- then
-- --   -- --   while v_y_cur <= array_length(i_array, 1)
-- --   -- --   loop
-- --   -- --     i_array[v_y_cur] := sm_sc.fv_absqrt(i_array[v_y_cur], i_asso_value[1], i_asso_value[2]);
-- --   -- --     v_y_cur := v_y_cur + 1;
-- --   -- --   end loop;
-- --   -- --   return i_array;
-- --   -- -- 
-- --   -- -- -- sm_sc.fv_absqrt([][][])
-- --   -- -- elsif array_ndims(i_array) = 3
-- --   -- -- then
-- --   -- --   for v_y_cur in 1 .. array_length(i_array, 1)
-- --   -- --   loop
-- --   -- --     for v_x_cur in 1 .. array_length(i_array, 2)
-- --   -- --     loop
-- --   -- --       for v_x3_cur in 1 .. array_length(i_array, 3)
-- --   -- --       loop
-- --   -- --         i_array[v_y_cur][v_x_cur][v_x3_cur] = 
-- --   -- --           sm_sc.fv_absqrt(i_array[v_y_cur][v_x_cur][v_x3_cur], i_asso_value[1], i_asso_value[2])
-- --   -- --         ;
-- --   -- --       end loop;    
-- --   -- --     end loop;
-- --   -- --   end loop;
-- --   -- --   return i_array;
-- --   -- --   
-- --   -- -- -- sm_sc.fv_absqrt([][][][])
-- --   -- -- elsif array_ndims(i_array) = 4
-- --   -- -- then
-- --   -- --   for v_y_cur in 1 .. array_length(i_array, 1)
-- --   -- --   loop
-- --   -- --     for v_x_cur in 1 .. array_length(i_array, 2)
-- --   -- --     loop
-- --   -- --       for v_x3_cur in 1 .. array_length(i_array, 3)
-- --   -- --       loop
-- --   -- --         for v_x4_cur in 1 .. array_length(i_array, 4)
-- --   -- --         loop
-- --   -- --           i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
-- --   -- --             sm_sc.fv_absqrt(i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_asso_value[1], i_asso_value[2])
-- --   -- --           ;
-- --   -- --         end loop;
-- --   -- --       end loop;    
-- --   -- --     end loop;
-- --   -- --   end loop;
-- --   -- --   return i_array;
-- --   -- -- else
-- --   -- --   raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
-- --   -- -- end if;
-- -- end
-- -- $$
-- -- language plpgsql stable
-- -- cost 100;
-- -- -- select sm_sc.fv_activate_absqrt(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- -- -- select sm_sc.fv_activate_absqrt(array[[[1.0 :: float, -2.0], [3.0, 4.0]],[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- -- -- select sm_sc.fv_activate_absqrt(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- -- -- select sm_sc.fv_activate_absqrt(array[1.5, -2.5, 3.5])
-- -- -- select sm_sc.fv_activate_absqrt(array[]::float[])
-- -- -- select sm_sc.fv_activate_absqrt(array[array[], array []]::float[])