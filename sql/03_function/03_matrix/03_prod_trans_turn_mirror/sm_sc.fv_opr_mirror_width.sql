-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_mirror_width(anyarray);
create or replace function sm_sc.fv_opr_mirror_width
(
  i_right     anyarray
)
returns anyarray
as
$$
declare -- here
  v_cur               int; 
  -- v_ele              alias for $0;
  v_ret               i_right%type;
  v_len_mirror_dim    int  :=   array_length(i_right, array_ndims(i_right));
begin
  -- set search_path to sm_sc;
  
  if array_ndims(i_right) is null
  then 
    return i_right;
  -- -- elsif array_ndims(i_right) = 1
  -- -- then
  -- --   -- -- for v_cur in 1 .. array_length(i_right, 1) / 2
  -- --   -- -- loop
  -- --   -- --   v_ele[1] := i_right[v_cur];
  -- --   -- --   i_right[v_cur] := i_right[array_length(i_right, 1) - v_cur + 1];
  -- --   -- --   i_right[array_length(i_right, 1) - v_cur + 1] := v_ele[1];
  -- --   -- -- end loop;
  -- --   -- -- return i_right;
  -- --   v_ret := array_fill(nullif(i_right[1], i_right[1]), array[array_length(i_right, 1)]);
  -- --   for v_cur in 1 .. array_length(i_right, 1)
  -- --   loop 
  -- --     v_ret[v_cur] := i_right[array_length(i_right, 1) - v_cur + 1];
  -- --   end loop;
  -- --   return v_ret;

  elsif array_ndims(i_right) = 2
  then
    -- -- return 	
    -- -- (
    -- --   select
    -- --     array_agg(array_x_new order by a_cur_y)
    -- --   from 
    -- --   (
    -- --     select 
    -- --       a_cur_y,
    -- --       array_agg(i_right[a_cur_y][a_cur_x] order by a_cur_x desc) as array_x_new
    -- --     from generate_series(1, array_length(i_right, 1)) tb_a_cur_y(a_cur_y)
    -- --       , generate_series(1, v_len_mirror_dim) tb_a_cur_x(a_cur_x)
    -- --     group by a_cur_y
    -- --   ) t_array_x_new
    -- -- )
    -- -- ;
    v_ret := array_fill(nullif(i_right[1][1], i_right[1][1]), array[array_length(i_right, 1), v_len_mirror_dim]);
    for v_cur in 1 .. v_len_mirror_dim
    loop 
      v_ret[ : ][v_cur : v_cur] := i_right[ : ][v_len_mirror_dim - v_cur + 1 : v_len_mirror_dim - v_cur + 1];
    end loop;
    return v_ret;
    
  elsif array_ndims(i_right) = 3
  then
    v_ret := array_fill(nullif(i_right[1][1][1], i_right[1][1][1]), array[array_length(i_right, 1), array_length(i_right, 2), v_len_mirror_dim]);
    for v_cur in 1 .. v_len_mirror_dim
    loop 
      v_ret[ : ][ : ][v_cur : v_cur] := i_right[ : ][ : ][v_len_mirror_dim - v_cur + 1 : v_len_mirror_dim - v_cur + 1];
    end loop;
    return v_ret;
    
  elsif array_ndims(i_right) = 4
  then
    v_ret := array_fill(nullif(i_right[1][1][1][1], i_right[1][1][1][1]), array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3), v_len_mirror_dim]);
    for v_cur in 1 .. v_len_mirror_dim
    loop 
      v_ret[ : ][ : ][ : ][v_cur : v_cur] := i_right[ : ][ : ][ : ][v_len_mirror_dim - v_cur + 1 : v_len_mirror_dim - v_cur + 1];
    end loop;
    return v_ret;
    
  else
    raise exception 'no method for such length!  Dim: %;  len_2: %;', array_dims(i_right),  v_len_mirror_dim;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_mirror_width
--   (
--     array[array[1, 2], array[3, 4]]
--   );
-- -- select sm_sc.fv_opr_mirror_width
-- --   (
-- --     array[1, 2, 3, 4]
-- --   );
-- select sm_sc.fv_opr_mirror_width
--   (
--     array[array[1, 2], array[3, 4], array[5, 6]]
--   );
-- select sm_sc.fv_opr_mirror_width
--   (
--     array[array[1, 2, 7], array[3, 4, 8], array[5, 6, 9]]
--   );
-- select sm_sc.fv_opr_mirror_width
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   );
-- select sm_sc.fv_opr_mirror_width
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   );