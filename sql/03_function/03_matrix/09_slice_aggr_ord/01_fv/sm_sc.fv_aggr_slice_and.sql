-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_and(bit[]);
create or replace function sm_sc.fv_aggr_slice_and
(
  i_array          bit[]
)
returns bit
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) is null
  then
    return null;
  else
    return
    (
      select 
        bit_and(a_ele)
      from unnest(i_array) a_ele  -- tb_a(a_ele)  --  unnest 表内字段别名，对自定义复合类型数组的支持有 bug?，例如：select a_ele from unnest(array[(1.2, 2.3) :: sm_sc.typ_l_complex]) tb_a(a_ele)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[B'010', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011']]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[B'010', B'011', B'010', B'011', B'101', B'011', B'010', B'011']
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[[B'010', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011']]]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[[[B'010', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011']]]]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[] :: bit[]
--   );


-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_aggr_slice_and(bit[], int[]);
create or replace function sm_sc.fv_aggr_slice_and
(
  i_array          bit[],
  i_cnt_per_grp    int[]
)
returns bit[]
as
$$
declare 
  v_ret    i_array%type      ;
  v_cur_y  int               ;
  v_cur_x  int               ;
  v_cur_x3 int               ;
  v_cur_x4 int               ;
  
begin
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_cnt_per_grp) > 1 
    then 
      raise exception 'unsupport ndims of i_cnt_per_grp > 1.';
    elsif array_ndims(i_array) <> array_length(i_cnt_per_grp, 1)
    then 
      raise exception 'unmatch between ndims of i_array and length of i_cnt_per_grp.';
    elsif 
      0 <> any 
      (
        (
          select 
            array_agg(array_length(i_array, a_cur_dim) order by a_cur_dim) 
          from generate_series(1, array_ndims(i_array)) tb_a_cur_dim(a_cur_dim)
        )
        %` i_cnt_per_grp
      )
    then 
      raise exception 'unperfect i_array''s length for i_cnt_per_grp at some dims';
    end if;
  end if;
  
  if i_array is null
  then 
    return null;
    
  elsif array_length(i_cnt_per_grp, 1) = 1
  then 
    v_ret := 
      array_fill
      (
        nullif(i_array[1], i_array[1]), 
        array[array_length(i_array, 1) / i_cnt_per_grp[1]]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      v_ret[v_cur_y] := 
        sm_sc.fv_aggr_slice_and
        (
          i_array
          [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
        );
    end loop;
    return v_ret;
    
  elsif array_length(i_cnt_per_grp, 1) = 2
  then
    -- -- return 
    -- -- (
    -- --   with
    -- --   cte_slice_x as 
    -- --   (
    -- --     select 
    -- --       a_cur_y,
    -- --       array_agg
    -- --       (
    -- --         sm_sc.fv_aggr_slice_and(i_array[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]) 
    -- --         order by a_cur_x
    -- --       ) as a_slice_x
    -- --     from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
    -- --       , generate_series(1, array_length(i_array, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
    -- --     group by a_cur_y
    -- --   )
    -- --   select 
    -- --     array_agg(a_slice_x order by a_cur_y)
    -- --   from cte_slice_x
    -- -- )
    -- -- ;
    
    v_ret := 
      array_fill
      (
        nullif(i_array[1][1], i_array[1][1]), 
        array
        [
          array_length(i_array, 1) / i_cnt_per_grp[1], 
          array_length(i_array, 2) / i_cnt_per_grp[2]
        ]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        v_ret[v_cur_y][v_cur_x] := 
          sm_sc.fv_aggr_slice_and
          (
            i_array
            [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
            [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
          );
      end loop;
    end loop;
    return v_ret;
    
  elsif array_length(i_cnt_per_grp, 1) = 3
  then
    v_ret := 
      array_fill
      (
        nullif(i_array[1][1][1], i_array[1][1][1]), 
        array
        [
          array_length(i_array, 1) / i_cnt_per_grp[1], 
          array_length(i_array, 2) / i_cnt_per_grp[2], 
          array_length(i_array, 3) / i_cnt_per_grp[3]
        ]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        for v_cur_x3 in 1 .. array_length(i_array, 3) / i_cnt_per_grp[3]
        loop 
          v_ret[v_cur_y][v_cur_x][v_cur_x3] := 
            sm_sc.fv_aggr_slice_and
            (
              i_array
              [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
              [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
              [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]]
            );
        end loop;
      end loop;
    end loop;
    return v_ret;
    
  elsif array_length(i_cnt_per_grp, 1) = 4
  then
    v_ret := 
      array_fill
      (
        nullif(i_array[1][1][1][1], i_array[1][1][1][1]), 
        array
        [
          array_length(i_array, 1) / i_cnt_per_grp[1], 
          array_length(i_array, 2) / i_cnt_per_grp[2], 
          array_length(i_array, 3) / i_cnt_per_grp[3], 
          array_length(i_array, 4) / i_cnt_per_grp[4]
        ]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        for v_cur_x3 in 1 .. array_length(i_array, 3) / i_cnt_per_grp[3]
        loop 
          for v_cur_x4 in 1 .. array_length(i_array, 4) / i_cnt_per_grp[4]
          loop 
            v_ret[v_cur_y][v_cur_x][v_cur_x3][v_cur_x4] := 
              sm_sc.fv_aggr_slice_and
              (
                i_array
                [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
                [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
                [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]]
                [(v_cur_x4 - 1) * i_cnt_per_grp[4] + 1 : v_cur_x4 * i_cnt_per_grp[4]]
              );
          end loop;
        end loop;
      end loop;
    end loop;
    return v_ret;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_aggr_slice_and
--   (
--     array[[B'00101', B'10101', B'11101', B'10101', B'10101', B'10011']
--          ,[B'10101', B'10101', B'11101', B'10101', B'10101', B'10011']
--          ,[B'01101', B'11101', B'10101', B'10001', B'10101', B'10011']
--          ,[B'00101', B'00101', B'11101', B'10101', B'10001', B'10000']
--          ]
--     , array[2, 3]
--   ) 

-- select
--   sm_sc.fv_aggr_slice_and
--   (
--     array
--     [
--       [[B'00101', B'10101', B'11101', B'10101', B'10101', B'10011']
--       ,[B'10101', B'10101', B'11101', B'10101', B'10101', B'10011']
--       ,[B'01101', B'11101', B'10101', B'10001', B'10101', B'10011']
--       ,[B'00101', B'00101', B'11101', B'10101', B'10001', B'10000']
--       ]
--     ]
--   , array[1, 2, 3]
--   )

-- select
--   sm_sc.fv_aggr_slice_and
--   (
--     array
--     [[
--       [[B'00101', B'10101', B'11101', B'10101', B'10101', B'10011']
--       ,[B'10101', B'10101', B'11101', B'10101', B'10101', B'10011']
--       ,[B'01101', B'11101', B'10101', B'10001', B'10101', B'10011']
--       ,[B'00101', B'00101', B'11101', B'10101', B'10001', B'10000']
--       ]
--     ]]
--   , array[1, 1, 2, 3]
--   )
-- ----------------------------------------------------------------------------------------
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_and(boolean[]);
create or replace function sm_sc.fv_aggr_slice_and
(
  i_array          boolean[]
)
returns boolean
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) is null
  then
    return i_array[0];
  else
    return 
    ( 
      false <> all(i_array)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[true, false, false, true], [false, true, false, true], [true, false, false, false], [false, false, true, true], [true, true, false, true]]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[true, false, false, true, false, true, false, true]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[[true, false, false, true], [false, true, false, true], [true, false, false, false], [false, false, true, true], [true, true, false, true]]]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[[[[true, false, false, true], [false, true, false, true], [true, false, false, false], [false, false, true, true], [true, true, false, true]]]]
--   );

-- select sm_sc.fv_aggr_slice_and
--   (
--     array[] :: boolean[]
--   );


-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_aggr_slice_and(boolean[], int[]);
create or replace function sm_sc.fv_aggr_slice_and
(
  i_array          boolean[],
  i_cnt_per_grp    int[]
)
returns boolean[]
as
$$
declare 
  v_ret    i_array%type      ;
  v_cur_y  int               ;
  v_cur_x  int               ;
  v_cur_x3 int               ;
  v_cur_x4 int               ;
  
begin
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_cnt_per_grp) > 1 
    then 
      raise exception 'unsupport ndims of i_cnt_per_grp > 1.';
    elsif array_ndims(i_array) <> array_length(i_cnt_per_grp, 1)
    then 
      raise exception 'unmatch between ndims of i_array and length of i_cnt_per_grp.';
    elsif 
      0 <> any 
      (
        (
          select 
            array_agg(array_length(i_array, a_cur_dim) order by a_cur_dim) 
          from generate_series(1, array_ndims(i_array)) tb_a_cur_dim(a_cur_dim)
        )
        / i_cnt_per_grp
      )
    then 
      raise exception 'unperfect i_array''s length for i_cnt_per_grp at some dims';
    end if;
  end if;
  
  if i_array is null
  then 
    return null;
    
  elsif array_length(i_cnt_per_grp, 1) = 1
  then 
    v_ret := 
      array_fill
      (
        nullif(i_array[1], i_array[1]), 
        array[array_length(i_array, 1) / i_cnt_per_grp[1]]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      v_ret[v_cur_y] := 
        sm_sc.fv_aggr_slice_and
        (
          i_array
          [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
        );
    end loop;
    return v_ret;
    
  elsif array_length(i_cnt_per_grp, 1) = 2
  then
    -- -- return 
    -- -- (
    -- --   with
    -- --   cte_slice_x as 
    -- --   (
    -- --     select 
    -- --       a_cur_y,
    -- --       array_agg
    -- --       (
    -- --         sm_sc.fv_aggr_slice_and(i_array[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]) 
    -- --         order by a_cur_x
    -- --       ) as a_slice_x
    -- --     from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
    -- --       , generate_series(1, array_length(i_array, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
    -- --     group by a_cur_y
    -- --   )
    -- --   select 
    -- --     array_agg(a_slice_x order by a_cur_y)
    -- --   from cte_slice_x
    -- -- )
    -- -- ;
    
    v_ret := 
      array_fill
      (
        nullif(i_array[1][1], i_array[1][1]), 
        array
        [
          array_length(i_array, 1) / i_cnt_per_grp[1], 
          array_length(i_array, 2) / i_cnt_per_grp[2]
        ]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        v_ret[v_cur_y][v_cur_x] := 
          sm_sc.fv_aggr_slice_and
          (
            i_array
            [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
            [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
          );
      end loop;
    end loop;
    return v_ret;
    
  elsif array_length(i_cnt_per_grp, 1) = 3
  then
    v_ret := 
      array_fill
      (
        nullif(i_array[1][1][1], i_array[1][1][1]), 
        array
        [
          array_length(i_array, 1) / i_cnt_per_grp[1], 
          array_length(i_array, 2) / i_cnt_per_grp[2], 
          array_length(i_array, 3) / i_cnt_per_grp[3]
        ]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        for v_cur_x3 in 1 .. array_length(i_array, 3) / i_cnt_per_grp[3]
        loop 
          v_ret[v_cur_y][v_cur_x][v_cur_x3] := 
            sm_sc.fv_aggr_slice_and
            (
              i_array
              [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
              [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
              [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]]
            );
        end loop;
      end loop;
    end loop;
    return v_ret;
    
  elsif array_length(i_cnt_per_grp, 1) = 4
  then
    v_ret := 
      array_fill
      (
        nullif(i_array[1][1][1][1], i_array[1][1][1][1]), 
        array
        [
          array_length(i_array, 1) / i_cnt_per_grp[1], 
          array_length(i_array, 2) / i_cnt_per_grp[2], 
          array_length(i_array, 3) / i_cnt_per_grp[3], 
          array_length(i_array, 4) / i_cnt_per_grp[4]
        ]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        for v_cur_x3 in 1 .. array_length(i_array, 3) / i_cnt_per_grp[3]
        loop 
          for v_cur_x4 in 1 .. array_length(i_array, 4) / i_cnt_per_grp[4]
          loop 
            v_ret[v_cur_y][v_cur_x][v_cur_x3][v_cur_x4] := 
              sm_sc.fv_aggr_slice_and
              (
                i_array
                [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
                [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
                [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]]
                [(v_cur_x4 - 1) * i_cnt_per_grp[4] + 1 : v_cur_x4 * i_cnt_per_grp[4]]
              );
          end loop;
        end loop;
      end loop;
    end loop;
    return v_ret;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_aggr_slice_and
--   (
--     array[[true, false, false, true, true, false]
--          ,[true, true, false, true, false, false]
--          ,[false, true, false, true, true, true]
--          ,[false, true, true, false, true, true]
--          ,[false, false, true, false, false, true]
--          ,[true, true, false, true, true, false]
--          ]
--     , array[2, 3]
--   )

-- select
--   sm_sc.fv_aggr_slice_and
--   (
--     array
--     [
--       [[true, false, false, true, true, false]
--       ,[true, true, false, true, false, false]
--       ,[false, true, false, true, true, true]
--       ,[false, true, true, false, true, true]
--       ,[false, false, true, false, false, true]
--       ,[true, true, false, true, true, false]
--       ]
--     ]
--   , array[1, 2, 3]
--   )

-- select
--   sm_sc.fv_aggr_slice_and
--   (
--     array
--     [[
--       [[true, false, false, true, true, false]
--       ,[true, true, false, true, false, false]
--       ,[false, true, false, true, true, true]
--       ,[false, true, true, false, true, true]
--       ,[false, false, true, false, false, true]
--       ,[true, true, false, true, true, false]
--       ]
--     ]]
--   , array[1, 1, 2, 3]
--   )