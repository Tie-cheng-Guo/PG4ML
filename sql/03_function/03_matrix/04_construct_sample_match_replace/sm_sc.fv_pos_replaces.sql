-- drop function if exists sm_sc.fv_pos_replaces(anyarray, int[], anyelement);
create or replace function sm_sc.fv_pos_replaces
(
  i_sour_arr     anyarray,
  i_pos_s        int[],
  i_tar_ele      anyelement
)
returns anyarray
as
$$
declare -- here
  v_cur   int;
begin
  -- 审查
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_sour_arr) > 4
    then
      raise exception 'unsupport ndims of i_sour_arr.';
    elsif array_ndims(i_pos_s) > 2
      or array_ndims(i_sour_arr) = 1 and array_ndims(i_sour_arr) > 1
    then 
      raise exception 'unsupport ndims of i_pos_s.';
    elsif array_length(i_pos_s, 2) <> array_ndims(i_sour_arr)
      or array_ndims(i_pos_s) = 1 and array_length(i_pos_s, 1) <> array_ndims(i_sour_arr)
    then 
      raise exception 'unsupport length of i_pos_s.';
    end if;
  end if;
  
  -- 1d
  if array_ndims(i_sour_arr) = 1
  then
    foreach v_cur in array i_pos_s
    loop
      i_sour_arr[v_cur] := i_tar_ele;
    end loop;
  end if;

  -- 2d
  if array_ndims(i_sour_arr) = 2
  then
    for v_cur in 1 .. array_length(i_pos_s, 1)
    loop
      i_sour_arr[i_pos_s[v_cur][1]][i_pos_s[v_cur][2]] := i_tar_ele;
    end loop;
  elsif array_ndims(i_sour_arr) = 3
  then
    for v_cur in 1 .. array_length(i_pos_s, 1)
    loop
      i_sour_arr[i_pos_s[v_cur][1]][i_pos_s[v_cur][2]][i_pos_s[v_cur][3]] := i_tar_ele;
    end loop;
  elsif array_ndims(i_sour_arr) = 4
  then
    for v_cur in 1 .. array_length(i_pos_s, 1)
    loop
      i_sour_arr[i_pos_s[v_cur][1]][i_pos_s[v_cur][2]][i_pos_s[v_cur][3]][i_pos_s[v_cur][4]] := i_tar_ele;
    end loop;
  end if;

  return i_sour_arr;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_pos_replaces(array['a', 'b', 'c'], array[1, 3], 'd')
-- select sm_sc.fv_pos_replaces(array[['a', 'b', 'c'], ['e', 'f', 'g']], array[[1, 3], [2, 2]], 'd')
-- select sm_sc.fv_pos_replaces(array[[['a', 'b', 'c'], ['e', 'f', 'g']], [['a', 'b', 'c'], ['e', 'f', 'g']]], array[[1, 2, 1], [2, 2, 2]], 'd')
-- select sm_sc.fv_pos_replaces(array[[[['a', 'b', 'c'], ['e', 'f', 'g']], [['a', 'b', 'c'], ['e', 'f', 'g']]], [[['a', 'b', 'c'], ['e', 'f', 'g']], [['a', 'b', 'c'], ['e', 'f', 'g']]]], array[[1, 2, 1, 2], [2, 2, 2, 1]], 'd')

-- ------------------------------------------------------------------
-- drop function if exists sm_sc.fv_pos_replaces(anyarray, int4range[], anyelement);
create or replace function sm_sc.fv_pos_replaces
(
  i_sour_arr     anyarray      ,
  i_pos_range_s  int4range[]   ,
  i_tar_ele      anyelement
)
returns anyarray
as
$$
declare -- here
  v_cur   int;
begin
  -- 审查
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_sour_arr) > 4
    then
      raise exception 'unsupport ndims of i_sour_arr.';
    elsif array_ndims(i_pos_range_s) > 2
      or array_ndims(i_sour_arr) = 1 and array_ndims(i_sour_arr) > 1
    then 
      raise exception 'unsupport ndims of i_pos_range_s.';
    elsif array_length(i_pos_range_s, 2) <> array_ndims(i_sour_arr)
      or array_ndims(i_pos_range_s) = 1 and array_length(i_pos_range_s, 1) <> array_ndims(i_sour_arr)
    then 
      raise exception 'unsupport length of i_pos_range_s.';
    end if;
  end if;
  
  -- 1d
  if array_ndims(i_sour_arr) = 1
  then
    for v_cur in 1 .. array_length(i_pos_range_s, 1)
    loop
      if i_pos_range_s[v_cur] is not null 
      then
        i_sour_arr
          [lower(i_pos_range_s[v_cur]) : upper(i_pos_range_s[v_cur]) -1] 
        := array_fill
           (
             i_tar_ele
           , array[upper(i_pos_range_s[v_cur]) - lower(i_pos_range_s[v_cur])]
           )
        ;
      end if;
    end loop;
  end if;

  -- 2d
  if array_ndims(i_sour_arr) = 2
  then
    for v_cur in 1 .. array_length(i_pos_range_s, 1)
    loop
      if i_pos_range_s[v_cur][1] is not null
        and i_pos_range_s[v_cur][2] is not null 
      then
        i_sour_arr
          [lower(i_pos_range_s[v_cur][1]) : upper(i_pos_range_s[v_cur][1]) -1]
          [lower(i_pos_range_s[v_cur][2]) : upper(i_pos_range_s[v_cur][2]) -1]  
        := array_fill
           (
             i_tar_ele
           , array
             [
               upper(i_pos_range_s[v_cur][1]) - lower(i_pos_range_s[v_cur][1])
             , upper(i_pos_range_s[v_cur][2]) - lower(i_pos_range_s[v_cur][2])
             ]
           )
        ;
      end if;
    end loop;
  elsif array_ndims(i_sour_arr) = 3
  then
    for v_cur in 1 .. array_length(i_pos_range_s, 1)
    loop
      if i_pos_range_s[v_cur][1] is not null
        and i_pos_range_s[v_cur][2] is not null 
        and i_pos_range_s[v_cur][3] is not null 
      then
        i_sour_arr
          [lower(i_pos_range_s[v_cur][1]) : upper(i_pos_range_s[v_cur][1]) -1]
          [lower(i_pos_range_s[v_cur][2]) : upper(i_pos_range_s[v_cur][2]) -1]
          [lower(i_pos_range_s[v_cur][3]) : upper(i_pos_range_s[v_cur][3]) -1]  
        := array_fill
           (
             i_tar_ele
           , array
             [
               upper(i_pos_range_s[v_cur][1]) - lower(i_pos_range_s[v_cur][1])
             , upper(i_pos_range_s[v_cur][2]) - lower(i_pos_range_s[v_cur][2])
             , upper(i_pos_range_s[v_cur][3]) - lower(i_pos_range_s[v_cur][3])
             ]
           )
        ;
      end if;
    end loop;
  elsif array_ndims(i_sour_arr) = 4
  then
    for v_cur in 1 .. array_length(i_pos_range_s, 1)
    loop
      if i_pos_range_s[v_cur][1] is not null
        and i_pos_range_s[v_cur][2] is not null 
        and i_pos_range_s[v_cur][3] is not null 
        and i_pos_range_s[v_cur][4] is not null 
      then
        i_sour_arr
          [lower(i_pos_range_s[v_cur][1]) : upper(i_pos_range_s[v_cur][1]) -1]
          [lower(i_pos_range_s[v_cur][2]) : upper(i_pos_range_s[v_cur][2]) -1]
          [lower(i_pos_range_s[v_cur][3]) : upper(i_pos_range_s[v_cur][3]) -1]
          [lower(i_pos_range_s[v_cur][4]) : upper(i_pos_range_s[v_cur][4]) -1]  
        := array_fill
           (
             i_tar_ele
           , array
             [
               upper(i_pos_range_s[v_cur][1]) - lower(i_pos_range_s[v_cur][1])
             , upper(i_pos_range_s[v_cur][2]) - lower(i_pos_range_s[v_cur][2])
             , upper(i_pos_range_s[v_cur][3]) - lower(i_pos_range_s[v_cur][3])
             , upper(i_pos_range_s[v_cur][4]) - lower(i_pos_range_s[v_cur][4])
             ]
           )
        ;
      end if;
    end loop;
  end if;

  return i_sour_arr;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_pos_replaces
--   (
--     array['a', 'b', 'c', 'e', 'f', 'g', 'h']
--   , array[int4range(1, 2, '[]'), int4range(4, 6, '[]')]
--   , 'd'
--   )

-- select 
--   sm_sc.fv_pos_replaces
--   (
--     array
--     [
--       ['a', 'b', 'c', 'e', 'f', 'g', 'h']
--     , ['a1', 'b1', 'c1', 'e1', 'f1', 'g1', 'h1']
--     ]
--   , array
--     [
--       [int4range(1, 2, '[]'), int4range(1, 2, '[]')]
--     , [int4range(2, 2, '[]'), int4range(4, 6, '[]')]
--     ]
--   , 'd2'
--   )

-- select 
--   sm_sc.fv_pos_replaces
--   (
--     array
--     [
--       [
--         ['a', 'b', 'c', 'e', 'f', 'g', 'h']
--       , ['a1', 'b1', 'c1', 'e1', 'f1', 'g1', 'h1']
--       ]
--     , [
--         ['a2', 'b2', 'c2', 'e2', 'f2', 'g2', 'h2']
--       , ['a3', 'b3', 'c3', 'e3', 'f3', 'g3', 'h3']
--       ]
--     , [
--         ['a4', 'b4', 'c4', 'e4', 'f4', 'g4', 'h4']
--       , ['a5', 'b5', 'c5', 'e5', 'f5', 'g5', 'h5']
--       ]
--     ]
--   , array
--     [
--       [int4range(1, 1, '[]'), int4range(1, 2, '[]'), int4range(1, 2, '[]')]
--     , [int4range(3, 3, '[]'), int4range(2, 2, '[]'), int4range(4, 6, '[]')]
--     ]
--   , 'd2'
--   )

-- select 
--   sm_sc.fv_pos_replaces
--   (
--     array
--     [
--       [
--         [
--           ['a', 'b', 'c', 'e', 'f', 'g', 'h']
--         , ['a1', 'b1', 'c1', 'e1', 'f1', 'g1', 'h1']
--         ]
--       , [
--           ['a2', 'b2', 'c2', 'e2', 'f2', 'g2', 'h2']
--         , ['a3', 'b3', 'c3', 'e3', 'f3', 'g3', 'h3']
--         ]
--       , [
--           ['a4', 'b4', 'c4', 'e4', 'f4', 'g4', 'h4']
--         , ['a5', 'b5', 'c5', 'e5', 'f5', 'g5', 'h5']
--         ]
--       ]
--     , [
--         [
--           ['a0', 'b0', 'c0', 'e0', 'f0', 'g0', 'h0']
--         , ['a6', 'b6', 'c6', 'e6', 'f6', 'g6', 'h6']
--         ]
--       , [
--           ['a7', 'b7', 'c7', 'e7', 'f7', 'g7', 'h7']
--         , ['a8', 'b8', 'c8', 'e8', 'f8', 'g8', 'h8']
--         ]
--       , [
--           ['a9', 'b9', 'c9', 'e9', 'f9', 'g9', 'h9']
--         , ['aj', 'bj', 'cj', 'ej', 'fj', 'gj', 'hj']
--         ]
--       ]
--     ]
--   , array
--     [
--       [int4range(1, 1, '[]'), int4range(1, 1, '[]'), int4range(1, 2, '[]'), int4range(1, 2, '[]')]
--     , [int4range(1, 2, '[]'), int4range(3, 3, '[]'), int4range(2, 2, '[]'), int4range(4, 6, '[]')]
--     ]
--   , 'dk'
--   )