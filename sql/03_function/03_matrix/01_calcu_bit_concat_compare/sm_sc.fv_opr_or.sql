-- set search_path to sm_sc;

-- -- 逻辑运算
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_or(boolean[], boolean[]);
create or replace function sm_sc.fv_opr_or
(
  i_left     boolean[]    ,
  i_right    boolean[]
)
returns boolean[]
as
$$
declare -- here
  v_y_cur       int    := 1  ;
  v_x_cur       int    := 1  ;
  v_x3_cur      int    := 1  ;
  v_x4_cur      int    := 1  ;
  v_len_left    int[]  := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
  v_len_right   int[]  := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
  v_len_depdt int[]  ;
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
  
  -- 整理入参一
  if v_len_left <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 3
    then 
      i_left := array[[[i_left]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 2
    then 
      i_left := array[[i_left]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 1
    then 
      i_left := array[i_left];
    end if;
    
    v_len_left := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
    
    -- 对齐维长
    if v_len_left <> v_len_depdt
    then 
      i_left := sm_sc.fv_new(i_left, v_len_depdt / v_len_left);
      v_len_left := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
    end if;
  end if;
  
  -- 整理入参二
  if v_len_right <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 3
    then 
      i_right := array[[[i_right]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 2
    then 
      i_right := array[[i_right]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 1
    then 
      i_right := array[i_right];
    end if;
    
    v_len_right := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
    
    -- 对齐维长
    if v_len_right <> v_len_depdt
    then 
      i_right := sm_sc.fv_new(i_right, v_len_depdt / v_len_right);
      v_len_right := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
    end if;
  end if;

  -- array[] or []
  if v_len_left is null and i_left is not null -- = 0
  then 
    return i_right;
  -- [] or array[]
  elsif v_len_right is null and i_right is not null -- = 0
  then 
    return i_left;
  
  elsif i_left is null or i_right is null
  then
    return null::boolean[];
  
  -- [] or []
  elsif array_length(v_len_left, 1) = 1
  then 
    while v_y_cur <= v_len_left[1]
    loop
      i_left[v_y_cur] := (i_left[v_y_cur] or i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [][] or [][]
  elsif array_length(v_len_left, 1) = 2
  then
    while v_y_cur <= v_len_left[1]
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= v_len_left[2]
      loop
        i_left[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] or i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
    
  -- [][][] or [][][]
  elsif array_length(v_len_left, 1) = 3
  then
    for v_y_cur in 1 .. v_len_left[1]
    loop
      for v_x_cur in 1 .. v_len_left[2]
      loop
        for v_x3_cur in 1 .. v_len_left[3]
        loop
          i_left[v_y_cur][v_x_cur][v_x3_cur] = 
            (i_left[v_y_cur][v_x_cur][v_x3_cur] or i_right[v_y_cur][v_x_cur][v_x3_cur]) 
          ;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- [][][][] or [][][][]
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
            i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              (i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] or i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_left;

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
--   sm_sc.fv_opr_or
--   ( 
--     sm_sc.fv_opr_round(sm_sc.fv_new_rand(array[2, 3, 1, 5]) :: decimal[]) :: int[] :: boolean[]
--   , sm_sc.fv_opr_round(sm_sc.fv_new_rand(array[   1, 4, 5]) :: decimal[]) :: int[] :: boolean[]
--   )

-- select 
--   sm_sc.fv_opr_or
--   ( 
--     sm_sc.fv_opr_round(sm_sc.fv_new_rand(array[   1, 4, 5]) :: decimal[]) :: int[] :: boolean[]
--   , sm_sc.fv_opr_round(sm_sc.fv_new_rand(array[2, 3, 1, 5]) :: decimal[]) :: int[] :: boolean[]
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_or
--   (
--     array[array[true, false], array[true, false]],
--     array[array[false, true], array[false, true]]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[true], array[false]],
--     array[array[false, true], array[false, true]]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[true, false], array[true, false]],
--     array[array[true], array[false]]
--   );
-- -- select sm_sc.fv_opr_or
-- --   (
-- --     array[true, false],
-- --     array[array[false, true], array[false, true]]
-- --   );
-- -- select sm_sc.fv_opr_or
-- --   (
-- --     array[array[true, false], array[true, false]],
-- --     array[true, false]
-- --   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[true, false]],
--     array[array[false, true], array[false, true]]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[true, false], array[true, false]],
--     array[array[true, false]]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[]::boolean[],
--     array[array[], array []]::boolean[]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[], array []]::boolean[],
--     array[]::boolean[]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[], array []]::boolean[],
--     array[array[], array []]::boolean[]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[true, false],
--     array[true, false]
--   );
-- select sm_sc.fv_opr_or(array[true], array[true, false]);
-- select sm_sc.fv_opr_or(array[false], array[array[true, false]]);
-- select sm_sc.fv_opr_or(array[array[true]], array[true, false]);
-- select sm_sc.fv_opr_or(array[array[false]], array[array[true, false]]);

-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[true,false,true],[true,false,true]],[[false,true,false],[true,true,false]]]
--   , array[[[true,false,true],[false,false,true]],[[true,false,false],[false,true,false]]]
--   )
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[[true,false,true],[true,false,true]],[[false,true,false],[true,false,false]]],[[[false,false,true],[false,false,true]],[[false,false,true],[false,true,false]]]]
--   , array[[[[false,false,true],[true,false,false]],[[true,false,true],[false,false,true]]],[[[true,false,false],[false,false,true]],[[false,true,false],[false,false,true]]]]
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_or(boolean[], boolean);
create or replace function sm_sc.fv_opr_or
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
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- null :: boolean[][] or boolean = null :: boolean[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::boolean[];

  -- [][] or boolean
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] or i_right;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] or boolean
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := i_left[v_y_cur] or i_right;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
    
  -- [][][] or boolean
  elsif array_ndims(i_left) =  3
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          i_left[v_y_cur][v_x_cur][v_x3_cur] = 
            i_left[v_y_cur][v_x_cur][v_x3_cur] 
            or i_right
          ;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- [][][][] or boolean
  elsif array_ndims(i_left) = 4
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_left, 4)
          loop
            i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
              or i_right
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_left;

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_or(array[array[true, false], array[false, true]], false)
-- select sm_sc.fv_opr_or(array[true, false], false)
-- select sm_sc.fv_opr_or(array[]::boolean[], true)
-- select sm_sc.fv_opr_or(array[array[], array []]::boolean[], false)
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[true,false,true],[true,false,true]],[[false,true,false],[true,true,false]]]
--   , true
--   )
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[[true,false,true],[true,false,true]],[[false,true,false],[true,false,false]]],[[[false,false,true],[false,false,true]],[[false,false,true],[false,true,false]]]]
--   , false
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_or(boolean, boolean[]);
create or replace function sm_sc.fv_opr_or
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
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- null :: boolean[][] or boolean = null :: boolean[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::boolean[];

  -- boolean or [][]
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := i_left or i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- boolean or []
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := i_left or i_right[v_y_cur];
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
    
  -- boolean or [][][]
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            i_left 
            or i_right[v_y_cur][v_x_cur][v_x3_cur] 
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- boolean or [][][][]
  elsif array_ndims(i_right) = 4
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              i_left
              or i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_right;

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_or(false, array[array[false, true], array[true, false]])
-- select sm_sc.fv_opr_or(false, array[true, false])
-- select sm_sc.fv_opr_or(false, array[]::boolean[] )
-- select sm_sc.fv_opr_or(true, array[array[], array []]::boolean[])
-- select 
--   sm_sc.fv_opr_or
--   (
--     true
--   , array[[[true,false,true],[true,false,true]],[[false,true,false],[true,true,false]]]
--   )
-- select 
--   sm_sc.fv_opr_or
--   (
--     false
--   , array[[[[true,false,true],[true,false,true]],[[false,true,false],[true,false,false]]],[[[false,false,true],[false,false,true]],[[false,false,true],[false,true,false]]]]
--   )

-- -------------------------------------------------------------------------------------------------------------------------------

-- -- 位运算
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_or(varbit[], varbit[]);
create or replace function sm_sc.fv_opr_or
(
  i_left     varbit[]    ,
  i_right    varbit[]
)
returns varbit[]
as
$$
declare -- here
  v_y_cur       int    := 1  ;
  v_x_cur       int    := 1  ;
  v_x3_cur      int    := 1  ;
  v_x4_cur      int    := 1  ;
  v_len_left    int[]  := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
  v_len_right   int[]  := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
  v_len_depdt int[]  ;
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
  
  -- 整理入参一
  if v_len_left <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 3
    then 
      i_left := array[[[i_left]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 2
    then 
      i_left := array[[i_left]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 1
    then 
      i_left := array[i_left];
    end if;
    
    v_len_left := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
    
    -- 对齐维长
    if v_len_left <> v_len_depdt
    then 
      i_left := sm_sc.fv_new(i_left, v_len_depdt / v_len_left);
      v_len_left := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
    end if;
  end if;
  
  -- 整理入参二
  if v_len_right <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 3
    then 
      i_right := array[[[i_right]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 2
    then 
      i_right := array[[i_right]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 1
    then 
      i_right := array[i_right];
    end if;
    
    v_len_right := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
    
    -- 对齐维长
    if v_len_right <> v_len_depdt
    then 
      i_right := sm_sc.fv_new(i_right, v_len_depdt / v_len_right);
      v_len_right := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
    end if;
  end if;

  -- array[] | []
  if v_len_left is null and i_left is not null -- = 0
  then 
    return i_right;
  -- [] | array[]
  elsif v_len_right is null and i_right is not null -- = 0
  then 
    return i_left;
  
  elsif i_left is null or i_right is null
  then
    return null::varbit;
  
  -- [] | []
  elsif array_length(v_len_left, 1) = 1
  then 
    while v_y_cur <= v_len_left[1]
    loop
      i_left[v_y_cur] := (i_left[v_y_cur] | i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [][] | [][]
  elsif array_length(v_len_left, 1) = 2
  then
    while v_y_cur <= v_len_left[1]
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= v_len_left[2]
      loop
        i_left[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] | i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
    
  -- [][][] | [][][]
  elsif array_length(v_len_left, 1) = 3
  then
    for v_y_cur in 1 .. v_len_left[1]
    loop
      for v_x_cur in 1 .. v_len_left[2]
      loop
        for v_x3_cur in 1 .. v_len_left[3]
        loop
          i_left[v_y_cur][v_x_cur][v_x3_cur] = 
            (i_left[v_y_cur][v_x_cur][v_x3_cur] | i_right[v_y_cur][v_x_cur][v_x3_cur]) 
          ;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- [][][][] | [][][][]
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
            i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              (i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] | i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_left;

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
--   sm_sc.fv_opr_or
--   ( 
--     (
--       with 
--       cte_x4 as
--       (
--         select 
--           a_y_cur, a_x_cur, a_x3_cur,
--           array_agg(abs(round(random() * 16 - 0.5)) :: int :: bit(3)) as a_x4
--         from generate_series(1, 2) tb_a_y_cur(a_y_cur)
--           , generate_series(1, 3) tb_a_x_cur(a_x_cur)
--           , generate_series(1, 1) tb_a_x3_cur(a_x3_cur)
--           , generate_series(1, 5) tb_a_x4_cur(a_x4_cur)
--         group by a_y_cur, a_x_cur, a_x3_cur
--       ),
--       cte_x3 as 
--       (
--         select 
--       	a_y_cur, a_x_cur, array_agg(a_x4) as a_x3
--         from cte_x4
--         group by a_y_cur, a_x_cur
--       ),
--       cte_x2 as 
--       (
--         select 
--       	a_y_cur, array_agg(a_x3) as a_x2
--         from cte_x3
--         group by a_y_cur
--       )
--       select array_agg(a_x2) :: varbit[] from cte_x2
--     )
--   , (
--       with 
--       cte_x3_ex as
--       (
--         select 
--           a_y_cur, a_x_cur,
--           array_agg(abs(round(random() * 16 - 0.5)) :: int :: bit(3)) as a_x3
--         from generate_series(1, 3) tb_a_y_cur(a_y_cur)
--           , generate_series(1, 3) tb_a_x_cur(a_x_cur)
--           , generate_series(1, 5) tb_a_x3_cur(a_x3_cur)
--         group by a_y_cur, a_x_cur
--       ),
--       cte_x2_ex as 
--       (
--         select 
--       	a_y_cur, array_agg(a_x3) as a_x2
--         from cte_x3_ex
--         group by a_y_cur
--       )
--       select array_agg(a_x2) :: varbit[] from cte_x2_ex
--     )
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_or
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[B'011', B'101'], array[B'011', B'101']]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[B'010'], array[B'011']],
--     array[array[B'011', B'101'], array[B'011', B'101']]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[B'101'], array[B'011']]
--   );
-- -- select sm_sc.fv_opr_or
-- --   (
-- --     array[B'101', B'011'],
-- --     array[array[B'011', B'101'], array[B'011', B'010']]
-- --   );
-- -- select sm_sc.fv_opr_or
-- --   (
-- --     array[array[B'101', B'011'], array[B'101', B'011']],
-- --     array[B'010', B'011']
-- --   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[B'101', B'011']],
--     array[array[B'011', B'101'], array[B'011', B'010']]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[B'101', B'011'], array[B'101', B'011']],
--     array[array[B'010', B'011']]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[]::varbit[],
--     array[array[], array []]::varbit[]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[], array []]::varbit[],
--     array[]::varbit[]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[array[], array []]::varbit[],
--     array[array[], array []]::varbit[]
--   );
-- select sm_sc.fv_opr_or
--   (
--     array[B'101', B'011'],
--     array[B'010', B'011']
--   );
-- select sm_sc.fv_opr_or(array[B'101'], array[B'101', B'011']);
-- select sm_sc.fv_opr_or(array[B'101'], array[array[B'101', B'011']]);
-- select sm_sc.fv_opr_or(array[array[B'101']], array[B'101', B'011']);
-- select sm_sc.fv_opr_or(array[array[B'101']], array[array[B'101', B'011']]);
-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[B'101',B'110',B'001'],[B'101',B'011',B'110']],[[B'011',B'001',B'100'],[B'111',B'100',B'011']]]
--   , array[[[B'011',B'001',B'100'],[B'011',B'110',B'000']],[[B'001',B'100',B'011'],[B'011',B'100',B'111']]]
--   )
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[[B'101',B'110',B'001'],[B'101',B'011',B'110']],[[B'011',B'001',B'100'],[B'111',B'100',B'011']]],[[[B'110',B'000',B'011'],[B'010',B'001',B'100']],[[B'001',B'100',B'011'],[B'111',B'010',B'101']]]]
--   , array[[[[B'011',B'001',B'100'],[B'011',B'110',B'000']],[[B'001',B'100',B'011'],[B'011',B'100',B'111']]],[[[B'001',B'010',B'100'],[B'011',B'010',B'111']],[[B'010',B'100',B'001'],[B'101',B'110',B'001']]]]
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_or(varbit[], varbit);
create or replace function sm_sc.fv_opr_or
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
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- null :: varbit[][] & varbit = null :: varbit[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::varbit[];

  -- [][] | varbit
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] | i_right;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] | varbit
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := i_left[v_y_cur] | i_right;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- [][][] | varbit
  elsif array_ndims(i_left) =  3
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          i_left[v_y_cur][v_x_cur][v_x3_cur] = 
            i_left[v_y_cur][v_x_cur][v_x3_cur] 
            | i_right
          ;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- [][][][] | varbit
  elsif array_ndims(i_left) = 4
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_left, 4)
          loop
            i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
              | i_right
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_left;    

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_or(array[array[B'010', B'011'], array[B'011', B'010']], B'011')
-- select sm_sc.fv_opr_or(array[B'010011', B'011010'], B'011101')
-- select sm_sc.fv_opr_or(array[]::varbit[], B'010')
-- select sm_sc.fv_opr_or(array[array[], array []]::varbit[], B'011')
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[B'101',B'110',B'001'],[B'101',B'011',B'110']],[[B'011',B'001',B'100'],[B'111',B'100',B'011']]]
--   , B'010'
--   )
-- select 
--   sm_sc.fv_opr_or
--   (
--     array[[[[B'101',B'110',B'001'],[B'101',B'011',B'110']],[[B'011',B'001',B'100'],[B'111',B'100',B'011']]],[[[B'110',B'000',B'011'],[B'010',B'001',B'100']],[[B'001',B'100',B'011'],[B'111',B'010',B'101']]]]
--   , B'010'
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_or(varbit, varbit[]);
create or replace function sm_sc.fv_opr_or
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
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- null :: varbit[][] | varbit = null :: varbit[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::varbit[];

  -- varbit | [][]
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := i_left | i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- varbit | []
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := i_left | i_right[v_y_cur];
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
    
  -- varbit | [][][]
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            i_left 
            | i_right[v_y_cur][v_x_cur][v_x3_cur] 
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- varbit | [][][][]
  elsif array_ndims(i_right) = 4
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              i_left
              | i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_right;

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_or(B'110', array[array[B'011', B'010'], array[B'101', B'110']])
-- select sm_sc.fv_opr_or(B'011101', array[B'010011', B'011010'])
-- select sm_sc.fv_opr_or(B'011', array[]::varbit[] )
-- select sm_sc.fv_opr_or(B'010', array[array[], array []]::varbit[])
-- select 
--   sm_sc.fv_opr_or
--   (
--     B'010'
--   , array[[[B'101',B'110',B'001'],[B'101',B'011',B'110']],[[B'011',B'001',B'100'],[B'111',B'100',B'011']]]
--   )
-- select 
--   sm_sc.fv_opr_or
--   (
--     B'010'
--   , array[[[[B'101',B'110',B'001'],[B'101',B'011',B'110']],[[B'011',B'001',B'100'],[B'111',B'100',B'011']]],[[[B'110',B'000',B'011'],[B'010',B'001',B'100']],[[B'001',B'100',B'011'],[B'111',B'010',B'101']]]]
--   )