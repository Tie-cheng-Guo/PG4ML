-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_transpose(anyarray);
create or replace function sm_sc.fv_opr_transpose
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
    return sm_sc.fv_opr_transpose_py(i_right);
    
  elsif array_ndims(i_right) = 2
  then
    -- -- return 	
    -- -- (
    -- --   select
    -- --     array_agg(array_x_new order by a_cur_xy)
    -- --   from 
    -- --   (
    -- --     select 
    -- --       a_cur_xy,
    -- --       array_agg(i_right[a_cur_yx][a_cur_xy] order by a_cur_yx) as array_x_new
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
    return v_ret;
    
  elsif array_ndims(i_right) = 3
  then
    v_ret  :=   array_fill(nullif(v_ret[1][1][1], v_ret[1][1][1]), array[array_length(i_right, 1), array_length(i_right, 3), array_length(i_right, 2)]);
    for v_cur in 1 .. array_length(i_right, 3)
    loop 
      v_ret[ : ][v_cur : v_cur][ : ]   :=  i_right[ : ][ : ][v_cur : v_cur];
    end loop;
    return v_ret;
    
  elsif array_ndims(i_right) = 4
  then
    v_ret  :=   array_fill(nullif(v_ret[1][1][1][1], v_ret[1][1][1][1]), array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 4), array_length(i_right, 3)]);
    for v_cur in 1 .. array_length(i_right, 4)
    loop 
      v_ret[ : ][ : ][v_cur : v_cur][ : ]   :=  i_right[ : ][ : ][ : ][v_cur : v_cur];
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
-- select sm_sc.fv_opr_transpose
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_transpose
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6], array[1.2, 2.3]]
--   );
-- select sm_sc.fv_opr_transpose
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]
--   );
-- select sm_sc.fv_opr_transpose
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   );


-- --------------------------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_transpose(anyarray, int[2]);
create or replace function sm_sc.fv_opr_transpose
(
  i_array_nd      anyarray      ,
  i_dims          int[2]
)
returns anyarray
as
$$
declare
  v_ret     i_array_nd%type;
  v_cur_1   int   ;
  v_cur_2   int   ;
begin
  if array_ndims(i_array_nd) not in (2, 3, 4)
  then 
    raise exception 'ndims of i_array_nd should be 2, 3 or 4.';
  end if;
  
  if array_ndims(i_dims) <> 1
    or array_ndims(i_array_nd) = 2 
      and 
      (
        i_dims[1] not in (1, 2) 
        or i_dims[2] not in (1, 2)
      )
    or array_ndims(i_array_nd) = 3 
      and 
      (
        i_dims[1] not in (1, 2, 3) 
        or i_dims[2] not in (1, 2, 3)
      )
    or array_ndims(i_array_nd) = 4
      and 
      (
        i_dims[1] not in (1, 2, 3, 4) 
        or i_dims[2] not in (1, 2, 3, 4)
      )
    or i_dims[1] = i_dims[2]
  then 
    raise exception 'illegal i_dims';
  end if;
  
  if pg_typeof(i_array_nd) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_transpose_py(i_array_nd, i_dims);
  end if;
 
  if array_ndims(i_array_nd) = 2
  then 
    if i_dims in (array[2, 1], array[1, 2])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 2), array_length(i_array_nd, 1)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 2)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret[v_cur_1 : v_cur_1][v_cur_2 : v_cur_2] := i_array_nd[v_cur_2 : v_cur_2][v_cur_1 : v_cur_1];
        end loop;
      end loop;
      return v_ret;
    end if;
    
  elsif array_ndims(i_array_nd) = 3
  then
    if i_dims in (array[1, 2], array[2, 1])
    then 
      -- -- return 
      -- -- (
      -- --   with 
      -- --   cte_slice_x as 
      -- --   (
      -- --     select 
      -- --       a_cur_z,
      -- --       a_cur_y,
      -- --       array_agg(i_array_nd[a_cur_z][a_cur_y][a_cur_x] order by a_cur_x) as a_slice_x
      -- --     from generate_series(1, array_length(i_array_nd, 1)) tb_a_cur_z(a_cur_z)
      -- --       , generate_series(1, array_length(i_array_nd, 2)) tb_a_cur_y(a_cur_y)
      -- --       , generate_series(1, array_length(i_array_nd, 3)) tb_a_cur_x(a_cur_x)
      -- --     group by a_cur_z, a_cur_y
      -- --   ),
      -- --   cte_slice_z_x as 
      -- --   (
      -- --     select 
      -- --       a_cur_y, 
      -- --       array_agg(a_slice_x order by a_cur_z) as a_slice_z_x
      -- --     from cte_slice_x
      -- --     group by a_cur_y
      -- --   )
      -- --   select 
      -- --     array_agg(a_slice_z_x order by a_cur_y)
      -- --   from cte_slice_z_x
      -- -- );
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 2), array_length(i_array_nd, 1), array_length(i_array_nd, 3)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 2)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret[v_cur_1 : v_cur_1][v_cur_2 : v_cur_2][ : ] := i_array_nd[v_cur_2 : v_cur_2][v_cur_1 : v_cur_1][ : ];
        end loop;
      end loop;
      return v_ret;
      
    elsif i_dims in (array[1, 3], array[3, 1])
    then 
      -- -- return 
      -- -- (
      -- --   with 
      -- --   cte_slice_z as 
      -- --   (
      -- --     select 
      -- --       a_cur_x,
      -- --       a_cur_y,
      -- --       array_agg(i_array_nd[a_cur_z][a_cur_y][a_cur_x] order by a_cur_z) as a_slice_z
      -- --     from generate_series(1, array_length(i_array_nd, 1)) tb_a_cur_z(a_cur_z)
      -- --       , generate_series(1, array_length(i_array_nd, 2)) tb_a_cur_y(a_cur_y)
      -- --       , generate_series(1, array_length(i_array_nd, 3)) tb_a_cur_x(a_cur_x)
      -- --     group by a_cur_x, a_cur_y
      -- --   ),
      -- --   cte_slice_y_x as 
      -- --   (
      -- --     select 
      -- --       a_cur_x, 
      -- --       array_agg(a_slice_z order by a_cur_y) as a_slice_y_z
      -- --     from cte_slice_z
      -- --     group by a_cur_x
      -- --   )
      -- --   select 
      -- --     array_agg(a_slice_y_z order by a_cur_x)
      -- --   from cte_slice_y_x
      -- -- );
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 3), array_length(i_array_nd, 2), array_length(i_array_nd, 1)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 3)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret[v_cur_1 : v_cur_1][ : ][v_cur_2 : v_cur_2] := i_array_nd[v_cur_2 : v_cur_2][ : ][v_cur_1 : v_cur_1];
        end loop;
      end loop;
      return v_ret;
      
    elsif i_dims in (array[2, 3], array[3, 2])
    then 
      -- -- return 
      -- -- (
      -- --   with 
      -- --   cte_slice_y as 
      -- --   (
      -- --     select 
      -- --       a_cur_z,
      -- --       a_cur_x,
      -- --       array_agg(i_array_nd[a_cur_z][a_cur_y][a_cur_x] order by a_cur_y) as a_slice_y
      -- --     from generate_series(1, array_length(i_array_nd, 1)) tb_a_cur_z(a_cur_z)
      -- --       , generate_series(1, array_length(i_array_nd, 2)) tb_a_cur_y(a_cur_y)
      -- --       , generate_series(1, array_length(i_array_nd, 3)) tb_a_cur_x(a_cur_x)
      -- --     group by a_cur_z, a_cur_x
      -- --   ),
      -- --   cte_slice_x_y as 
      -- --   (
      -- --     select 
      -- --       a_cur_z, 
      -- --       array_agg(a_slice_y order by a_cur_x) as a_slice_x_y
      -- --     from cte_slice_y
      -- --     group by a_cur_z
      -- --   )
      -- --   select 
      -- --     array_agg(a_slice_x_y order by a_cur_z)
      -- --   from cte_slice_x_y
      -- -- );
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 1), array_length(i_array_nd, 3), array_length(i_array_nd, 2)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 3)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 2)
        loop 
          v_ret[ : ][v_cur_1 : v_cur_1][v_cur_2 : v_cur_2] := i_array_nd[ : ][v_cur_2 : v_cur_2][v_cur_1 : v_cur_1];
        end loop;
      end loop;
      return v_ret;
      
    end if;
    
  elsif array_ndims(i_array_nd) = 4
  then 
    if i_dims in (array[1, 2], array[2, 1])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 2), array_length(i_array_nd, 1), array_length(i_array_nd, 3), array_length(i_array_nd, 4)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 2)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret[v_cur_1 : v_cur_1][v_cur_2 : v_cur_2][ : ][ : ] := i_array_nd[v_cur_2 : v_cur_2][v_cur_1 : v_cur_1][ : ][ : ];
        end loop;
      end loop;
      return v_ret;
    elsif i_dims in (array[1, 3], array[3, 1])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 3), array_length(i_array_nd, 2), array_length(i_array_nd, 1), array_length(i_array_nd, 4)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 3)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret[v_cur_1 : v_cur_1][ : ][v_cur_2 : v_cur_2][ : ] := i_array_nd[v_cur_2 : v_cur_2][ : ][v_cur_1 : v_cur_1][ : ];
        end loop;
      end loop;
      return v_ret;
    elsif i_dims in (array[1, 4], array[4, 1])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 4), array_length(i_array_nd, 2), array_length(i_array_nd, 3), array_length(i_array_nd, 1)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 4)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret[v_cur_1 : v_cur_1][ : ][ : ][v_cur_2 : v_cur_2] := i_array_nd[v_cur_2 : v_cur_2][ : ][ : ][v_cur_1 : v_cur_1];
        end loop;
      end loop;
      return v_ret;
    elsif i_dims in (array[2, 3], array[3, 2])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 1), array_length(i_array_nd, 3), array_length(i_array_nd, 2), array_length(i_array_nd, 4)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 3)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 2)
        loop 
          v_ret[ : ][v_cur_1 : v_cur_1][v_cur_2 : v_cur_2][ : ] := i_array_nd[ : ][v_cur_2 : v_cur_2][v_cur_1 : v_cur_1][ : ];
        end loop;
      end loop;
      return v_ret;
    elsif i_dims in (array[2, 4], array[4, 2])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 1), array_length(i_array_nd, 4), array_length(i_array_nd, 3), array_length(i_array_nd, 2)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 4)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 2)
        loop 
          v_ret[ : ][v_cur_1 : v_cur_1][ : ][v_cur_2 : v_cur_2] := i_array_nd[ : ][v_cur_2 : v_cur_2][ : ][v_cur_1 : v_cur_1];
        end loop;
      end loop;
      return v_ret;
    elsif i_dims in (array[3, 4], array[4, 3])
    then 
      v_ret := array_fill(nullif(i_array_nd[0], i_array_nd[0]), array[array_length(i_array_nd, 1), array_length(i_array_nd, 2), array_length(i_array_nd, 4), array_length(i_array_nd, 3)]);
      for v_cur_1 in 1 .. array_length(i_array_nd, 4)
      loop 
        for v_cur_2 in 1 .. array_length(i_array_nd, 3)
        loop 
          v_ret[ : ][ : ][v_cur_1 : v_cur_1][v_cur_2 : v_cur_2] := i_array_nd[ : ][ : ][v_cur_2 : v_cur_2][v_cur_1 : v_cur_1];
        end loop;
      end loop;
      return v_ret;
      
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_transpose
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4],
--         [5, 6, 7, 8],
--         [9, 10, 11, 12]
--       ],
--       [
--         [21, 22, 23, 24],
--         [25, 26, 27, 28],
--         [29, 30, 31, 32]
--       ]
--     ]
--     , array[2, 1]  -- array[1, 2]
--   );
-- select sm_sc.fv_opr_transpose
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4],
--         [5, 6, 7, 8],
--         [9, 10, 11, 12]
--       ],
--       [
--         [21, 22, 23, 24],
--         [25, 26, 27, 28],
--         [29, 30, 31, 32]
--       ]
--     ]
--     , array[3, 2]   -- array[1, 3]  -- array[2, 1]
--   );
-- select sm_sc.fv_opr_transpose
--   (
--     sm_sc.fv_new_rand(array[2,3,4,5])
--   , array[1,2]   -- array[1,3]  -- array[1,4]  -- array[2,3]   -- array[2,4]   -- array[3,4]
--   );