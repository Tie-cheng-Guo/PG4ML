-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_is_regexp_match(text[], text[]);
create or replace function sm_sc.fv_opr_is_regexp_match
(
  i_left     text[]    ,
  i_right    text[]
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     boolean[];
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

  -- ([][0] ~ [][]) 或者 ([0] ~ [][])
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return array_fill(null::boolean, array[coalesce(array_length(i_right, 1), 0), coalesce(array_length(i_right, 2), 0)]);
  -- ([][] ~ [][0]) 或者 less([][] ~ [0])
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return array_fill(null::boolean, array[coalesce(array_length(i_left, 1), 0), coalesce(array_length(i_left, 2), 0)]);

  elsif i_left is null or i_right is null
  then
    return null::boolean[];

  -- ([.] ~ [])
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_is_regexp_match(i_left[1], i_right);
  -- ([] ~ [.])
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_is_regexp_match(i_left, i_right[1]);

  -- ([[.]] ~ [])
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_is_regexp_match(i_left[1][1], i_right);
  -- ([] ~ [[.]])
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_is_regexp_match(i_left, i_right[1][1]);

  -- ([] ~ [])
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      v_ret[v_y_cur] := (i_left[v_y_cur] ~ i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 ([][] ~ [][])
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] ~ i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_left 需要延拓 ([][1] ~ [][])
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    v_ret := array_fill(null::boolean, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][1] ~ i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_right 需要延拓 ([][] ~ [][1])
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] ~ i_right[v_y_cur][1]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_left 需要延拓 ([1][] ~ [][])
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    v_ret := array_fill(null::boolean, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[1][v_x_cur] ~ i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_right 需要延拓 ([][] ~ [1][])
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] ~ i_right[1][v_x_cur]);
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
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array['abbbbbc122223'], array['abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array[a.c], array[1.*?3]]
--   );
-- -- select sm_sc.fv_opr_is_regexp_match
-- --   (
-- --     array['abbbbbc122223', 'abc123'],
-- --     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
-- --   );
-- -- select sm_sc.fv_opr_is_regexp_match
-- --   (
-- --     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
-- --     array['1.3', 'a.*?c']
-- --   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array['abbbbbc122223', 'abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[]::text[],
--     array[array[], array []]::text[]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array[], array []]::text[],
--     array[]::text[]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array[array[], array []]::text[],
--     array[array[], array []]::text[]
--   );
-- select sm_sc.fv_opr_is_regexp_match
--   (
--     array['abbbbbc122223', 'abc123', 'abc123', 'ac13'],
--     array['a.c', '1.*?3', '1.3', 'a.*?c']
--   );
-- select sm_sc.fv_opr_is_regexp_match(array[1], array[1,2,3]);
-- select sm_sc.fv_opr_is_regexp_match(array[1], array[array[1,2,3]]);
-- select sm_sc.fv_opr_is_regexp_match(array[array[1]], array[1,2,3]);
-- select sm_sc.fv_opr_is_regexp_match(array[array[1]], array[array[1,2,3]]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_regexp_match(text[], text);
create or replace function sm_sc.fv_opr_is_regexp_match
(
  i_left     text[]    ,
  i_right    text
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     boolean[]   := case array_ndims(i_left) when 2 then array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2)]) when 1 then array_fill(null::boolean, array[array_length(i_left, 1)]) else null::boolean[] end;
begin
  -- (null :: text[][] ~ text) = null :: text[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return v_ret;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::boolean[];

  -- ([][] ~ text)
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] ~ i_right);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- ([] ~ text)
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      v_ret[v_y_cur] := (i_left[v_y_cur] ~ i_right);
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
-- select sm_sc.fv_opr_is_regexp_match(array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']], 'a.c')
-- select sm_sc.fv_opr_is_regexp_match(array['abbbbbc122223', 'abc123', 'abc123', 'ac13'], 'a.c')
-- select sm_sc.fv_opr_is_regexp_match(array[]::text[], '1.3')
-- select sm_sc.fv_opr_is_regexp_match(array[array[], array []]::text[], '1.3')

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_regexp_match(text, text[]);
create or replace function sm_sc.fv_opr_is_regexp_match
(
  i_left     text    ,
  i_right    text[]
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     boolean[]   := case array_ndims(i_right) when 2 then array_fill(null::boolean, array[array_length(i_right, 1), array_length(i_right, 2)]) when 1 then array_fill(null::boolean, array[array_length(i_right, 1)]) else null::boolean[] end;
begin
  -- (null :: text[][] ~ text) = null :: text[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return v_ret;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::text[];

  -- (text ~ [][])
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left ~ i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- (text ~ [])
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := (i_left ~ i_right[v_y_cur]);
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
-- select sm_sc.fv_opr_is_regexp_match('abbbbbc122223', array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']])
-- select sm_sc.fv_opr_is_regexp_match('abc123', array['a.c', '1.*?3', '1.3', 'a.*?c'])
-- select sm_sc.fv_opr_is_regexp_match('abc123', array[]::text[])
-- select sm_sc.fv_opr_is_regexp_match('abc123', array[array[], array []]::text[])
