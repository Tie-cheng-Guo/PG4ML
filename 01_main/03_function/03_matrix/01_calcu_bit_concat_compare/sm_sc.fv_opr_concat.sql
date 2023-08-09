-- drop function if exists sm_sc.fv_opr_concat(varbit[], varbit[]);
create or replace function sm_sc.fv_opr_concat
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

  -- concat(array[], [])
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return i_right;
  -- concat([], array[])
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return i_left;

  elsif i_left is null or i_right is null
  then
    return null::anyarray;

  -- concat([.], [])
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_concat(i_left[1], i_right);
  -- concat([], [.])
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_concat(i_left, i_right[1]);

  -- concat([[.]], [])
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_concat(i_left[1][1], i_right);
  -- concat([], [[.]])
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_concat(i_left, i_right[1][1]);

  -- concat([], [])
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := concat(i_left[v_y_cur], i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 concat([][], [][])
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_left[v_y_cur][v_x_cur] := concat(i_left[v_y_cur][v_x_cur], i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 横向广播，i_left 需要延拓 concat([][1], [][])
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := concat(i_left[v_y_cur][1], i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 横向广播，i_right 需要延拓 concat([][], [][1])
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := concat(i_left[v_y_cur][v_x_cur], i_right[v_y_cur][1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 纵向广播 i_left 需要延拓 concat([1][], [][])
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := concat(i_left[1][v_x_cur], i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 纵向广播 i_right 需要延拓 concat([][], [1][])
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := concat(i_left[v_y_cur][v_x_cur], i_right[1][v_x_cur]);
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
-- select sm_sc.fv_opr_concat
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[B'011', B'101'], array[B'011', B'101']]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[array[B'010'], array[B'011']],
--     array[array[B'011', B'101'], array[B'011', B'101']]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[B'101'], array[B'011']]
--   );
-- -- select sm_sc.fv_opr_concat
-- --   (
-- --     array[B'101', B'011'],
-- --     array[array[B'011', B'101'], array[B'011', B'010']]
-- --   );
-- -- select sm_sc.fv_opr_concat
-- --   (
-- --     array[array[B'101', B'011'], array[B'101', B'011']],
-- --     array[B'010', B'011']
-- --   );
-- select sm_sc.fv_opr_concat
--   (
--     array[array[B'101', B'011']],
--     array[array[B'011', B'101'], array[B'011', B'010']]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[array[B'101', B'011'], array[B'101', B'011']],
--     array[array[B'010', B'011']]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[]::varbit[],
--     array[array[], array []]::varbit[]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[array[], array []]::varbit[],
--     array[]::varbit[]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[array[], array []]::varbit[],
--     array[array[], array []]::varbit[]
--   );
-- select sm_sc.fv_opr_concat
--   (
--     array[B'101', B'011'],
--     array[B'010', B'011']
--   );
-- select sm_sc.fv_opr_concat(array[B'101'], array[B'101', B'011']);
-- select sm_sc.fv_opr_concat(array[B'101'], array[array[B'101', B'011']]);
-- select sm_sc.fv_opr_concat(array[array[B'101']], array[B'101', B'011']);
-- select sm_sc.fv_opr_concat(array[array[B'101']], array[array[B'101', B'011']]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat(anyarray, anyelement);
create or replace function sm_sc.fv_opr_concat
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
  -- concat(null :: float[][], float = null :: float[][])
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::anyarray;

  -- concat([][], float)
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := concat(i_left[v_y_cur][v_x_cur], i_right);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- concat([], float)
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := concat(i_left[v_y_cur], i_right);
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
-- select sm_sc.fv_opr_concat(array[array[B'010', B'011'], array[B'011', B'010']], B'011')
-- select sm_sc.fv_opr_concat(array[B'010011', B'011010'], B'011101')
-- select sm_sc.fv_opr_concat(array[]::varbit[], B'010')
-- select sm_sc.fv_opr_concat(array[array[], array []]::varbit[], B'011')

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_concat(anyelement, anyarray);
create or replace function sm_sc.fv_opr_concat
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
  -- concat(null :: float[][], float = null :: float[][])
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::anyarray;

  -- concat(float, [][])
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := concat(i_left, i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- less(float, [])
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := concat(i_left, i_right[v_y_cur]);
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
-- select sm_sc.fv_opr_concat(B'110', array[array[B'011', B'010'], array[B'101', B'110']])
-- select sm_sc.fv_opr_concat(B'011101', array[B'010011', B'011010'])
-- select sm_sc.fv_opr_concat(B'011', array[]::varbit[] )
-- select sm_sc.fv_opr_concat(B'010', array[array[], array []]::varbit[])
