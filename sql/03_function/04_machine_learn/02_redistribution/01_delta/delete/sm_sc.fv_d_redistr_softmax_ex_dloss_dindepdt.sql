
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt(float[], float[], float[], int[]);
-- -- create or replace function sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt
-- -- (
-- --   i_depdt                  float[]                                      -- softmax 输出
-- -- , i_dloss_ddepdt           float[]                                      -- 此入参传入 dloss/dindepdt, 用于 softmax 直接求取 dloss/ddepdt
-- -- , i_indepdt                float[]      default null                    -- softmax 算子的输入，来自上一层算子的输出
-- -- , i_cnt_per_grp            int[]        default null
-- -- )
-- -- returns float[]     -- 输出列序与 i_indepdt 枚举值 one_hot 序一致
-- -- as
-- -- $$
-- -- declare 
-- --   v_len               int;
-- --   v_stddev_samp       float;
-- -- begin
-- --   if i_cnt_per_grp is null
-- --   then 
-- --     i_cnt_per_grp := 
-- --       (
-- --         select 
-- --           array_agg(array_length(i_dloss_ddepdt, a_dim_no) order by a_dim_no)
-- --         from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a(a_dim_no)
-- --       )
-- --     ;
-- --   elsif sm_sc.fv_aggr_slice_is_exists_null(i_cnt_per_grp)
-- --   then 
-- --     i_cnt_per_grp :=
-- --       sm_sc.fv_coalesce
-- --       (
-- --         i_cnt_per_grp
-- --       , (
-- --           select 
-- --             array_agg(array_length(i_dloss_ddepdt, a_dim_no) order by a_dim_no)
-- --           from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a(a_dim_no)
-- --         )
-- --       )
-- --     ;
-- --   end if;
-- --   
-- --   -- 审计维度
-- --   if current_setting('pg4ml._v_is_debug_check', true) = '1'
-- --   then
-- --     if array_ndims(i_cnt_per_grp) > 1 
-- --     then 
-- --       raise exception 'unsupport ndims of i_cnt_per_grp > 1.';
-- --     elsif array_ndims(i_dloss_ddepdt) <> array_length(i_cnt_per_grp, 1)
-- --     then 
-- --       raise exception 'unmatch between ndims of i_dloss_ddepdt and length of i_cnt_per_grp.';
-- --     elsif 
-- --       0 <> any 
-- --       (
-- --         (
-- --           select 
-- --             array_agg(array_length(i_dloss_ddepdt, a_cur_dim) order by a_cur_dim) 
-- --           from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a_cur_dim(a_cur_dim)
-- --         )
-- --         %` i_cnt_per_grp
-- --       )
-- --     then 
-- --       raise exception 'unperfect i_dloss_ddepdt''s length for i_cnt_per_grp at some dims';
-- --     end if;
-- -- 
-- --     if array_ndims(i_depdt) > 4 or array_ndims(i_indepdt) > 4 or array_ndims(i_dloss_ddepdt) > 4
-- --       or array_dims(i_dloss_ddepdt) <> array_dims(i_depdt) or array_dims(i_dloss_ddepdt) <> array_dims(i_indepdt)
-- --       -- -- or array_length(i_dloss_ddepdt, 1) <> array_length(i_depdt, 1)
-- --       -- -- or array_length(i_dloss_ddepdt, 2) <> array_length(i_depdt, 2)
-- --       -- -- or array_length(i_dloss_ddepdt, 3) <> array_length(i_depdt, 3)
-- --       -- -- or array_length(i_dloss_ddepdt, 4) <> array_length(i_depdt, 4)
-- --       -- -- or array_length(i_dloss_ddepdt, 1) <> array_length(i_indepdt, 1)
-- --       -- -- or array_length(i_dloss_ddepdt, 2) <> array_length(i_indepdt, 2)
-- --       -- -- or array_length(i_dloss_ddepdt, 3) <> array_length(i_indepdt, 3)
-- --       -- -- or array_length(i_dloss_ddepdt, 4) <> array_length(i_indepdt, 4)
-- --     then 
-- --       raise exception 'unmatch ndims or length between i_depdt, i_indepdt and i_dloss_ddepdt.';
-- --     end if;
-- --   end if;
-- -- 
-- --   if i_depdt is null
-- --   then
-- --     i_depdt := sm_sc.fv_redistr_softmax_ex(i_indepdt, i_cnt_per_grp);
-- --   end if;
-- -- 
-- --   return 
-- --     i_depdt 
-- --     *` 
-- --     (
-- --       i_dloss_ddepdt 
-- --       -` 
-- --       sm_sc.fv_repeat_axis_py
-- --       (
-- --         (
-- --           i_depdt 
-- --           *` 
-- --           i_dloss_ddepdt
-- --         ) 
-- --         |@+| 
-- --         i_cnt_per_grp
-- --       , (select array_agg(a_no order by a_no) from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a(a_no))
-- --       , i_cnt_per_grp
-- --       )
-- --     )
-- --   ; -- ~=` 8
-- -- end
-- -- $$
-- -- language plpgsql stable
-- -- parallel safe
-- -- cost 100;
-- -- 
-- -- -- -- set search_path to sm_sc;
-- -- -- select sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt
-- -- --   (
-- -- --     sm_sc.fv_redistr_softmax_ex(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]),
-- -- --     (-` array[array[0.0 :: float, 1.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[1.0 :: float, 0.0]] /` sm_sc.fv_redistr_softmax_ex(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]])),
-- -- --     array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]
-- -- --   );
-- -- 
-- -- -- select sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt
-- -- --   (
-- -- --     sm_sc.fv_redistr_softmax_ex(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]),
-- -- --     (-` array[array[0.0 :: float, 1.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[1.0 :: float, 0.0]] /` sm_sc.fv_redistr_softmax_ex(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]])),
-- -- --     array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]
-- -- --   );
-- -- 
-- -- -- with 
-- -- -- cte_arr as 
-- -- -- (
-- -- --   select 
-- -- --     sm_sc.fv_new_rand(array[2, 3, 4]) as a_arr
-- -- -- )
-- -- -- select 
-- -- --   sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt
-- -- --   (
-- -- --     sm_sc.fv_redistr_softmax_ex(a_arr)
-- -- --   , array[[[0,0,0,0],[0,0,0,0],[0,0,0,0]],[[1,0,0,0],[0,0,0,0],[0,0,0,0]]]
-- -- --   , a_arr
-- -- --   ) 
-- -- -- from cte_arr
-- -- 
-- -- -- with 
-- -- -- cte_arr as 
-- -- -- (
-- -- --   select 
-- -- --     sm_sc.fv_new_rand(array[2, 3, 4, 2]) as a_arr
-- -- -- )
-- -- -- select 
-- -- --   sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt
-- -- --   (
-- -- --     sm_sc.fv_redistr_softmax_ex(a_arr)
-- -- --   , array[[[[0,0],[0,0],[0,0],[0,0]],[[0,0],[0,0],[0,0],[0,0]],[[0,0],[0,0],[0,0],[0,0]]],[[[1,0],[0,0],[0,0],[0,0]],[[0,0],[0,0],[0,0],[0,0]],[[0,0],[0,0],[0,0],[0,0]]]]
-- -- --   , a_arr
-- -- --   ) 
-- -- -- from cte_arr
-- -- 
-- -- -- do
-- -- -- $$
-- -- -- declare 
-- -- --   v_dloss_ddepdt   float[]  :=   sm_sc.fv_new(0.0, array[4, 6, 9]);
-- -- -- begin
-- -- --   v_dloss_ddepdt[1][1][1]   :=   1.0;
-- -- --   raise notice '%',
-- -- --   (
-- -- --     with 
-- -- --     cte_arr as 
-- -- --     (
-- -- --       select 
-- -- --         sm_sc.fv_new_rand(array[4, 6, 9]) as a_arr
-- -- --     )
-- -- --     select 
-- -- --       sm_sc.fv_d_redistr_softmax_ex_dloss_dindepdt
-- -- --       (
-- -- --         sm_sc.fv_redistr_softmax_ex(a_arr)
-- -- --       , v_dloss_ddepdt
-- -- --       , a_arr
-- -- --       , array[2, 3, 3]
-- -- --       ) 
-- -- --     from cte_arr
-- -- --   );
-- -- -- end
-- -- -- $$
-- -- -- language plpgsql