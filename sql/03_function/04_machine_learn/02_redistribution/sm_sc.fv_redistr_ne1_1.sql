-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_redistr_ne1_1(float[]);
create or replace function sm_sc.fv_redistr_ne1_1
(
  i_array          float[]
)
returns float[]
as
$$
declare -- here
  v_max     float   :=   |@>| i_array ;
  v_min     float   :=   |@<| i_array ;
  v_ptp     float   :=   v_max - v_min;      
  v_2_median  float   :=   v_max + v_min;
begin
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) <= 4
  then
    if abs(v_ptp) < 1e-256
    then 
      return array_fill(0.0 :: float, (select array_agg(array_length(i_array, a_dim) order by a_dim) from generate_series(1, array_ndims(i_array)) tb_a_dim(a_dim)));
    else 
      return (i_array -` v_2_median) /` (v_ptp / 2.0);
    end if;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_redistr_ne1_1
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]::float[]
--   );

-- select sm_sc.fv_redistr_ne1_1
--   (
--     array[1,2,3,4,5,6]::float[]
--   );

-- select sm_sc.fv_redistr_ne1_1
--   (
--     array[[[1,2,3,4,25,6],[-1,-2,-3,4,5,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,5,6]]]::float[]
--   );

-- select sm_sc.fv_redistr_ne1_1
--   (
--     array[[[[1,2,3,4,25,6],[-1,-2,-3,4,35,6]],[[1,2,3,-4,-5,-36],[1,12,3,14,25,6]]],[[[1,12,3,4,25,6],[-1,-42,-3,4,5,6]],[[1,2,13,-4,-5,-36],[1,12,3,14,5,6]]]]::float[]
--   );

-- select sm_sc.fv_redistr_ne1_1
--   (
--     array[]::float[]
--   );

-- select sm_sc.fv_redistr_ne1_1
--   (
--     array[1.0, 1.0, 1.0]::float[]
--   );

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_redistr_ne1_1(float[], int[]);
create or replace function sm_sc.fv_redistr_ne1_1
(
  i_array          float[],
  i_cnt_per_grp    int[]
)
returns float[]
as
$$
declare 
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
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      i_array
        [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]] 
      := 
        sm_sc.fv_redistr_ne1_1
        (
          i_array
            [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
        );
    end loop;
    return i_array;
    
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
    -- --         sm_sc.fv_redistr_ne1_1(i_array[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]) 
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
    
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        i_array
          [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
          [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]] 
        := 
          sm_sc.fv_redistr_ne1_1
          (
            i_array
              [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
              [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
          );
      end loop;
    end loop;
    return i_array;
    
  elsif array_length(i_cnt_per_grp, 1) = 3
  then
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        for v_cur_x3 in 1 .. array_length(i_array, 3) / i_cnt_per_grp[3]
        loop 
          i_array
            [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
            [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
            [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]] 
          := 
            sm_sc.fv_redistr_ne1_1
            (
              i_array
                [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
                [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
                [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]]
            );
        end loop;
      end loop;
    end loop;
    return i_array;
    
  elsif array_length(i_cnt_per_grp, 1) = 4
  then
    for v_cur_y in 1 .. array_length(i_array, 1) / i_cnt_per_grp[1]
    loop 
      for v_cur_x in 1 .. array_length(i_array, 2) / i_cnt_per_grp[2]
      loop 
        for v_cur_x3 in 1 .. array_length(i_array, 3) / i_cnt_per_grp[3]
        loop 
          for v_cur_x4 in 1 .. array_length(i_array, 4) / i_cnt_per_grp[4]
          loop 
            i_array
              [(v_cur_y - 1) * i_cnt_per_grp[1] + 1 : v_cur_y * i_cnt_per_grp[1]]
              [(v_cur_x - 1) * i_cnt_per_grp[2] + 1 : v_cur_x * i_cnt_per_grp[2]]
              [(v_cur_x3 - 1) * i_cnt_per_grp[3] + 1 : v_cur_x3 * i_cnt_per_grp[3]]
              [(v_cur_x4 - 1) * i_cnt_per_grp[4] + 1 : v_cur_x4 * i_cnt_per_grp[4]] 
            := 
              sm_sc.fv_redistr_ne1_1
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
    return i_array;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_redistr_ne1_1
--   (
--     array[2.3, 5.1, 8.2, 2.56, 3.33, -1.9] :: float[]
--     , array[2]
--   )

-- select 
--   sm_sc.fv_redistr_ne1_1
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ] :: float[]
--     , array[2, 3]
--   )

-- select
--   sm_sc.fv_redistr_ne1_1
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15])
--   , array[2, 3, 3]
--   )

-- select
--   sm_sc.fv_redistr_ne1_1
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15, 8])
--   , array[2, 3, 3, 4]
--   )