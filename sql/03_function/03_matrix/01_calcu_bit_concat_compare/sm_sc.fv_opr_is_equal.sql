-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_is_equal(anyarray, anyarray);
create or replace function sm_sc.fv_opr_is_equal
(
  i_left     anyarray    ,
  i_right    anyarray
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
  v_ret     boolean[];
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
  
  if pg_typeof(i_right) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_is_equal_py(i_left, i_right);
  else    
    v_len_depdt :=
      (
        select 
          sm_sc.__fv_mirror_y(array_agg(greatest(a_len_left, a_len_right)))
        from unnest(sm_sc.__fv_mirror_y(v_len_left), sm_sc.__fv_mirror_y(v_len_right)) tb_a_len(a_len_left, a_len_right)
      )
    ;
    v_ret := array_fill(null::boolean, v_len_depdt);
    
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
    
    -- array[] == []
    if v_len_left is null and i_left is not null -- = 0
    then 
      return array_fill(null::boolean, array[coalesce(array_length(i_right, 1), 0), coalesce(array_length(i_right, 2), 0)]);
    -- [] == array[]
    elsif v_len_right is null and i_right is not null -- = 0
    then 
      return array_fill(null::boolean, array[coalesce(array_length(i_left, 1), 0), coalesce(array_length(i_left, 2), 0)]);
    
    elsif i_left is null or i_right is null
    then
      return null::boolean[];
    
    -- [] == []
    elsif array_length(v_len_left, 1) = 1
    then 
      while v_y_cur <= v_len_left[1]
      loop
        v_ret[v_y_cur] := (i_left[v_y_cur] = i_right[v_y_cur]);
        v_y_cur := v_y_cur + 1;
      end loop;
      return v_ret;
    
    -- [][] == [][]
    elsif array_length(v_len_left, 1) = 2
    then
      while v_y_cur <= v_len_left[1]
      loop 
        v_x_cur := 1  ;
        while v_x_cur <= v_len_left[2]
        loop
          v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] = i_right[v_y_cur][v_x_cur]);
          v_x_cur := v_x_cur + 1;
        end loop;
        v_y_cur := v_y_cur + 1;
      end loop;
      return v_ret;
      
    -- [][][] == [][][]
    elsif array_length(v_len_left, 1) = 3
    then
      for v_y_cur in 1 .. v_len_left[1]
      loop
        for v_x_cur in 1 .. v_len_left[2]
        loop
          for v_x3_cur in 1 .. v_len_left[3]
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur] := 
              (i_left[v_y_cur][v_x_cur][v_x3_cur] = i_right[v_y_cur][v_x_cur][v_x3_cur])
            ;
          end loop;    
        end loop;
      end loop;
      return v_ret;
      
    -- [][][][] == [][][][]
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
                (i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur])
              ;
            end loop;
          end loop;    
        end loop;
      end loop;
      return v_ret;
    
    -- 审计二维长度
    else
      raise exception 'no method for such length!  v_len_left: %; v_len_right: %;', v_len_left, v_len_right;
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_opr_is_equal
--   ( 
--     <>` (sm_sc.fv_new_rand(array[2, 3, 1, 5]) -` 0.5 :: float)
--   , <>` (sm_sc.fv_new_rand(array[   1, 4, 5]) -` 0.5 :: float)
--   )
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[1.3, 52.3], array[5.6, 45.6]]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[32.5], array[9.1]],
--     array[array[12.3, 2.3], array[45.6, 25.6]]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[12.3, 32.3], array[45.6, 15.6]],
--     array[array[12.5], array[19.1]]
--   );
-- -- select sm_sc.fv_opr_is_equal
-- --   (
-- --     array[3.5, 9.1],
-- --     array[array[2.3, 12.3], array[45.6, 4.6]]
-- --   );
-- -- select sm_sc.fv_opr_is_equal
-- --   (
-- --     array[array[12.3, 2.3], array[45.6, 5.6]],
-- --     array[12.5, 19.1]
-- --   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[3.5, 9.1]],
--     array[array[2.3, 12.3], array[45.6, 4.6]]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[12.3, 2.3], array[45.6, 5.6]],
--     array[array[12.5, 19.1]]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_is_equal
--   (
--     array[12.3, 2.3, 45.6],
--     array[12.5, 19.1, 5.6]
--   );
-- select sm_sc.fv_opr_is_equal(array[1], array[1,2,3]);
-- select sm_sc.fv_opr_is_equal(array[1], array[array[1,2,3]]);
-- select sm_sc.fv_opr_is_equal(array[array[1]], array[1,2,3]);
-- select sm_sc.fv_opr_is_equal(array[array[1]], array[array[1,2,3]]);
-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_is_equal
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   , array[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]
--   )
-- select 
--   sm_sc.fv_opr_is_equal
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   , array[[[[1.2,2.3,3.4],[0.3,0.4,0.7]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]],[[[1.6,2.7,3.4],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[1.4,2.2,0.8]]]]
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_equal(anyarray, anyelement);
create or replace function sm_sc.fv_opr_is_equal
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     boolean[]  ;
begin
  -- (null :: float[][] = null :: float[][])
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return v_ret;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::boolean[];
  
  elsif pg_typeof(i_left) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_is_equal_py(i_left, i_right);  

  -- ([][] = float)
  elsif array_ndims(i_left) =  2
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2)]);
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] = i_right);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- ([] = float)
  elsif array_ndims(i_left) =  1
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1)]);
    while v_y_cur <= array_length(i_left, 1)
    loop
      v_ret[v_y_cur] := (i_left[v_y_cur] = i_right);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- ([][][] = float)
  elsif array_ndims(i_left) =  3
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2), array_length(i_left, 3)]);
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] = 
            (
              i_left[v_y_cur][v_x_cur][v_x3_cur] 
              = i_right
            )
          ;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- ([][][][] = float)
  elsif array_ndims(i_left) = 4
  then
    v_ret := array_fill(null::boolean, array[array_length(i_left, 1), array_length(i_left, 2), array_length(i_left, 3), array_length(i_left, 4)]);
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_left, 4)
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              (
                i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
                = i_right
              )
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_is_equal(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_is_equal(array[12.3, 25.1, 2.56, 3.25], 8.8)
-- select sm_sc.fv_opr_is_equal(array[]::float[], 8.8::float)
-- select sm_sc.fv_opr_is_equal(array[array[], array []]::float[], 8.8::float)
-- select 
--   sm_sc.fv_opr_is_equal
--   (
--     array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   , 2.2
--   )
-- select 
--   sm_sc.fv_opr_is_equal
--   (
--     array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   , 2.2
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_is_equal(anyelement, anyarray);
create or replace function sm_sc.fv_opr_is_equal
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     boolean[]  ;
begin
  -- (null :: float[][] = null :: float[][])
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return v_ret;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::anyarray;
  
  elsif pg_typeof(i_right) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_is_equal_py(i_left, i_right);  

  -- (float = [][])
  elsif array_ndims(i_right) =  2
  then
    v_ret := array_fill(null::boolean, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left = i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- (float = [])
  elsif array_ndims(i_right) =  1
  then
    v_ret := array_fill(null::boolean, array[array_length(i_right, 1)]);
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := (i_left = i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- (float = [][][])
  elsif array_ndims(i_right) = 3
  then
    v_ret := array_fill(null::boolean, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3)]);
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] = 
            (
              i_left 
              = i_right[v_y_cur][v_x_cur][v_x3_cur] 
            )
          ;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- (float = [][][][])
  elsif array_ndims(i_right) = 4
  then
    v_ret := array_fill(null::boolean, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3), array_length(i_right, 4)]);
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              (
                i_left
                = i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
              )
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return v_ret;
  
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_is_equal(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_is_equal(8.8, array[12.3, 25.1, 2.56, 3.25])
-- select sm_sc.fv_opr_is_equal(8.8::float, array[]::float[] )
-- select sm_sc.fv_opr_is_equal(8.8::float, array[array[], array []]::float[])
-- select 
--   sm_sc.fv_opr_is_equal
--   (
--     2.2
--   , array[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]]
--   )
-- select 
--   sm_sc.fv_opr_is_equal
--   (
--     2.2
--   , array[[[[1,2,3],[1.2,2.3,3.4]],[[0.5,0.7,0.8],[0.3,0.4,0.7]]],[[[1.6,2.7,3.4],[1.4,2.2,0.8]],[[-0.5,1.7,0.8],[2.3,-0.4,-2.7]]]]
--   )
