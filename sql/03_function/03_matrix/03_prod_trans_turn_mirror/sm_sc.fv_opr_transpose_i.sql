-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_transpose_i(anyarray);
create or replace function sm_sc.fv_opr_transpose_i
(
  i_right     anyarray
)
returns anyarray
as
$$
declare 
  v_ret  i_right%type;
  v_cur  int  ;
begin
  -- set search_path to sm_sc;
    
  if array_ndims(i_right) is null
  then 
    return i_right;
    
  elsif pg_typeof(i_right) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_transpose_i_py(i_right);
    
  elsif array_ndims(i_right) = 2
  then
    -- -- return 	
    -- -- (
    -- --   select
    -- --     array_agg(array_x_new order by a_cur_xy desc)
    -- --   from 
    -- --   (
    -- --     select 
    -- --       a_cur_xy,
    -- --       array_agg(i_right[a_cur_yx][a_cur_xy] order by a_cur_yx desc) as array_x_new
    -- --     from generate_series(1, array_length(i_right, 1)) tb_a_cur_yx(a_cur_yx)
    -- --       , generate_series(1, array_length(i_right, 2)) tb_a_cur_xy(a_cur_xy)
    -- --     group by a_cur_xy
    -- --   ) t_array_x_new
    -- -- )
    -- -- ;
    v_ret  :=   array_fill(nullif(v_ret[1][1], v_ret[1][1]), array[array_length(i_right, 2), array_length(i_right, 1)]);
    for v_cur in 1 .. array_length(i_right, 2)
    loop 
      v_ret[v_cur : v_cur][ : ]   :=  i_right[ : ][v_cur : v_cur];
    end loop;
    return sm_sc.fv_opr_mirror(sm_sc.fv_opr_mirror(v_ret, 2), 1);
    
  elsif array_ndims(i_right) = 3
  then
    v_ret  :=   array_fill(nullif(v_ret[1][1][1], v_ret[1][1][1]), array[array_length(i_right, 1), array_length(i_right, 3), array_length(i_right, 2)]);
    for v_cur in 1 .. array_length(i_right, 3)
    loop 
      v_ret[ : ][v_cur : v_cur][ : ]   :=  i_right[ : ][ : ][v_cur : v_cur];
    end loop;
    return sm_sc.fv_opr_mirror(sm_sc.fv_opr_mirror(v_ret, 3), 2);
    
  elsif array_ndims(i_right) = 4
  then
    v_ret  :=   array_fill(nullif(v_ret[1][1][1][1], v_ret[1][1][1][1]), array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 4), array_length(i_right, 3)]);
    for v_cur in 1 .. array_length(i_right, 4)
    loop 
      v_ret[ : ][ : ][v_cur : v_cur][ : ]   :=  i_right[ : ][ : ][ : ][v_cur : v_cur];
    end loop;
    return sm_sc.fv_opr_mirror(sm_sc.fv_opr_mirror(v_ret, 4), 3);
    
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_transpose_i
--   (
--     array[array[1, 2], array[3, 4]]
--   );
-- select sm_sc.fv_opr_transpose_i
--   (
--     array[array[1, 2], array[3, 4], array[5, 6]]
--   );
-- select sm_sc.fv_opr_transpose_i
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   );
-- select sm_sc.fv_opr_transpose_i
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   );