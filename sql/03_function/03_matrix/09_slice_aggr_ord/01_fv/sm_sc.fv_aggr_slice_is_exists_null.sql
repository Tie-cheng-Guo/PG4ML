-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_is_exists_null(anyarray);
create or replace function sm_sc.fv_aggr_slice_is_exists_null
(
  i_array          anyarray,
  i_ele   anyelement   default  null
)
returns boolean
as
$$
declare 
  v_ret      boolean;
begin
  -- 审计二维长度
  if array_ndims(i_array) is null
  then
    return null;
  else
    v_ret   :=   false;
    foreach i_ele in array i_array
    loop 
      if i_ele is null 
      then 
        v_ret = true;
        exit;
      end if;
    end loop;
    return v_ret;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_is_exists_null(array[4, 6, 9, null])
-- select sm_sc.fv_aggr_slice_is_exists_null(array[[4, 6, 9, null], [5, 7, 3, 3]])
-- select sm_sc.fv_aggr_slice_is_exists_null(array[[[4, 6, 9, null], [5, 7, 3, 3]]])
-- select sm_sc.fv_aggr_slice_is_exists_null(array[[[[4, 6, 9, null], [5, 7, 3, 3]]]])

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_aggr_slice_is_exists_null(anyarray, int[]);
create or replace function sm_sc.fv_aggr_slice_is_exists_null
(
  i_array          anyarray,
  i_cnt_per_grp    int[]
)
returns boolean[]
as
$$
declare 
  v_ret    boolean[]      ;
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
        null :: boolean, 
        array[array_length(i_array, 1) / i_cnt_per_grp[1]]
      );
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      v_ret[v_cur_y] := 
        sm_sc.fv_aggr_slice_is_exists_null
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
    -- --         sm_sc.fv_aggr_slice_is_exists_null(i_array[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]) 
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
        null :: boolean, 
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
          sm_sc.fv_aggr_slice_is_exists_null
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
        null :: boolean, 
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
            sm_sc.fv_aggr_slice_is_exists_null
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
        null :: boolean, 
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
              sm_sc.fv_aggr_slice_is_exists_null
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
--   sm_sc.fv_aggr_slice_is_exists_null
--   (
--     array[1,2,null,4,5,6, null,20,30,40,null,60, 100,null,300,400,500,null]
--     , array[3]
--   )

-- select 
--   sm_sc.fv_aggr_slice_is_exists_null
--   (
--     array[[1,2,null,4,5,6]
--          ,[null,20,30,40,null,60]
--          ,[100,null,300,400,500,null]
--          ,[-1,null,-3,null,-5,-6]
--          ,[-1,null,-3,null,-5,-6]
--          ,[-10,null,-30,null,null,-60]]
--     , array[2, 3]
--   )

-- select 
--   sm_sc.fv_aggr_slice_is_exists_null
--   (
--     array[[[1,2,null,4,5,6]
--          ,[null,20,30,40,null,60]
--          ,[100,null,300,400,500,null]
--          ,[-1,null,-3,null,-5,-6]
--          ,[-1,null,-3,null,-5,-6]
--          ,[-10,null,-30,null,null,-60]]]
--     , array[1, 2, 3]
--   )

-- select 
--   sm_sc.fv_aggr_slice_is_exists_null
--   (
--     array[[[[1,2,null,4,5,6]
--          ,[null,20,30,40,null,60]
--          ,[100,null,300,400,500,null]
--          ,[-1,null,-3,null,-5,-6]
--          ,[-1,null,-3,null,-5,-6]
--          ,[-10,null,-30,null,null,-60]]]]
--     , array[1, 1, 2, 3]
--   )