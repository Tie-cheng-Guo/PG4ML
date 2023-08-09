-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_regexp_replace(text[], text[], text);
create or replace function sm_sc.fv_regexp_replace
(
  i_array         text[]    ,
  i_pattern       text[]    ,
  i_replacement   text   default ''    ,
  i_flags         text   default 'g'
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

  -- regexp_replace([][0], [][]) 或者 regexp_replace([0], [][])
  if array_length(i_array, array_ndims(i_array)) is null and i_array is not null -- = 0
  then 
    return array_fill(null::text, array[coalesce(array_length(i_pattern, 1), 0), coalesce(array_length(i_pattern, 2), 0)]);
  -- regexp_replace([][], [][0]) 或者 regexp_replace([][], [0])
  elsif array_length(i_pattern, array_ndims(i_pattern)) is null and i_pattern is not null -- = 0
  then 
    return array_fill(null::text, array[coalesce(array_length(i_array, 1), 0), coalesce(array_length(i_array, 2), 0)]);

  elsif i_array is null or i_pattern is null
  then
    return null::text[];

  -- regexp_replace([.], [])
  elsif array_ndims(i_array) = 1 and array_length(i_array, 1) = 1
  then 
    return sm_sc.fv_regexp_replace(i_array[1], i_pattern, i_replacement, i_flags);
  -- regexp_replace([], [.])
  elsif array_ndims(i_pattern) = 1 and array_length(i_pattern, 1) = 1
  then 
    return sm_sc.fv_regexp_replace(i_array, i_pattern[1], i_replacement, i_flags);

  -- regexp_replace([[.]], [])
  elsif array_length(i_array, 2) = 1 and array_length(i_array, 1) = 1
  then 
    return sm_sc.fv_regexp_replace(i_array[1][1], i_pattern, i_replacement, i_flags);
  -- regexp_replace([], [[.]])
  elsif array_length(i_pattern, 2) = 1 and array_length(i_pattern, 1) = 1
  then 
    return sm_sc.fv_regexp_replace(i_array, i_pattern[1][1], i_replacement, i_flags);

  -- regexp_replace([], [])
  elsif array_ndims(i_array) = 1 and array_ndims(i_pattern) = 1 and array_length(i_array, 1) = array_length(i_pattern, 1)
  then 
    while v_y_cur <= array_length(i_array, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur], i_pattern[v_y_cur], i_replacement, i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_array) = array_ndims(i_pattern) <= 2 条件。
  -- 同形状 regexp_replace([][], [][])
  elsif array_length(i_array, 1) = array_length(i_pattern, 1) and array_length(i_array, 2) = array_length(i_pattern, 2)
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur][v_x_cur], i_pattern[v_y_cur][v_x_cur], i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_array 需要延拓 regexp_replace([][1], [][])
  elsif array_length(i_array, 2) = 1 and array_ndims(i_pattern) = 2
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur][1], i_pattern[v_y_cur][v_x_cur], i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 横向广播，i_pattern 需要延拓 regexp_replace([][], [][1])
  elsif array_length(i_pattern, 2) = 1 and array_ndims(i_array) = 2
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur][v_x_cur], i_pattern[v_y_cur][1], i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_array 需要延拓 regexp_replace([1][], [][])
  elsif array_length(i_array, 1) = 1 and array_length(i_array, 2) = array_length(i_pattern, 2)
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[1][v_x_cur], i_pattern[v_y_cur][v_x_cur], i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  -- 纵向广播 i_pattern 需要延拓 regexp_replace([][], [1][])
  elsif array_length(i_pattern, 1) = 1 and array_length(i_pattern, 2) = array_length(i_array, 2)
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur][v_x_cur], i_pattern[1][v_x_cur], i_replacement, i_flags) tb_a(a_matches));
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
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223'], array['abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['a.c'], array['1.*?3']],
--     'fff'
--   );
-- -- select sm_sc.fv_regexp_replace
-- --   (
-- --     array['abbbbbc122223', 'abc123'],
-- --     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']],
-- --     'fff'
-- --   );
-- -- select sm_sc.fv_regexp_replace
-- --   (
-- --     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
-- --     array['1.3', 'a.*?c'],
-- --     'fff'
-- --   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['1.3', 'a.*?c']],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[]::text[],
--     array[array[], array []]::text[],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array[], array []]::text[],
--     array[]::text[],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array[], array []]::text[],
--     array[array[], array []]::text[],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array['abbbbbc122223', 'abc123', 'abc123', 'ac13'],
--     array['a.c', '1.*?3', '1.3', 'a.*?c'],
--     'fff'
--   );
-- select sm_sc.fv_regexp_replace(array['abbbbbc122223'], array['a.c', '1.*?3', '1.3', 'a.*?c'], 'fff');
-- select sm_sc.fv_regexp_replace(array['abbbbbc122223'], array[array['a.c', '1.*?3', '1.3', 'a.*?c']], 'fff');
-- select sm_sc.fv_regexp_replace(array[array[1]], array[1,2,3], 'fff');
-- select sm_sc.fv_regexp_replace(array[array[1]], array[array[1,2,3]], 'fff');

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_regexp_replace(text[], text, text);
create or replace function sm_sc.fv_regexp_replace
(
  i_array         text[]    ,
  i_pattern       text      ,
  i_replacement   text   default ''    ,
  i_flags         text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     text[]   := case array_ndims(i_array) when 2 then array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]) when 1 then array_fill(null::text, array[array_length(i_array, 1)]) else null::text[] end;
begin
  -- regexp_replace(null :: text[][], text) = null :: text[][]
  if array_length(i_array, array_ndims(i_array)) is null and i_pattern is not null
  then 
    return v_ret;
  -- -- elsif i_pattern is null
  -- -- then
  -- --   return null::text[];

  -- regexp_replace([][], text)
  elsif array_ndims(i_array) =  2
  then
    while v_y_cur <= array_length(i_array, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_array, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur][v_x_cur], i_pattern, i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_replace([], text)
  elsif array_ndims(i_array) =  1
  then
    while v_y_cur <= array_length(i_array, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur], i_pattern, i_replacement, i_flags) tb_a(a_matches));
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
-- select sm_sc.fv_regexp_replace(array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']], 'a.c', 'fff')
-- select sm_sc.fv_regexp_replace(array['abbbbbc122223', 'abc123', 'abc123', 'ac13'], 'a.c', 'fff')
-- select sm_sc.fv_regexp_replace(array[]::text[], '1.3', 'fff')
-- select sm_sc.fv_regexp_replace(array[array[], array []]::text[], '1.3', 'fff')

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_regexp_replace(text, text[], text);
create or replace function sm_sc.fv_regexp_replace
(
  i_array         text      ,
  i_pattern       text[]    ,
  i_replacement   text   default ''    ,
  i_flags         text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     text[]   := case array_ndims(i_pattern) when 2 then array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]) when 1 then array_fill(null::text, array[array_length(i_pattern, 1)]) else null::text[] end;
begin
  -- regexp_replace(null :: text[][], text) = null :: text[][]
  if array_length(i_pattern, array_ndims(i_pattern)) is null and i_array is not null
  then 
    return v_ret;
  -- -- elsif i_array is null
  -- -- then
  -- --   return null::text[];

  -- regexp_replace(text, [][])
  elsif array_ndims(i_pattern) =  2
  then
    while v_y_cur <= array_length(i_pattern, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_pattern, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array, i_pattern[v_y_cur][v_x_cur], i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_replace(text, [])
  elsif array_ndims(i_pattern) =  1
  then
    while v_y_cur <= array_length(i_pattern, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array, i_pattern[v_y_cur], i_replacement, i_flags) tb_a(a_matches));
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
-- select sm_sc.fv_regexp_replace('abbbbbc122223', array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']], 'fff')
-- select sm_sc.fv_regexp_replace('abc123', array['a.c', '1.*?3', '1.3', 'a.*?c'], 'fff')
-- select sm_sc.fv_regexp_replace('abc123', array[]::text[], 'fff')
-- select sm_sc.fv_regexp_replace('abc123', array[array[], array []]::text[], 'fff')
