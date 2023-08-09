-- set search_path to sm_sc;
drop function if exists sm_sc.fv_opr_prod_mx(anyarray, anyarray);
-- -- create or replace function sm_sc.fv_opr_prod_mx
-- -- (
-- --   i_left     anyarray    ,
-- --   i_right    anyarray
-- -- )
-- -- returns anyarray
-- -- as
-- -- $$
-- -- -- declare 
-- -- begin
-- --   -- set search_path to sm_sc;
-- --   if array_length(i_left, 2) <> array_length(i_right, 1)
-- --   then
-- --     raise exception 'unmatched length!';
-- --   end if;
-- -- 
-- --   if array_ndims(i_left) = 2 and array_ndims(i_right) = 2
-- --   then
-- --     return
-- --     (
-- --       select 
-- --         array_agg(cur_array_x order by cur_left_y)
-- --       from
-- --       (
-- --         select 
-- --           cur_left_y   ,
-- --           array_agg(val_y_x order by cur_right_x) as cur_array_x
-- --         from
-- --         (
-- --           select 
-- --             cur_left_y             ,
-- --             cur_right_x            ,
-- --             sum(i_left[cur_left_y][cur_left_x_right_y] * i_right[cur_left_x_right_y][cur_right_x]) as val_y_x
-- --           from generate_series(1, array_length(i_left, 1))  cur_left_y
-- --              , generate_series(1, array_length(i_left, 2))  cur_left_x_right_y
-- --              , generate_series(1, array_length(i_right, 2))  cur_right_x
-- --           group by cur_left_y, cur_right_x
-- --         ) t_a_val_y_x
-- --         group by cur_left_y
-- --       ) t_a_array_x
-- --     )
-- --     ;
-- --   else
-- --     return null; raise notice 'no method for such length!  L_Ndim: %; L_len_1: %; L_len_2: %; R_Ndim: %; R_len_1: %; R_len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2), array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
-- --   end if;
-- -- 
-- -- end
-- -- $$
-- -- language plpgsql stable
-- -- parallel safe
-- -- cost 100;
-- -- -- -- set search_path to sm_sc;
-- -- -- select sm_sc.fv_opr_prod_mx
-- -- --   (
-- -- --     array[array[1.0000,2.0000,3.0000], array[4.0000,5.0000,6.0000]],
-- -- --     array[array[1.0000,3.0000,5.0000,7.0000 ], array[5.0000,7.0000,9.0000,11.0000], array[9.0000,11.0000,13.0000,15.0000]]
-- -- --   );