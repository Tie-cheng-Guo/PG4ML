-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_upper_tri_mx(anyarray, anyelement);
create or replace function sm_sc.fv_upper_tri_mx
(
  i_array            anyarray      ,
  i_lower_fill_value anyelement        -- 如果用 default 值，那么参数的伪类型不易支持，那么分为两个入参不同的重载函数
)
returns anyarray
as
$$
declare 
  v_lower_fill_value    i_lower_fill_value%type  := i_lower_fill_value;
  v_array_heigh         int                      := array_length(i_array, array_ndims(i_array) - 1);
  v_array_width         int                      := array_length(i_array, array_ndims(i_array));
  v_array_len_y         int                      := array_length(i_array, 1);
  v_array_len_x         int                      := array_length(i_array, 2);
begin
  -- set search_path to sm_sc;
  
  if i_array is null 
  then 
    return null;
  end if;
  
  if v_lower_fill_value is null and array_ndims(i_array) = 1
  then 
    v_lower_fill_value := nullif(i_array[1], i_array[1]);
  elsif v_lower_fill_value is null and array_ndims(i_array) = 2
  then
    v_lower_fill_value := nullif(i_array[1][1], i_array[1][1]);
  elsif v_lower_fill_value is null and array_ndims(i_array) = 3
  then
    v_lower_fill_value := nullif(i_array[1][1][1], i_array[1][1][1]);
  elsif v_lower_fill_value is null and array_ndims(i_array) = 4
  then
    v_lower_fill_value := nullif(i_array[1][1][1][1], i_array[1][1][1][1]);
  end if;

  if array_ndims(i_array) = 2
  then 
    for v_cur in 1 .. case when v_array_width >= v_array_heigh then least(v_array_heigh, v_array_width) - 1 else least(v_array_heigh, v_array_width) end
    loop 
      i_array
        [v_cur + 1 : ] 
        [v_cur : v_cur]
      := 
        array_fill
        (
          v_lower_fill_value
        , array
          [
            v_array_heigh - v_cur
          , 1
          ]
        )
      ;
    end loop;
  elsif array_ndims(i_array) = 3
  then 
    for v_cur in 1 .. case when v_array_width >= v_array_heigh then least(v_array_heigh, v_array_width) - 1 else least(v_array_heigh, v_array_width) end
    loop 
      i_array
        [ : ]
        [v_cur + 1 : ] 
        [v_cur : v_cur]
      := 
        array_fill
        (
          v_lower_fill_value
        , array
          [
            v_array_len_y
          , v_array_heigh - v_cur
          , 1
          ]
        )
      ;
    end loop;
  elsif array_ndims(i_array) = 4
  then 
    for v_cur in 1 .. case when v_array_width >= v_array_heigh then least(v_array_heigh, v_array_width) - 1 else least(v_array_heigh, v_array_width) end
    loop 
      i_array
        [ : ]
        [ : ]
        [v_cur + 1 : ] 
        [v_cur : v_cur]
      := 
        array_fill
        (
          v_lower_fill_value
        , array
          [
            v_array_len_y
          , v_array_len_x
          , v_array_heigh - v_cur
          , 1
          ]
        )
      ;
    end loop;
  else 
    raise exception 'no method for ndims = %.', array_ndims(i_array);
  end if;
  
  return i_array;
end
$$
language plpgsql stable
cost 100;

-- -- set search_path to sm_sc;
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array[[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array[[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array[[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     ]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--     , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--     , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--     ]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--     , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--     , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--     ]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [
--         [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       ]
--     , [
--         [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       ]
--     ]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [
--         [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       ]
--     , [
--         [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       ]
--     ]
--   , 0
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [
--         [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       ]
--     , [
--         [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       ]
--     ]
--   , 0
--   );


-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_upper_tri_mx(anyarray);
create or replace function sm_sc.fv_upper_tri_mx
(
  i_array            anyarray
)
returns anyarray
as
$$
-- declare 
begin
  return sm_sc.fv_upper_tri_mx(i_array, null);
end
$$
language plpgsql stable
cost 100;

-- -- set search_path to sm_sc;
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array[[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array[[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array[[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     ]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--     , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--     , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--     ]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--     , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--     , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--     ]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [
--         [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       ]
--     , [
--         [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--       ]
--     ]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [
--         [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       ]
--     , [
--         [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       ]
--     ]
--   );
-- select 
--   sm_sc.fv_upper_tri_mx
--   (
--     array
--     [
--       [
--         [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       ]
--     , [
--         [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       , [[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--       ]
--     ]
--   );
