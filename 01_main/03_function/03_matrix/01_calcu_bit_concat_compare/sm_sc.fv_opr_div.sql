-- drop function if exists sm_sc.fv_div_for_zero(float, float);
create or replace function sm_sc.fv_div_for_zero
(
  i_left       float   ,
  i_right      float
)
returns float
as 
$$
begin 
  return 
    coalesce 
    (
      i_left / nullif(i_right, 0.0 :: float),
      case
        when i_left > 0.0
          then 1e+128
        when i_left < 0.0
          then -1e+128
        when i_left = 0.0
          then 0.0
      end
    )
  ;
end
$$
language plpgsql;

-- drop function if exists sm_sc.fv_div_for_zero(anyelement, anyelement);
create or replace function sm_sc.fv_div_for_zero
(
  i_left       anyelement   ,
  i_right      anyelement
)
returns anyelement
as 
$$
begin 
  return 
    i_left / i_right
  ;
end
$$
language plpgsql;

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_div(anyarray, anyarray);
create or replace function sm_sc.fv_opr_div
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
  v_val_0   alias for $0;
begin
  v_val_0 := array[0.0 :: float];
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

  -- array[] / []
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return i_right;
  -- [] / array[]
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return i_left;

  elsif i_left is null or i_right is null
  then
    return null::anyarray;

  -- [.] / []
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_div(i_left[1], i_right);
  -- [] / [.]
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_div(i_left, i_right[1]);

  -- [[.]] / []
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_div(i_left[1][1], i_right);
  -- [] / [[.]]
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_div(i_left, i_right[1][1]);

  -- [] / []
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur], i_right[v_y_cur]);   -- i_left[v_y_cur] / nullif(i_right[v_y_cur], v_val_0[1]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 [][] / [][]
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_left[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur][v_x_cur], i_right[v_y_cur][v_x_cur]);   -- i_left[v_y_cur][v_x_cur] / nullif(i_right[v_y_cur][v_x_cur], v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 横向广播，i_left 需要延拓 [][1] / [][]
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur][1], i_right[v_y_cur][v_x_cur]);   -- i_left[v_y_cur][1] / nullif(i_right[v_y_cur][v_x_cur], v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 横向广播，i_right 需要延拓 [][] / [][1]
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur][v_x_cur], i_right[v_y_cur][1]);   -- i_left[v_y_cur][v_x_cur] / nullif(i_right[v_y_cur][1], v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 纵向广播 i_left 需要延拓 [1][] / [][]
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left[1][v_x_cur], i_right[v_y_cur][v_x_cur]);   -- i_left[1][v_x_cur] / nullif(i_right[v_y_cur][v_x_cur], v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 纵向广播 i_right 需要延拓 [][] / [1][]
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur][v_x_cur], i_right[1][v_x_cur]);   -- i_left[v_y_cur][v_x_cur] / nullif(i_right[1][v_x_cur], v_val_0[1]);
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
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_div
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[32.5], array[-9.1]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[12.5], array[-19.1]]
--   );
-- -- select sm_sc.fv_opr_div    -- 设计不支持一维二维混合运算
-- --   (
-- --     array[32.5, -9.1],
-- --     array[array[-12.3, 12.3], array[-45.6, 45.6]]
-- --   );
-- -- select sm_sc.fv_opr_div    -- 设计不支持一维二维混合运算
-- --   (
-- --     array[array[12.3, -12.3], array[45.6, -45.6]],
-- --     array[12.5, -19.1]
-- --   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[32.5, -9.1]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[12.5, -19.1]]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[1.2, 2.3]::float[],
--     array[2.1, 3.2]::float[]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[(1.2, 2.3)::sm_sc.typ_l_complex],
--     array[(2.1, 3.2)::sm_sc.typ_l_complex]
--   );
-- select sm_sc.fv_opr_div
--   (
--     array[array[(1.2, 2.3)::sm_sc.typ_l_complex]],
--     array[array[(2.1, 3.2)::sm_sc.typ_l_complex]]
--   );
-- select sm_sc.fv_opr_div(array[1]::float[], array[1,2,3]::float[]);
-- select sm_sc.fv_opr_div(array[1]::float[], array[array[1,2,3]]::float[]);
-- select sm_sc.fv_opr_div(array[array[1]]::float[], array[1,2,3]::float[]);
-- select sm_sc.fv_opr_div(array[array[1]]::float[], array[array[1,2,3]]::float[]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_div(anyarray, anyelement);
create or replace function sm_sc.fv_opr_div
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
  v_val_0   alias for $0;
begin
  v_val_0 := array[0.0 :: float];
  -- null :: float[][] / float = null :: float[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::anyarray;

  -- [][] / float
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur][v_x_cur], i_right);   -- i_left[v_y_cur][v_x_cur] / nullif(i_right, v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] / float
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := sm_sc.fv_div_for_zero(i_left[v_y_cur], i_right);   -- i_left[v_y_cur] / nullif(i_right, v_val_0[1]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_div(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_div(array[]::float[], 8.8)
-- select sm_sc.fv_opr_div(array[]::float[], null)
-- select sm_sc.fv_opr_div(array[1.2, 2.3]::float[], 8.8)
-- select sm_sc.fv_opr_div(array[array[], array []]::float[], 8.8)
-- select sm_sc.fv_opr_div(array[1.2, 2.3]::float[], null::float)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_div(anyelement, anyarray);
create or replace function sm_sc.fv_opr_div
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
  v_val_0   alias for $0;
begin
  v_val_0 := array[0.0 :: float];
  -- null :: float[][] / float = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::anyarray;

  -- float / [][]
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(i_left, i_right[v_y_cur][v_x_cur]);   -- i_left / nullif(i_right[v_y_cur][v_x_cur], v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- float / []
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := sm_sc.fv_div_for_zero(i_left, i_right[v_y_cur]);   -- i_left / nullif(i_right[v_y_cur], v_val_0[1]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_div(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_div(8.8, array[]::float[] )
-- select sm_sc.fv_opr_div(null, array[]::float[])
-- select sm_sc.fv_opr_div(8.8, array[1.2, 2.3]::float[] )
-- select sm_sc.fv_opr_div(8.8, array[array[], array []]::float[])
-- select sm_sc.fv_opr_div(null::float, array[1.2, 2.3]::float[] )
-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_div(anyarray);
create or replace function sm_sc.fv_opr_div
(
  i_right    anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_val_0   alias for $0;
begin
  v_val_0 := array[0.0 :: float];
  -- / [][]
  if array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := sm_sc.fv_div_for_zero(1.0 :: float, i_right[v_y_cur][v_x_cur]);   -- 1.0 :: float/ nullif(i_right[v_y_cur][v_x_cur], v_val_0[1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- / []
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := sm_sc.fv_div_for_zero(1.0 :: float, i_right[v_y_cur]);   -- 1.0 :: float/ nullif(i_right[v_y_cur], v_val_0[1]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_div(array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_div(array[12.3, 25.1, 2.56, 3.25])

