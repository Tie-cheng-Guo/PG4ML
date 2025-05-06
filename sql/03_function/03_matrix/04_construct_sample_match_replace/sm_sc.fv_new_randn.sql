-- -- -- set search_path to sm_sc;
-- -- -- drop function if exists sm_sc.fv_new_randn(float, float, int[]);
-- -- create or replace function sm_sc.fv_new_randn
-- -- (
-- --   i_meta_val_mean     float    ,
-- --   i_meta_val_stddev   float    ,
-- --   i_dims_len          int[]
-- -- )
-- -- returns float[]
-- -- as
-- -- $$
-- -- declare 
-- --   v_ret    float[]   ;
-- --   v_cur_y  int       ;
-- --   v_cur_x  int       ;
-- --   v_cur_x3 int       ;
-- --   v_cur_x4 int       ;
-- --   v_cur_x5 int       ;
-- -- begin
-- --   -- set search_path to sm_sc;
-- --   if current_setting('pg4ml._v_is_debug_check', true) = '1'
-- --   then
-- --     if array_ndims(i_dims_len) <> 1 
-- --       or array_length(i_dims_len, 1) not between 1 and 5
-- --       or 1 <= any(i_dims_len)
-- --     then
-- --       raise exception 'unsupport ndims or length!';
-- --     end if;
-- --   end if;
-- -- 
-- --   if array_length(i_dims_len, 1) = 1
-- --   then 
-- --     return 
-- --     (
-- --       select 
-- --         array_agg(a_randn)
-- --       from normal_rand(i_dims_len[1], i_meta_val_mean, i_meta_val_stddev) a_randn
-- --     )
-- --     ;
-- --   elsif array_length(i_dims_len, 1) = 2
-- --   then 
-- --     v_ret := array_fill(null :: float, i_dims_len);
-- --     for v_cur_y in 1 .. i_dims_len[1]
-- --     loop 
-- --       for v_cur_x in 1 .. i_dims_len[2]
-- --       loop 
-- --         v_ret[v_cur_y][v_cur_x] = normal_rand(1, i_meta_val_mean, i_meta_val_stddev);
-- --       end loop;
-- --     end loop;
-- --     return v_ret;
-- --   elsif array_length(i_dims_len, 1) = 3
-- --   then 
-- --     v_ret := array_fill(null :: float, i_dims_len);
-- --     for v_cur_y in 1 .. i_dims_len[1]
-- --     loop 
-- --       for v_cur_x in 1 .. i_dims_len[2]
-- --       loop 
-- --         for v_cur_x3 in 1 .. i_dims_len[3]
-- --         loop 
-- --           v_ret[v_cur_y][v_cur_x][v_cur_x3] = normal_rand(1, i_meta_val_mean, i_meta_val_stddev);
-- --         end loop;
-- --       end loop;
-- --     end loop;
-- --     return v_ret;
-- --   elsif array_length(i_dims_len, 1) = 4
-- --   then 
-- --     v_ret := array_fill(null :: float, i_dims_len);
-- --     for v_cur_y in 1 .. i_dims_len[1]
-- --     loop 
-- --       for v_cur_x in 1 .. i_dims_len[2]
-- --       loop 
-- --         for v_cur_x3 in 1 .. i_dims_len[3]
-- --         loop 
-- --           for v_cur_x4 in 1 .. i_dims_len[4]
-- --           loop 
-- --             v_ret[v_cur_y][v_cur_x][v_cur_x3][v_cur_x4] = normal_rand(1, i_meta_val_mean, i_meta_val_stddev);
-- --           end loop;
-- --         end loop;
-- --       end loop;
-- --     end loop;
-- --     return v_ret;
-- --   elsif array_length(i_dims_len, 1) = 5
-- --   then 
-- --     v_ret := array_fill(null :: float, i_dims_len);
-- --     for v_cur_y in 1 .. i_dims_len[1]
-- --     loop 
-- --       for v_cur_x in 1 .. i_dims_len[2]
-- --       loop 
-- --         for v_cur_x3 in 1 .. i_dims_len[3]
-- --         loop 
-- --           for v_cur_x4 in 1 .. i_dims_len[4]
-- --           loop 
-- --             for v_cur_x5 in 1 .. i_dims_len[5]
-- --             loop 
-- --               v_ret[v_cur_y][v_cur_x][v_cur_x3][v_cur_x4][v_cur_x5] = normal_rand(1, i_meta_val_mean, i_meta_val_stddev);
-- --             end loop;
-- --           end loop;
-- --         end loop;
-- --       end loop;
-- --     end loop;
-- --     return v_ret;
-- --   end if;
-- -- end
-- -- $$
-- -- language plpgsql volatile
-- -- parallel safe
-- -- cost 100;

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new_randn(float, float, int[]);
create or replace function sm_sc.fv_new_randn
(
  i_meta_val_mean     float    ,
  i_meta_val_stddev   float    ,
  i_dims_len          int[]
)
returns float[]
as
$$
  import numpy as np 
  return np.random.normal(i_meta_val_mean, i_meta_val_stddev, i_dims_len).tolist()
$$
language plpython3u volatile
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_randn
--   (
--     12.3,
--     2.0 :: float,
--     array[5, 6]
--   );