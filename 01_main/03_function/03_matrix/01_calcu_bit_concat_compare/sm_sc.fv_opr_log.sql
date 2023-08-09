-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_log(anyarray, anyarray);
create or replace function sm_sc.fv_opr_log
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;  -- -- -- 从 0 开始游标，避免(array[]::float[])[1]
  v_y_cur   int  := 1  ;
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

  -- log(array[], [])
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return i_right;
  -- log([], array[])
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return i_left;

  elsif i_left is null or i_right is null
  then
    return null::anyarray;

  -- log([.], [])
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_log(i_left[1], i_right);
  -- log([], [.])
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_log(i_left, i_right[1]);

  -- log([[.]], [])
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_log(i_left[1][1], i_right);
  -- log([], [[.]])
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_log(i_left, i_right[1][1]);

  -- log([], [])
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := log(i_left[v_y_cur] :: decimal, i_right[v_y_cur] :: decimal);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 log([][], [][])
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_left[v_y_cur][v_x_cur] := log(i_left[v_y_cur][v_x_cur] :: decimal, i_right[v_y_cur][v_x_cur] :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 横向广播，i_left 需要延拓 log([][1], [][])
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := log(i_left[v_y_cur][1] :: decimal, i_right[v_y_cur][v_x_cur] :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 横向广播，i_right 需要延拓 log([][], [][1])
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := log(i_left[v_y_cur][v_x_cur] :: decimal, i_right[v_y_cur][1] :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 纵向广播 i_left 需要延拓 log([1][], [][])
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := log(i_left[1][v_x_cur] :: decimal, i_right[v_y_cur][v_x_cur] :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 纵向广播 i_right 需要延拓 log([][], [1][])
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := log(i_left[v_y_cur][v_x_cur] :: decimal, i_right[1][v_x_cur] :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 审计二维长度
  else
    return null; raise notice 'no method for such length!  L_Ndim: %; L_len_1: %; L_len_2: %; R_Ndim: %; R_len_1: %; R_len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2), array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_log
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[1.3, 52.3], array[5.6, 45.6]]
--   );
-- select sm_sc.fv_opr_log
--   (
--     array[array[32.5], array[9.1]],
--     array[array[12.3, 2.3], array[45.6, 25.6]]
--   );
-- select sm_sc.fv_opr_log
--   (
--     array[array[12.3, 32.3], array[45.6, 15.6]],
--     array[array[12.5], array[19.1]]
--   );
-- -- select sm_sc.fv_opr_log
-- --   (
-- --     array[3.5, 9.1],
-- --     array[array[2.3, 12.3], array[45.6, 4.6]]
-- --   );
-- -- select sm_sc.fv_opr_log
-- --   (
-- --     array[array[12.3, 2.3], array[45.6, 5.6]],
-- --     array[12.5, 19.1]
-- --   );
-- select sm_sc.fv_opr_log
--   (
--     array[array[3.5, 9.1]],
--     array[array[2.3, 12.3], array[45.6, 4.6]]
--   );
-- select sm_sc.fv_opr_log
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[12.5, 19.1]]
--   );
-- select sm_sc.fv_opr_log
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_log
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_log
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_log(array[12.3], array[45.6, 5.6]);
-- select sm_sc.fv_opr_log(array[12.3], array[array[45.6, 5.6]]);
-- select sm_sc.fv_opr_log(array[array[12.3]], array[45.6, 5.6]);
-- select sm_sc.fv_opr_log(array[array[12.3]], array[array[45.6, 5.6]]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_log(anyarray, anyelement);
create or replace function sm_sc.fv_opr_log
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- log(null :: float[][], float = null :: float[][])
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::anyarray;

  -- log([][], float)
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := log(i_left[v_y_cur][v_x_cur] :: decimal, i_right :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- log([], float)
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := log(i_left[v_y_cur] :: decimal, i_right :: decimal);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2);
  end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_opr_log(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_log(array[]::float[], 8.8)
-- select sm_sc.fv_opr_log(array[array[], array []]::float[], 8.8)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_log(anyelement, anyarray);
create or replace function sm_sc.fv_opr_log
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- log(null :: float[][], float = null :: float[][])
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::anyarray;

  -- log(float, [][])
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := log(i_left :: decimal, i_right[v_y_cur][v_x_cur] :: decimal);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- log(float, [])
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := log(i_left :: decimal, i_right[v_y_cur] :: decimal);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_opr_log(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_log(8.8, array[]::float[] )
-- select sm_sc.fv_opr_log(8.8, array[array[], array []]::float[])