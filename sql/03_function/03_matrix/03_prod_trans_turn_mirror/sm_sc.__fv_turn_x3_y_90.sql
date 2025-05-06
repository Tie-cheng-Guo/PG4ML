-- set search_path to sm_sc;
-- drop function if exists sm_sc.__fv_turn_x3_y_90(anyarray);
create or replace function sm_sc.__fv_turn_x3_y_90
(
  i_right     anyarray
)
returns anyarray
as
$$
declare 
  v_ret      i_right%type   ;
  v_cur_1    int  ;
  v_cur_2    int  ;
  v_len_y    int  := array_length(i_right, 1);
  v_len_x    int  := array_length(i_right, 2);
  v_len_x3   int  := array_length(i_right, 3);
  v_len_x4   int  := array_length(i_right, 4);
begin
  -- set search_path to sm_sc;
    
  if array_ndims(i_right) is null
  then 
    return i_right;
  -- -- elsif array_ndims(i_right) = 2
  -- -- then
  -- --   -- return 	
  -- --   -- (
  -- --   --   select
  -- --   --     array_agg(array_x_new order by a_cur_x)
  -- --   --   from 
  -- --   --   (
  -- --   --     select 
  -- --   --       a_cur_x,
  -- --   --       array_agg(i_right[a_cur_y][a_cur_x] order by a_cur_y desc) as array_x_new
  -- --   --     from generate_series(1, v_len_y) tb_a_cur_y(a_cur_y)
  -- --   --       , generate_series(1, v_len_x) tb_a_cur_x(a_cur_x)
  -- --   --     group by a_cur_x
  -- --   --   ) t_array_x_new
  -- --   -- )
  -- --   -- ;
  -- --   v_ret := array_fill(nullif(i_right[1][1], i_right[1][1]), array[v_len_x, v_len_y]);
  -- --   for v_cur_1 in 1 .. v_len_x
  -- --   loop 
  -- --     v_ret[v_len_x - v_cur_1 + 1 : v_len_x - v_cur_1 + 1][ : ] := i_right[ : ][v_cur_1 : v_cur_1];
  -- --   end loop;
  -- --   return v_ret;
    
  elsif array_ndims(i_right) = 3
  then
    v_ret := array_fill(nullif(i_right[1][1][1], i_right[1][1][1]), array[v_len_x3, v_len_x, v_len_y]);
    for v_cur_1 in 1 .. v_len_x3
    loop 
      for v_cur_2 in 1 .. v_len_y
      loop 
        v_ret[v_len_x3 - v_cur_1 + 1 : v_len_x3 - v_cur_1 + 1][ : ][v_cur_2 : v_cur_2] := i_right[v_cur_2 : v_cur_2][ : ][v_cur_1 : v_cur_1];
      end loop;
    end loop;
    return v_ret;
    
  elsif array_ndims(i_right) = 4
  then
    v_ret := array_fill(nullif(i_right[1][1][1][1], i_right[1][1]), array[v_len_x3, v_len_x, v_len_y, v_len_x4]);
    for v_cur_1 in 1 .. v_len_x3
    loop 
      for v_cur_2 in 1 .. v_len_y
      loop 
        v_ret[v_len_x3 - v_cur_1 + 1 : v_len_x3 - v_cur_1 + 1][ : ][v_cur_2 : v_cur_2][ : ] := i_right[v_cur_2 : v_cur_2][ : ][v_cur_1 : v_cur_1][ : ];
      end loop;
    end loop;
    return v_ret;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- -- select sm_sc.__fv_turn_x3_y_90
-- --   (
-- --     array[array[1, 2], array[3, 4]]
-- --   );
-- -- select sm_sc.__fv_turn_x3_y_90
-- --   (
-- --     array[array[1, 2], array[3, 4], array[5, 6]]
-- --   );
-- select sm_sc.__fv_turn_x3_y_90
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   );
-- select sm_sc.__fv_turn_x3_y_90
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   );