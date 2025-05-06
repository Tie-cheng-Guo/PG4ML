-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_regexp_replace(text[], text[], text, text);
create or replace function sm_sc.fv_regexp_replace
(
  i_array     text[]    ,
  i_pattern    text[]    ,
  i_replacement   text   default ''    ,
  i_flags      text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_y_cur       int    := 1  ;
  v_x_cur       int    := 1  ;
  v_x3_cur      int    := 1  ;
  v_x4_cur      int    := 1  ;
  v_len_left    int[]  := (select array_agg(array_length(i_array, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_array)) tb_a_cur_dim(a_cur_dim));
  v_len_right   int[]  := (select array_agg(array_length(i_pattern, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_pattern)) tb_a_cur_dim(a_cur_dim));
  v_len_depdt int[]  ;
  v_ret     text[];
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if exists 
       (
         select  
         from unnest(sm_sc.__fv_mirror_y(v_len_left), sm_sc.__fv_mirror_y(v_len_right)) tb_a_len(a_len_left, a_len_right)
         where a_len_left <> a_len_right
           and a_len_left <> 1
           and a_len_right <> 1
       )
    then
      raise exception 'no method!';
    end if;
  end if;
  
  v_len_depdt :=
    (
      select 
        sm_sc.__fv_mirror_y(array_agg(greatest(a_len_left, a_len_right)))
      from unnest(sm_sc.__fv_mirror_y(v_len_left), sm_sc.__fv_mirror_y(v_len_right)) tb_a_len(a_len_left, a_len_right)
    )
  ;
  v_ret := array_fill(null::text, v_len_depdt);
  
  -- 整理入参一
  if v_len_left <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 3
    then 
      i_array := array[[[i_array]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 2
    then 
      i_array := array[[i_array]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 1
    then 
      i_array := array[i_array];
    end if;
    
    v_len_left := (select array_agg(array_length(i_array, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_array)) tb_a_cur_dim(a_cur_dim));
    
    -- 对齐维长
    if v_len_left <> v_len_depdt
    then 
      i_array := sm_sc.fv_new(i_array, v_len_depdt / v_len_left);
      v_len_left := (select array_agg(array_length(i_array, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_array)) tb_a_cur_dim(a_cur_dim));
    end if;
  end if;
  
  -- 整理入参二
  if v_len_right <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 3
    then 
      i_pattern := array[[[i_pattern]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 2
    then 
      i_pattern := array[[i_pattern]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 1
    then 
      i_pattern := array[i_pattern];
    end if;
    
    v_len_right := (select array_agg(array_length(i_pattern, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_pattern)) tb_a_cur_dim(a_cur_dim));
    
    -- 对齐维长
    if v_len_right <> v_len_depdt
    then 
      i_pattern := sm_sc.fv_new(i_pattern, v_len_depdt / v_len_right);
      v_len_right := (select array_agg(array_length(i_pattern, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_pattern)) tb_a_cur_dim(a_cur_dim));
    end if;
  end if;

  -- regexp_replace(array[], [])
  if v_len_left is null and i_array is not null -- = 0
  then 
    return array_fill(null::text, array[coalesce(array_length(i_pattern, 1), 0), coalesce(array_length(i_pattern, 2), 0)]);
  -- regexp_replace([] ~ array[]
  elsif v_len_right is null and i_pattern is not null -- = 0
  then 
    return array_fill(null::text, array[coalesce(array_length(i_array, 1), 0), coalesce(array_length(i_array, 2), 0)]);
  
  elsif i_array is null or i_pattern is null
  then
    return null::text[];
  
  -- regexp_replace([], [])
  elsif array_length(v_len_left, 1) = 1
  then 
    while v_y_cur <= v_len_left[1]
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur], i_pattern[v_y_cur], i_replacement, i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_replace([][], [][])
  elsif array_length(v_len_left, 1) = 2
  then
    while v_y_cur <= v_len_left[1]
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= v_len_left[2]
      loop
        v_ret[v_y_cur][v_x_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur][v_x_cur], i_pattern[v_y_cur][v_x_cur], i_replacement, i_flags) tb_a(a_matches));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
    
  -- regexp_replace([][][], [][][])
  elsif array_length(v_len_left, 1) = 3
  then
    for v_y_cur in 1 .. v_len_left[1]
    loop
      for v_x_cur in 1 .. v_len_left[2]
      loop
        for v_x3_cur in 1 .. v_len_left[3]
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] := 
          (
            select array_agg(a_matches)::text 
            from regexp_replace(i_array[v_y_cur][v_x_cur][v_x3_cur], i_pattern[v_y_cur][v_x_cur][v_x3_cur], i_replacement, i_flags) tb_a(a_matches)
          );
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- regexp_replace([][][][], [][][][])
  elsif array_length(v_len_left, 1) = 4
  then
    for v_y_cur in 1 .. v_len_left[1]
    loop
      for v_x_cur in 1 .. v_len_left[2]
      loop
        for v_x3_cur in 1 .. v_len_left[3]
        loop
          for v_x4_cur in 1 .. v_len_left[4]
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] := 
            (
              select array_agg(a_matches)::text 
              from regexp_replace(i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_pattern[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_replacement, i_flags) tb_a(a_matches)
            );
          end loop;
        end loop;    
      end loop;
    end loop;
    return v_ret;

  -- 审计二维长度
  else
    raise exception 'no method for such length!  v_len_left: %; v_len_right: %;', v_len_left, v_len_right;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_regexp_replace
--   ( 
--     (<>` (sm_sc.fv_new_rand(array[2, 3, 1, 5]) -` 0.5 :: text)) :: text[]
--   , (<>` (sm_sc.fv_new_rand(array[   1, 4, 5]) -` 0.5 :: text)) :: text[]
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223'], array['abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array[a.c], array[1.*?3]]
--   );
-- -- select sm_sc.fv_regexp_replace
-- --   (
-- --     array['abbbbbc122223', 'abc123'],
-- --     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
-- --   );
-- -- select sm_sc.fv_regexp_replace
-- --   (
-- --     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
-- --     array['1.3', 'a.*?c']
-- --   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123']],
--     array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']],
--     array[array['1.3', 'a.*?c']]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[]::text[],
--     array[array[], array []]::text[]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array[], array []]::text[],
--     array[]::text[]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array[array[], array []]::text[],
--     array[array[], array []]::text[]
--   );
-- select sm_sc.fv_regexp_replace
--   (
--     array['abbbbbc122223', 'abc123', 'abc123', 'ac13'],
--     array['a.c', '1.*?3', '1.3', 'a.*?c']
--   );
-- select sm_sc.fv_regexp_replace(array['1'], array['1','2','3']);
-- select sm_sc.fv_regexp_replace(array['1'], array[array['1','2','3']]);
-- select sm_sc.fv_regexp_replace(array[array['1']], array['1','2','3']);
-- select sm_sc.fv_regexp_replace(array[array['1']], array[array['1','2','3']]);
-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_regexp_replace
--   (
--     array[[['abc123', 'ac13'],['abc123', 'ac13']],[['abc123', 'ac13'],['abc123', 'ac13']]]
--   , array[[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']],[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']]]
--   )
-- select 
--   sm_sc.fv_regexp_replace
--   (
--     array[[[['abc123', 'ac13'],['abc123', 'ac13']],[['abc123', 'ac13'],['abc123', 'ac13']]],[[['abc123', 'ac13'],['abc123', 'ac13']],[['abc123', 'ac13'],['abc123', 'ac13']]]]
--   , array[[[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']],[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']]],[[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']],[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']]]]
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_regexp_replace(text[], text, text, text);
create or replace function sm_sc.fv_regexp_replace
(
  i_array     text[]    ,
  i_pattern    text    ,
  i_replacement   text   default ''    ,
  i_flags      text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     text[]  ;
begin
  -- regexp_replace(null :: text[][] ~ text) = null :: text[][]
  if array_length(i_array, array_ndims(i_array)) is null and i_pattern is not null
  then 
    return v_ret;
  -- -- elsif i_pattern is null
  -- -- then
  -- --   return null::text[];

  -- regexp_replace([][], text)
  elsif array_ndims(i_array) =  2
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2)]);
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
    v_ret := array_fill(null::text, array[array_length(i_array, 1)]);
    while v_y_cur <= array_length(i_array, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array[v_y_cur], i_pattern, i_replacement, i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_replace([][][], text)
  elsif array_ndims(i_array) =  3
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2), array_length(i_array, 3)]);
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] = 
          (
            select array_agg(a_matches)::text 
            from regexp_replace(i_array[v_y_cur][v_x_cur][v_x3_cur], i_pattern, i_replacement, i_flags) tb_a(a_matches)
          );
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- regexp_replace([][][][], text)
  elsif array_ndims(i_array) = 4
  then
    v_ret := array_fill(null::text, array[array_length(i_array, 1), array_length(i_array, 2), array_length(i_array, 3), array_length(i_array, 4)]);
    for v_y_cur in 1 .. array_length(i_array, 1)
    loop
      for v_x_cur in 1 .. array_length(i_array, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_array, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_array, 4)
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
            (
              select array_agg(a_matches)::text 
              from regexp_replace(i_array[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_pattern, i_replacement, i_flags) tb_a(a_matches)
            );
          end loop;
        end loop;    
      end loop;
    end loop;
    return v_ret;
   
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_regexp_replace(array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']], 'a.c')
-- select sm_sc.fv_regexp_replace(array['abbbbbc122223', 'abc123', 'abc123', 'ac13'], 'a.c')
-- select sm_sc.fv_regexp_replace(array[]::text[], '1.3')
-- select sm_sc.fv_regexp_replace(array[array[], array []]::text[], '1.3')
-- select 
--   sm_sc.fv_regexp_replace
--   (
--     array[[['abc123', 'ac13'],['abc123', 'ac13']],[['abc123', 'ac13'],['abc123', 'ac13']]]
--   , '1.*?3'
--   )
-- select 
--   sm_sc.fv_regexp_replace
--   (
--     array[[[['abc123', 'ac13'],['abc123', 'ac13']],[['abc123', 'ac13'],['abc123', 'ac13']]],[[['abc123', 'ac13'],['abc123', 'ac13']],[['abc123', 'ac13'],['abc123', 'ac13']]]]
--   , 'a.*?c'
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_regexp_replace(text, text[], text, text);
create or replace function sm_sc.fv_regexp_replace
(
  i_array     text    ,
  i_pattern    text[]    ,
  i_replacement   text   default ''    ,
  i_flags      text   default 'g'
)
returns text[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     text[]  ;
begin
  -- regexp_replace(null :: text[][] ~ text) = null :: text[][]
  if array_length(i_pattern, array_ndims(i_pattern)) is null and i_array is not null
  then 
    return v_ret;
  -- -- elsif i_array is null
  -- -- then
  -- --   return null::text[];

  -- regexp_replace(text, [][])
  elsif array_ndims(i_pattern) =  2
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2)]);
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
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1)]);
    while v_y_cur <= array_length(i_pattern, 1)
    loop
      v_ret[v_y_cur] := (select array_agg(a_matches)::text from regexp_replace(i_array, i_pattern[v_y_cur], i_replacement, i_flags) tb_a(a_matches));
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- regexp_replace(text, [][][])
  elsif array_ndims(i_pattern) = 3
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2), array_length(i_pattern, 3)]);
    for v_y_cur in 1 .. array_length(i_pattern, 1)
    loop
      for v_x_cur in 1 .. array_length(i_pattern, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_pattern, 3)
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] = 
          (
            select array_agg(a_matches)::text 
            from regexp_replace(i_array, i_pattern[v_y_cur][v_x_cur][v_x3_cur], i_replacement, i_flags) tb_a(a_matches)
          );
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- regexp_replace(text, [][][][])
  elsif array_ndims(i_pattern) = 4
  then
    v_ret := array_fill(null::text, array[array_length(i_pattern, 1), array_length(i_pattern, 2), array_length(i_pattern, 3), array_length(i_pattern, 4)]);
    for v_y_cur in 1 .. array_length(i_pattern, 1)
    loop
      for v_x_cur in 1 .. array_length(i_pattern, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_pattern, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_pattern, 4)
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
            (
              select array_agg(a_matches)::text 
              from regexp_replace(i_array, i_pattern[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_replacement, i_flags) tb_a(a_matches)
            );
          end loop;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_pattern);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_regexp_replace('abbbbbc122223', array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']])
-- select sm_sc.fv_regexp_replace('abc123', array['a.c', '1.*?3', '1.3', 'a.*?c'])
-- select sm_sc.fv_regexp_replace('abc123', array[]::text[])
-- select sm_sc.fv_regexp_replace('abc123', array[array[], array []]::text[])
-- select 
--   sm_sc.fv_regexp_replace
--   (
--     'abc123'
--   , array[[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']],[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']]]
--   )
-- select 
--   sm_sc.fv_regexp_replace
--   (
--     'abc123'
--   , array[[[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']],[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']]],[[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']],[['1.*?3', 'a.*?c'],['1.*?3', 'a.*?c']]]]
--   )
