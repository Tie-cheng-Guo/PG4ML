-- set search_path to sm_sc;

-- -- 逻辑运算
-- drop function if exists sm_sc.fv_opr_xor(boolean[], boolean[]);
create or replace function sm_sc.fv_opr_xor
(
  i_left     boolean[]    ,
  i_right    boolean[]
)
returns boolean[]
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

  -- array[] xor []
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return i_right;
  -- [] xor array[]
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return i_left;

  elsif i_left is null or i_right is null
  then
    return null::boolean[];

  -- [.] xor []
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left[1], i_right);
  -- [] xor [.]
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left, i_right[1]);

  -- [[.]] xor []
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left[1][1], i_right);
  -- [] xor [[.]]
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left, i_right[1][1]);

  -- [] xor []
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := (i_left[v_y_cur] <> i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 [][] xor [][]
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_left[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] <> i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 横向广播，i_left 需要延拓 [][1] xor [][]
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := (i_left[v_y_cur][1] <> i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 横向广播，i_right 需要延拓 [][] xor [][1]
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] <> i_right[v_y_cur][1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 纵向广播 i_left 需要延拓 [1][] xor [][]
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := (i_left[1][v_x_cur] <> i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 纵向广播 i_right 需要延拓 [][] xor [1][]
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] <> i_right[1][v_x_cur]);
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
-- select sm_sc.fv_opr_xor
--   (
--     array[array[true, false], array[true, false]],
--     array[array[false, true], array[false, true]]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[true], array[false]],
--     array[array[false, true], array[false, true]]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[true, false], array[true, false]],
--     array[array[true], array[false]]
--   );
-- -- select sm_sc.fv_opr_xor
-- --   (
-- --     array[true, false],
-- --     array[array[false, true], array[false, true]]
-- --   );
-- -- select sm_sc.fv_opr_xor
-- --   (
-- --     array[array[true, false], array[true, false]],
-- --     array[true, false]
-- --   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[true, false]],
--     array[array[false, true], array[false, true]]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[true, false], array[true, false]],
--     array[array[true, false]]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[]::boolean[],
--     array[array[], array []]::boolean[]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[], array []]::boolean[],
--     array[]::boolean[]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[], array []]::boolean[],
--     array[array[], array []]::boolean[]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[true, false],
--     array[true, false]
--   );
-- select sm_sc.fv_opr_xor(array[true], array[true, false]);
-- select sm_sc.fv_opr_xor(array[true], array[array[true, false]]);
-- select sm_sc.fv_opr_xor(array[array[false]], array[true, false]);
-- select sm_sc.fv_opr_xor(array[array[false]], array[array[true, false]]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_xor(boolean[], boolean);
create or replace function sm_sc.fv_opr_xor
(
  i_left     boolean[]    ,
  i_right    boolean
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- null :: float[][] xor float = null :: float[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::boolean[];

  -- [][] xor float
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] <> i_right);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] xor float
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := (i_left[v_y_cur] <> i_right);
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
-- select sm_sc.fv_opr_xor(array[array[true, false], array[false, true]], false)
-- select sm_sc.fv_opr_xor(array[true, false], false)
-- select sm_sc.fv_opr_xor(array[]::boolean[], true)
-- select sm_sc.fv_opr_xor(array[array[], array []]::boolean[], false)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_xor(boolean, boolean[]);
create or replace function sm_sc.fv_opr_xor
(
  i_left     boolean    ,
  i_right    boolean[]
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- null :: float[][] xor float = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::boolean[];

  -- float xor [][]
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := (i_left <> i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- float xor []
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := (i_left <> i_right[v_y_cur]);
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
-- select sm_sc.fv_opr_xor(false, array[array[false, true], array[true, false]])
-- select sm_sc.fv_opr_xor(false, array[true, false])
-- select sm_sc.fv_opr_xor(false, array[]::boolean[] )
-- select sm_sc.fv_opr_xor(true, array[array[], array []]::boolean[])

-- -------------------------------------------------------------------------------------------------------------------------------

-- -- 位运算
-- drop function if exists sm_sc.fv_opr_xor(varbit[], varbit[]);
create or replace function sm_sc.fv_opr_xor
(
  i_left     varbit[]    ,
  i_right    varbit[]
)
returns varbit[]
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

  -- array[] # []
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return i_right;
  -- [] # array[]
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return i_left;

  elsif i_left is null or i_right is null
  then
    return null::varbit[];

  -- [.] # []
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left[1], i_right);
  -- [] # [.]
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left, i_right[1]);

  -- [[.]] # []
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left[1][1], i_right);
  -- [] # [[.]]
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_xor(i_left, i_right[1][1]);

  -- [] # []
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := i_left[v_y_cur] # i_right[v_y_cur];
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 [][] # [][]
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] # i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 横向广播，i_left 需要延拓 [][1] # [][]
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := i_left[v_y_cur][1] # i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 横向广播，i_right 需要延拓 [][] # [][1]
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] # i_right[v_y_cur][1];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 纵向广播 i_left 需要延拓 [1][] # [][]
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := i_left[1][v_x_cur] # i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 纵向广播 i_right 需要延拓 [][] # [1][]
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] # i_right[1][v_x_cur];
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
-- select sm_sc.fv_opr_xor
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[B'011', B'101'], array[B'011', B'101']]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[B'010'], array[B'011']],
--     array[array[B'011', B'101'], array[B'011', B'101']]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[B'101'], array[B'011']]
--   );
-- -- select sm_sc.fv_opr_xor
-- --   (
-- --     array[B'101', B'011'],
-- --     array[array[B'011', B'101'], array[B'011', B'010']]
-- --   );
-- -- select sm_sc.fv_opr_xor
-- --   (
-- --     array[array[B'101', B'011'], array[B'101', B'011']],
-- --     array[B'010', B'011']
-- --   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[B'101', B'011']],
--     array[array[B'011', B'101'], array[B'011', B'010']]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[B'101', B'011'], array[B'101', B'011']],
--     array[array[B'010', B'011']]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[]::varbit[],
--     array[array[], array []]::varbit[]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[], array []]::varbit[],
--     array[]::varbit[]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[array[], array []]::varbit[],
--     array[array[], array []]::varbit[]
--   );
-- select sm_sc.fv_opr_xor
--   (
--     array[B'101', B'011'],
--     array[B'010', B'011']
--   );
-- select sm_sc.fv_opr_xor(array[B'101'], array[B'101', B'011']);
-- select sm_sc.fv_opr_xor(array[B'101'], array[array[B'101', B'011']]);
-- select sm_sc.fv_opr_xor(array[array[B'011']], array[B'101', B'011']);
-- select sm_sc.fv_opr_xor(array[array[B'011']], array[array[B'101', B'011']]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_xor(varbit[], varbit);
create or replace function sm_sc.fv_opr_xor
(
  i_left     varbit[]    ,
  i_right    varbit
)
returns varbit[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- null :: varbit[][] # varbit = null :: varbit[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::varbit[];

  -- [][] # varbit
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] # i_right;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] # varbit
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := i_left[v_y_cur] # i_right;
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
-- select sm_sc.fv_opr_xor(array[array[B'010', B'011'], array[B'011', B'010']], B'011')
-- select sm_sc.fv_opr_xor(array[B'010011', B'011010'], B'011101')
-- select sm_sc.fv_opr_xor(array[]::varbit[], B'010')
-- select sm_sc.fv_opr_xor(array[array[], array []]::varbit[], B'011')

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_xor(varbit, varbit[]);
create or replace function sm_sc.fv_opr_xor
(
  i_left     varbit    ,
  i_right    varbit[]
)
returns varbit[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- null :: varbit[][] # varbit = null :: varbit[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::varbit[];

  -- varbit # [][]
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := i_left # i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- varbit # []
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := i_left # i_right[v_y_cur];
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
-- select sm_sc.fv_opr_xor(B'110', array[array[B'011', B'010'], array[B'101', B'110']])
-- select sm_sc.fv_opr_xor(B'011101', array[B'010011', B'011010'])
-- select sm_sc.fv_opr_xor(B'011', array[]::varbit[] )
-- select sm_sc.fv_opr_xor(B'010', array[array[], array []]::varbit[])
