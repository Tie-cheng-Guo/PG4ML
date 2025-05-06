-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_apad(anyarray, anyarray, int);
create or replace function sm_sc.fv_apad
(
  i_array            anyarray      ,
  i_fill_values      anyarray      , -- 如果用 default 值，那么参数的伪类型不易支持，那么分为两个入参不同的重载函数
  i_times            int        default  1   
)
returns anyarray
as
$$
declare 
  v_fill_values    i_array%type  := i_fill_values;
begin
  -- set search_path to sm_sc;
  if i_array is null 
  then 
    return null;
  end if;
  
  -- if v_fill_values is null 
  -- then 
  --   if array_ndims(i_array) = 1
  --   then 
  --     v_fill_values := array[nullif(i_array[1], i_array[1])];
  --   elsif array_ndims(i_array) = 2
  --   then
  --     v_fill_values := array[[nullif(i_array[1][1], i_array[1][1])]];
  --   elsif array_ndims(i_array) = 3
  --   then 
  --     v_fill_values := array_fill(nullif(i_array[1][1][1], i_array[1][1][1]), array[array_length(i_array, 1), 1, array_length(i_array, 3)]);
  --   elsif array_ndims(i_array) = 4
  --   then 
  --     v_fill_values := array_fill(nullif(i_array[1][1][1][1], i_array[1][1][1][1]), array[array_length(i_array, 1), array_length(i_array, 2), 1, array_length(i_array, 4)]);
  --   end if;
  -- end if;

  if i_times <= 0
  then
    return i_array;
  elsif array_ndims(i_array) <> array_ndims(v_fill_values)
  then 
    raise exception 'ndims of i_array: % and i_fill_values: % should be the same.', array_ndims(i_array), array_ndims(v_fill_values);
  elsif array_ndims(i_array) = 1
  then 
    return
      (
        select 
          sm_sc.fa_array_concat(v_fill_values)
        from generate_series(1, i_times)
      )
      || i_array
    ;
  elsif array_ndims(i_array) = 2
  then 
    if array_length(v_fill_values, 2) not in (1, array_length(i_array, 2))
    then 
      raise exception 'width of 2d i_fill_values should be 1 or the same as 2d i_array''s. ';
    else
      return
        (
          select 
            sm_sc.fa_mx_concat_y(v_fill_values)
          from generate_series(1, i_times)
        )
        |-|| i_array
      ;
    end if;
  elsif array_ndims(i_array) = 3
  then 
    if array_length(v_fill_values, 1) not in (1, array_length(i_array, 1))
      or array_length(v_fill_values, 3) not in (1, array_length(i_array, 3))
    then 
      raise exception 'width of 2d i_fill_values should be 1 or the same as 2d i_array''s. ';
    else
      return
        (
          select 
            sm_sc.fa_mx_concat_x(v_fill_values)
          from generate_series(1, i_times)
        )
        |-|| i_array
      ;
    end if;
  elsif array_ndims(i_array) = 4
  then 
    if array_length(v_fill_values, 1) not in (1, array_length(i_array, 1))
      or array_length(v_fill_values, 2) not in (1, array_length(i_array, 2))
      or array_length(v_fill_values, 4) not in (1, array_length(i_array, 4))
    then 
      raise exception 'width of 3d i_fill_values should be the same as 3d i_array''s. ';
    else
      return
        (
          select 
            sm_sc.fa_mx_concat_x3(v_fill_values)
          from generate_series(1, i_times)
        )
        |-|| i_array
      ;
    end if;
  else 
    raise exception 'no method for ndims = %.', array_ndims(i_array);
  end if;
end
$$
language plpgsql stable
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_apad
--   (
--     array[1, 2, 3, 4, 5, 6],
--     array[7, 8],
--     2
--   );
-- select sm_sc.fv_apad
--   (
--     array[array[1, 2, 3, 4, 5, 6], array[-1, -2, -3, -4, -5, -6]],
--     array[array[7], array[8]],
--     2
--   );
-- select sm_sc.fv_apad
--   (
--     array[array[1.0 :: float, -1], array[2, -2], array[3, -3], array[4, -4], array[5, -5], array[6, -6]],
--     array[array[7, 8], array[9, 10]] :: float[],
--     2
--   );
-- select sm_sc.fv_apad
--   (
--     array[array[1, -1], array[2, -2], array[3, -3], array[4, -4], array[5, -5], array[6, -6]],
--     array[array[7], array[8]],
--     2
--   );
-- select sm_sc.fv_apad
--   (
--     array[array[1.0 :: float, -1], array[2, -2], array[3, -3], array[4, -4], array[5, -5], array[6, -6]],
--     array[array[null :: float]],
--     2
--   );
-- select 
--   sm_sc.fv_apad
--   (
--     array[[[1, -1],[2, -2],[3, -3],[4, -4],[5, -5],[6, -6],[21, -21],[22, -22],[23, -23],[24, -24],[25, -25],[26, -26]]]
--   , array[[[7, -7],[8, -8],[9, -9],[10, -10],[11, -11],[12, -12]]]
--   , 2
--   );
-- select 
--   sm_sc.fv_apad
--   (
--     array[[[[1, -1],[2, -2],[3, -3],[4, -4],[5, -5],[6, -6],[21, -21],[22, -22],[23, -23],[24, -24],[25, -25],[26, -26]]],[[[1, -1],[2, -2],[3, -3],[4, -4],[5, -5],[6, -6],[21, -21],[22, -22],[23, -23],[24, -24],[25, -25],[26, -26]]]]
--   , array[[[[7, -7],[8, -8],[9, -9],[10, -10],[11, -11],[12, -12]]],[[[7, -7],[8, -8],[9, -9],[10, -10],[11, -11],[12, -12]]]]
--   , 2
--   );


-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_apad(anyarray, int);
create or replace function sm_sc.fv_apad
(
  i_array            anyarray      ,
  i_times            int   default 1
)
returns anyarray
as
$$
declare 
  v_fill_values    i_array%type;
begin
  if array_ndims(i_array) = 1
  then 
    v_fill_values := array[nullif(i_array[1], i_array[1])];
  elsif array_ndims(i_array) = 2
  then
    v_fill_values := array[[nullif(i_array[1][1], i_array[1][1])]];
  elsif array_ndims(i_array) = 3
  then 
    v_fill_values := array_fill(nullif(i_array[1][1][1], i_array[1][1][1]), array[array_length(i_array, 1), 1, array_length(i_array, 3)]);
  elsif array_ndims(i_array) = 4
  then 
    v_fill_values := array_fill(nullif(i_array[1][1][1][1], i_array[1][1][1][1]), array[array_length(i_array, 1), array_length(i_array, 2), 1, array_length(i_array, 4)]);
  end if;

  return sm_sc.fv_apad(i_array, v_fill_values, i_times);

end
$$
language plpgsql stable
cost 100;


-- select sm_sc.fv_apad
--   (
--     array[1, 2, 3, 4, 5, 6],
--     2
--   );
-- select sm_sc.fv_apad
--   (
--     array[array[1, 2, 3, 4, 5, 6], array[-1, -2, -3, -4, -5, -6]],
--     2
--   );
-- select sm_sc.fv_apad
--   (
--     array[array[1.0 :: float, -1], array[2, -2], array[3, -3], array[4, -4], array[5, -5], array[6, -6]],
--     2
--   );
-- select 
--   sm_sc.fv_apad
--   (
--     array[[[1, -1],[2, -2],[3, -3],[4, -4],[5, -5],[6, -6],[21, -21],[22, -22],[23, -23],[24, -24],[25, -25],[26, -26]]]
--   , 2
--   );
-- select 
--   sm_sc.fv_apad
--   (
--     array[[[[1, -1],[2, -2],[3, -3],[4, -4],[5, -5],[6, -6],[21, -21],[22, -22],[23, -23],[24, -24],[25, -25],[26, -26]]],[[[1, -1],[2, -2],[3, -3],[4, -4],[5, -5],[6, -6],[21, -21],[22, -22],[23, -23],[24, -24],[25, -25],[26, -26]]]]
--   , 2
--   );