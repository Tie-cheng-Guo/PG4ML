-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_shift_left(varbit[], int[]);
create or replace function sm_sc.fv_opr_shift_left
(
  i_left     varbit[]    ,
  i_right    int[]
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
  v_ret     varbit[];
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
  v_ret := array_fill(null::varbit, v_len_depdt);
  
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

  -- array[] << []
  if v_len_left is null and i_left is not null -- = 0
  then 
    return array_fill(null::varbit, array[coalesce(array_length(i_right, 1), 0), coalesce(array_length(i_right, 2), 0)]);
  -- [] << array[]
  elsif v_len_right is null and i_right is not null -- = 0
  then 
    return array_fill(null::varbit, array[coalesce(array_length(i_left, 1), 0), coalesce(array_length(i_left, 2), 0)]);
  
  elsif i_left is null or i_right is null
  then
    return null::varbit[];
  
  -- [] << []
  elsif array_length(v_len_left, 1) = 1
  then 
    while v_y_cur <= v_len_left[1]
    loop
      v_ret[v_y_cur] := (i_left[v_y_cur] << i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- [][] << [][]
  elsif array_length(v_len_left, 1) = 2
  then
    while v_y_cur <= v_len_left[1]
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= v_len_left[2]
      loop
        v_ret[v_y_cur][v_x_cur] := (i_left[v_y_cur][v_x_cur] << i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
    
  -- [][][] << [][][]
  elsif array_length(v_len_left, 1) = 3
  then
    for v_y_cur in 1 .. v_len_left[1]
    loop
      for v_x_cur in 1 .. v_len_left[2]
      loop
        for v_x3_cur in 1 .. v_len_left[3]
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] := 
            (i_left[v_y_cur][v_x_cur][v_x3_cur] << i_right[v_y_cur][v_x_cur][v_x3_cur])
          ;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- [][][][] << [][][][]
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
              (i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] << i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur])
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
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_opr_shift_left
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
--   , ((sm_sc.fv_new_rand(array[   1, 4, 5]) -` 0.3 :: float) *` 10 :: float) :: int[]
--   );


-- select 
--   sm_sc.fv_opr_shift_left
--   ( 
--     (
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
--   , ((sm_sc.fv_new_rand(array[2, 3, 1, 5]) -` 0.3 :: float) *` 10 :: float) :: int[]
--   );
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[1, 2], array[-1, -2]]
--   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[B'010'], array[B'011']],
--     array[array[1, 2], array[-1, -2]]
--   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[B'010', B'011'], array[B'101', B'011']],
--     array[array[1], array[2]]
--   );
-- -- select sm_sc.fv_opr_shift_left
-- --   (
-- --     array[B'101', B'011'],
-- --     array[array[1, 2], array[-1, -2]]
-- --   );
-- -- select sm_sc.fv_opr_shift_left
-- --   (
-- --     array[array[B'101', B'011'], array[B'101', B'011']],
-- --     array[1, -1]
-- --   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[B'101', B'011']],
--     array[array[1, 2], array[-1, -2]]
--   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[B'101', B'011'], array[B'101', B'011']],
--     array[array[1, -1]]
--   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[]::bit[],
--     array[array[], array []]::int[]
--   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[], array []]::bit[],
--     array[]::int[]
--   );
-- select sm_sc.fv_opr_shift_left
--   (
--     array[array[], array []]::bit[],
--     array[array[], array []]::int[]
--   );
-- select sm_sc.fv_opr_shift_left(array[B'101'], array[1, 2]);
-- select sm_sc.fv_opr_shift_left(array[B'101'], array[array[1, 2]]);
-- select sm_sc.fv_opr_shift_left(array[array[B'011']], array[1, 2]);
-- select sm_sc.fv_opr_shift_left(array[array[B'011']], array[array[1, 2]]);
-- set session pg4ml._v_is_debug_check = '1';
-- set session pg4ml._v_is_debug_check = '0';
-- select 
--   sm_sc.fv_opr_shift_left
--   (
--     array[[[B'101', B'011', B'001'],[B'101', B'011', B'001']],[[B'101', B'011', B'001'],[B'101', B'011', B'001']]]
--   , array[[[1,2,-1],[1,2,-1]],[[1,2,-1],[1,2,-1]]]
--   )
-- select 
--   sm_sc.fv_opr_shift_left
--   (
--     array[[[[B'101', B'011', B'001'],[B'101', B'011', B'001']],[[B'101', B'011', B'001'],[B'101', B'011', B'001']]],[[[B'101', B'011', B'001'],[B'101', B'011', B'001']],[[B'101', B'011', B'001'],[B'101', B'011', B'001']]]]
--   , array[[[[1,2,-1],[1,2,-1]],[[1,2,-1],[1,2,-1]]],[[[-1,2,1],[1,-2,-1]],[[-1,2,-1],[1,-2,1]]]]
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_shift_left(varbit[], int);
create or replace function sm_sc.fv_opr_shift_left
(
  i_left     varbit[]    ,
  i_right    int  default 1
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
  -- null :: varbit[][] << varbit = null :: varbit[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::varbit[];

  -- [][] << varbit
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := i_left[v_y_cur][v_x_cur] << i_right;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] << varbit
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := i_left[v_y_cur] << i_right;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [][][] << varbit
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
            << i_right
          ;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- [][][][] << varbit
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
              << i_right
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

-- select sm_sc.fv_opr_shift_left(array[array[B'010', B'011'], array[B'011', B'010']], 2)
-- select sm_sc.fv_opr_shift_left(array[B'010011', B'011010'], 3)
-- select sm_sc.fv_opr_shift_left(array[]::bit[], 1)
-- select sm_sc.fv_opr_shift_left(array[array[], array []]::bit[], 1)
-- select 
--   sm_sc.fv_opr_shift_left
--   (
--     array[[[B'101', B'011', B'001'],[B'101', B'011', B'001']],[[B'101', B'011', B'001'],[B'101', B'011', B'001']]]
--   , 1
--   )
-- select 
--   sm_sc.fv_opr_shift_left
--   (
--     array[[[[B'101', B'011', B'001'],[B'101', B'011', B'001']],[[B'101', B'011', B'001'],[B'101', B'011', B'001']]],[[[B'101', B'011', B'001'],[B'101', B'011', B'001']],[[B'101', B'011', B'001'],[B'101', B'011', B'001']]]]
--   , -1
--   )

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_shift_left(varbit, int[]);
create or replace function sm_sc.fv_opr_shift_left
(
  i_left     varbit    ,
  i_right    int[]
)
returns varbit[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     varbit[]    ;
begin
  -- null :: varbit[][] << varbit = null :: varbit[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::varbit[];

  -- varbit << [][]
  elsif array_ndims(i_right) =  2
  then
    v_ret := array_fill(null::varbit, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := i_left << i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- varbit << []
  elsif array_ndims(i_right) =  1
  then
    v_ret := array_fill(null::varbit, array[array_length(i_right, 1)]);
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := i_left << i_right[v_y_cur];
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- varbit << [][][]
  elsif array_ndims(i_right) = 3
  then
    v_ret := array_fill(null::varbit, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3)]);
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] = 
            i_left 
            << i_right[v_y_cur][v_x_cur][v_x3_cur] 
          ;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- varbit << [][][][]
  elsif array_ndims(i_right) = 4
  then
    v_ret := array_fill(null::varbit, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3), array_length(i_right, 4)]);
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              i_left
              << i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] 
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

-- select sm_sc.fv_opr_shift_left(B'110', array[array[1, 3], array[-1, 2]])
-- select sm_sc.fv_opr_shift_left(B'011101', array[2, 3])
-- select sm_sc.fv_opr_shift_left(B'011', array[]::int[] )
-- select sm_sc.fv_opr_shift_left(B'010', array[array[], array []]::int[])
-- select 
--   sm_sc.fv_opr_shift_left
--   (
--     B'1011001001010110'
--   , array[[[1,2,-1],[1,2,-1]],[[1,2,-1],[1,2,-1]]]
--   )
-- select 
--   sm_sc.fv_opr_shift_left
--   (
--     B'1011001001010110'
--   , array[[[[1,2,-1],[1,2,-1]],[[1,2,-1],[1,2,-1]]],[[[-1,2,1],[1,-2,-1]],[[-1,2,-1],[1,-2,1]]]]
--   )
