-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_compare(anyarray, anyarray);
create or replace function sm_sc.fv_opr_compare
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns smallint[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     smallint[];
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if array_ndims(i_left) > 2 
    or array_ndims(i_right) > 2
    or array_ndims(i_left) = 1 
      and array_ndims(i_right) = 1 
      and array_length(i_left, 1) <> array_length(i_right, 1)
      and array_length(i_left, 1) <> 1
      and array_length(i_right, 1) <> 1
    or array_ndims(i_left) = 2 and array_ndims(i_right) = 2
      and array_length(i_left, 1) <> array_length(i_right, 1) 
      and array_length(i_left, 1) <> array_length(i_right, 2)
      and array_length(i_left, 2) <> array_length(i_right, 1)
      and array_length(i_left, 1) <> 1
      and array_length(i_right, 1) <> 1
      and array_length(i_left, 2) <> 1
      and array_length(i_right, 2) <> 1
  then
    raise exception 'no method!';
  end if;


  -- compare([][0], [][]) 或者 compare([0], [][])
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return array_fill(null::smallint, array[coalesce(array_length(i_right, 1), 0), coalesce(array_length(i_right, 2), 0)]);
  -- compare([][], [][0]) 或者 compare([][], [0])
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return array_fill(null::smallint, array[coalesce(array_length(i_left, 1), 0), coalesce(array_length(i_left, 2), 0)]);

  elsif i_left is null or i_right is null
  then
    return null::smallint[];

  -- compare([.], [])
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_compare(i_left[1], i_right);
  -- compare([], [.])
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_compare(i_left, i_right[1]);

  -- compare([[.]], [])
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_compare(i_left[1][1], i_right);
  -- compare([], [[.]])
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_compare(i_left, i_right[1][1]);

  -- compare([], [])
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      v_ret[v_y_cur] := sign(i_left[v_y_cur] - i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 compare([][], [][])
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    v_ret := array_fill(null::smallint, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left[v_y_cur][v_x_cur] - i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_left 需要延拓 compare([][1] , [][])
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    v_ret := array_fill(null::smallint, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left[v_y_cur][1] - i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_right 需要延拓 compare([][] , [][1])
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    v_ret := array_fill(null::smallint, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left[v_y_cur][v_x_cur] - i_right[v_y_cur][1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_left 需要延拓 compare([1][] , [][])
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    v_ret := array_fill(null::smallint, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left[1][v_x_cur] - i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_right 需要延拓 compare([][] , [1][])
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    v_ret := array_fill(null::smallint, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left[v_y_cur][v_x_cur] - i_right[1][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- 审计二维长度
  else
    return null; raise notice 'no method for such length!  L_Ndim: %; L_len_1: %; L_len_2: %; R_Ndim: %; R_len_1: %; R_len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2), array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_compare
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[1.3, 52.3], array[5.6, 45.6]]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[array[32.5], array[9.1]],
--     array[array[12.3, 2.3], array[45.6, 25.6]]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[array[12.3, 32.3], array[45.6, 15.6]],
--     array[array[12.5], array[19.1]]
--   );
-- -- select sm_sc.fv_opr_compare
-- --   (
-- --     array[3.5, 9.1],
-- --     array[array[2.3, 12.3], array[45.6, 4.6]]
-- --   );
-- -- select sm_sc.fv_opr_compare
-- --   (
-- --     array[array[12.3, 2.3], array[45.6, 5.6]],
-- --     array[12.5, 19.1]
-- --   );
-- select sm_sc.fv_opr_compare
--   (
--     array[array[3.5, 9.1]],
--     array[array[2.3, 12.3], array[45.6, 4.6]]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[12.5, 19.1]]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_compare
--   (
--     array[12.3, 2.3, 45.6],
--     array[12.5, 19.1, 5.6]
--   );
-- select sm_sc.fv_opr_compare(array[1], array[1,2,3]);
-- select sm_sc.fv_opr_compare(array[1], array[array[1,2,3]]);
-- select sm_sc.fv_opr_compare(array[array[1]], array[1,2,3]);
-- select sm_sc.fv_opr_compare(array[array[1]], array[array[1,2,3]]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_compare(anyarray, anyelement);
create or replace function sm_sc.fv_opr_compare
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns smallint[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     smallint[]   := case array_ndims(i_left) when 2 then array_fill(null::smallint, array[array_length(i_left, 1), array_length(i_left, 2)]) when 1 then array_fill(null::smallint, array[array_length(i_left, 1)]) else null::smallint[] end;
begin
  -- compare(null :: float[][], float) = null :: float[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return v_ret;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::smallint[];

  -- compare([][], float)
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left[v_y_cur][v_x_cur] - i_right);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- concat([], float)
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      v_ret[v_y_cur] := sign(i_left[v_y_cur] - i_right);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_compare(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_compare(array[12.3, 25.1, 2.56, 3.25], 8.8)
-- select sm_sc.fv_opr_compare(array[]::float[], 8.8)
-- select sm_sc.fv_opr_compare(array[array[], array []]::float[], 8.8)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_compare(anyelement, anyarray);
create or replace function sm_sc.fv_opr_compare
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns smallint[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     smallint[]   := case array_ndims(i_right) when 2 then array_fill(null::smallint, array[array_length(i_right, 1), array_length(i_right, 2)]) when 1 then array_fill(null::smallint, array[array_length(i_right, 1)]) else null::smallint[] end;
begin
  -- compare(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return v_ret;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::anyarray;

  -- compare(float + [][])
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sign(i_left - i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- compare(float, [])
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := sign(i_left - i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_compare(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_compare(8.8, array[12.3, 25.1, 2.56, 3.25])
-- select sm_sc.fv_opr_compare(8.8, array[]::float[] )
-- select sm_sc.fv_opr_compare(8.8, array[array[], array []]::float[])
