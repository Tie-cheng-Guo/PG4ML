-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_regexp_matches(text[], text[], text);
create or replace function sm_sc.fv_regexp_matches
(
  i_array      text[]    ,
  i_pattern    text[]    ,
  i_flags      text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     text[];
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if array_ndims(i_array) > 2 
    or array_ndims(i_pattern) > 2
    or array_ndims(i_array) = 1 
      and array_ndims(i_pattern) = 1 
      and array_length(i_array, 1) <> array_length(i_pattern, 1)
      and array_length(i_array, 1) <> 1
      and array_length(i_pattern, 1) <> 1
    or array_ndims(i_array) = 2 and array_ndims(i_pattern) = 2
      and array_length(i_array, 1) <> array_length(i_pattern, 1) 
      and array_length(i_array, 1) <> array_length(i_pattern, 2)
      and array_length(i_array, 2) <> array_length(i_pattern, 1)
      and array_length(i_array, 1) <> 1
      and array_length(i_pattern, 1) <> 1
      and array_length(i_array, 2) <> 1
      and array_length(i_pattern, 2) <> 1
  then
    raise exception 'no method!';
  end if;

  -- regexp_matches([][0], [][]) 或者 regexp_matches([0], [][])
  if array_length(i_array, array_ndims(i_array)) is null and i_array is not null -- = 0
  then 
    return array_fill(null::text, array[coalesce(array_length(i_pattern, 1), 0), coalesce(array_length(i_pattern, 2), 0)]);
  -- regexp_matches([][], [][0]) 或者 regexp_matches([][], [0])
  elsif array_length(i_pattern, array_ndims(i_pattern)) is null and i_pattern is not null -- = 0
  then 
    return array_fill(null::text, array[coalesce(array_length(i_array, 1), 0), coalesce(array_length(i_array, 2), 0)]);

  elsif i_array is null or i_pattern is null
  then
    return null::text[];

  -- regexp_matches([.], [])
  elsif array_ndims(i_array) = 1 and array_length(i_array, 1) = 1
  then 
    return sm_sc.fv_regexp_matches(i_array[1], i_pattern, i_flags);
  -- regexp_matches([], [.])
  elsif array_ndims(i_pattern) = 1 and array_length(i_pattern, 1) = 1
  then 
    return sm_sc.fv_regexp_matches(i_array, i_pattern[1], i_flags);

  -- regexp_matches([[.]], [])
  elsif array_length(i_array, 2) = 1 and array_length(i_array, 1) = 1
  then 
    return sm_sc.fv_regexp_matches(i_array[1][1], i_pattern, i_flags);
  -- regexp_matches([], [[.]])
  elsif array_length(i_pattern, 2) = 1 and array_length(i_pattern, 1) = 1
  then 
    return sm_sc.fv_regexp_matches(i_array, i_pattern[1][1], i_flags);

  -- regexp_matches([], [])
  elsif array_ndims(i_array) = 1 and array_ndims(i_pattern) = 1 and array_length(i_array, 1) = array_length(i_pattern, 1)
  then 
    while v_y_cur <= array_length(i_array, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur], i_pattern[v_y_cur], i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_array) = array_ndims(i_pattern) <= 2 条件。
  -- 同形状 regexp_matches([][], [][])
  elsif array_length(i_array, 1) = array_length(i_pattern, 1) and array_length(i_array, 2) = array_length(i_pattern, 2)
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur][v_x_cur], i_pattern[v_y_cur][v_x_cur], i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_array 需要延拓 regexp_matches([][1], [][])
  elsif array_length(i_array, 2) = 1 and array_ndims(i_pattern) = 2
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur][1], i_pattern[v_y_cur][v_x_cur], i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_pattern 需要延拓 regexp_matches([][], [][1])
  elsif array_length(i_pattern, 2) = 1 and array_ndims(i_array) = 2
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur][v_x_cur], i_pattern[v_y_cur][1], i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_array 需要延拓 regexp_matches([1][], [][])
  elsif array_length(i_array, 1) = 1 and array_length(i_array, 2) = array_length(i_pattern, 2)
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[1][v_x_cur], i_pattern[v_y_cur][v_x_cur], i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_pattern 需要延拓 regexp_matches([][], [1][])
  elsif array_length(i_pattern, 1) = 1 and array_length(i_pattern, 2) = array_length(i_array, 2)
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur][v_x_cur], i_pattern[1][v_x_cur], i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- 审计二维长度
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_regexp_matches
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[array['abbbbbc122223'], array['abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['a.c'], array['1.*?3']]
--   );
-- -- select sm_sc.fv_regexp_matches
-- --   (
-- --     array['abbbbbc122223', 'abc123'],
-- --     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
-- --   );
-- -- select sm_sc.fv_regexp_matches
-- --   (
-- --     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
-- --     array['1.3', 'a.*?c']
-- --   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[array['abbbbbc122223', 'abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[]::text[],
--     array[array[], array []]::text[]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[array[], array []]::text[],
--     array[]::text[]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array[array[], array []]::text[],
--     array[array[], array []]::text[]
--   );
-- select sm_sc.fv_regexp_matches
--   (
--     array['abbbbbc122223', 'abc123', 'abc123', 'ac13'],
--     array['a.c', '1.*?3', '1.3', 'a.*?c']
--   );
-- select sm_sc.fv_regexp_matches(array[1], array[1,2,3]);
-- select sm_sc.fv_regexp_matches(array[1], array[array[1,2,3]]);
-- select sm_sc.fv_regexp_matches(array[array[1]], array[1,2,3]);
-- select sm_sc.fv_regexp_matches(array[array[1]], array[array[1,2,3]]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_regexp_matches(text[], text, text);
create or replace function sm_sc.fv_regexp_matches
(
  i_array      text[]    ,
  i_pattern    text    ,
  i_flags      text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     text[]   := case array_ndims(i_array) when 2 then array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]) when 1 then array_fill(null::text, array[array_length(i_array, 1)]) else null::text[] end;
begin
  -- regexp_matches(null :: text[][], text) = null :: text[][]
  if array_length(i_array, array_ndims(i_array)) is null and i_pattern is not null
  then 
    return v_ret;
  -- -- elsif i_pattern is null
  -- -- then
  -- --   return null::text[];

  -- regexp_matches([][], text)
  elsif array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur][v_x_cur], i_pattern, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_matches([], text)
  elsif array_ndims(i_array) =  1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array[v_y_cur], i_pattern, i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_regexp_matches(array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']], 'a.c')
-- select sm_sc.fv_regexp_matches(array['abbbbbc122223', 'abc123', 'abc123', 'ac13'], 'a.c')
-- select sm_sc.fv_regexp_matches(array[]::text[], '1.3')
-- select sm_sc.fv_regexp_matches(array[array[], array []]::text[], '1.3')

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_regexp_matches(text, text[], text);
create or replace function sm_sc.fv_regexp_matches
(
  i_array      text    ,
  i_pattern    text[]    ,
  i_flags      text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     text[]   := case array_ndims(i_pattern) when 2 then array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]) when 1 then array_fill(null::text, array[array_length(i_pattern, 1)]) else null::text[] end;
begin
  -- regexp_matches(null :: text[][], text) = null :: text[][]
  if array_length(i_pattern, array_ndims(i_pattern)) is null and i_array is not null
  then 
    return v_ret;
  -- -- elsif i_array is null
  -- -- then
  -- --   return null::text[];

  -- regexp_matches(text, [][])
  elsif array_ndims(i_pattern) =  2
  then
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array, i_pattern[v_y_cur][v_x_cur], i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_matches(text, [])
  elsif array_ndims(i_pattern) =  1
  then
    while v_y_cur <= array_length(i_pattern, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_matches(i_array, i_pattern[v_y_cur], i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_regexp_matches('abbbbbc122223', array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']])
-- select sm_sc.fv_regexp_matches('abc123', array['a.c', '1.*?3', '1.3', 'a.*?c'])
-- select sm_sc.fv_regexp_matches('abc123', array[]::text[])
-- select sm_sc.fv_regexp_matches('abc123', array[array[], array []]::text[])
