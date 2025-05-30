-- drop function if exists sm_sc.fv_d_activate_absqrt(float[], float[]);
-- -- create or replace function sm_sc.fv_d_activate_absqrt
-- -- (
-- --   i_indepdt       float[] 
-- -- , i_asso_value    float[]   default  array[0.5, 0.0]
-- --                             -- 要求 0 < v_beta < 1
-- --                             -- 要求 0 < v_gamma < 1
-- -- )
-- -- returns float[]
-- -- as
-- -- $$
-- -- declare -- here
-- --   v_alpha                 float     ;
-- --   v_sign_flag_val         float[]   ;
-- --   v_sign_flag_gamma       float[]   ;
-- --   v_a_p_a                 float[]   ;
-- -- begin
-- --   -- 审计维度
-- --   if array_length(i_indepdt, array_ndims(i_indepdt)) is null
-- --   then 
-- --     return null;
-- --   end if;
-- --   
-- --   v_alpha         :=    i_asso_value[1] ^ (1.0 :: float / (1.0 :: float - i_asso_value[1]));
-- --   v_sign_flag_val :=    (<>`(<>` i_indepdt +` 0.5 :: float)) :: float[];   -- >=0 则为 1.0， <0 则为 -1.0
-- --   v_a_p_a         :=    (@` i_indepdt) +` v_alpha;
-- --   
-- --   if i_asso_value = array[0.5, 0.0] :: float[]
-- --   then 
-- --     return 
-- --       0.5 :: float *` (v_a_p_a ^` (-0.5 :: float))
-- --     ;
-- --   else 
-- --     v_sign_flag_gamma := 
-- --       i_asso_value[2]
-- --       *` 
-- --       ((1.0 :: float -` v_sign_flag_val) /` 2.0 :: float)    -- >=0 则为 0.0， <0 则为 1.0
-- --     ;
-- --     
-- --     return 
-- --       (
-- --         (
-- --           ((v_alpha ^` v_sign_flag_gamma) *` (i_asso_value[1] -` v_sign_flag_gamma))
-- --           *`
-- --           (v_a_p_a ^` i_asso_value[1])
-- --         )
-- --         +`
-- --         (v_sign_flag_gamma *` (v_alpha ^ (i_asso_value[1] + i_asso_value[2])) :: float)
-- --       )
-- --       /`
-- --       (
-- --         v_a_p_a
-- --         ^`
-- --         (v_sign_flag_gamma +` 1.0 :: float)
-- --       )
-- --     ;
-- --   end if;
-- -- end
-- -- $$
-- -- language plpgsql stable
-- -- cost 100;
-- -- -- select sm_sc.fv_d_activate_absqrt(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- -- -- select sm_sc.fv_d_activate_absqrt(array[[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- -- -- select sm_sc.fv_d_activate_absqrt(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- -- -- select sm_sc.fv_d_activate_absqrt(array[1.5, -2.5, 3.5])
-- -- -- select sm_sc.fv_d_activate_absqrt(array[]::float[])
-- -- -- select sm_sc.fv_d_activate_absqrt(array[array[], array []]::float[])