-- drop function if exists sm_sc.fv_aggr_chunk_min(float[], int[]);
create or replace function sm_sc.fv_aggr_chunk_min
(
  i_array          float[],
  i_cnt_per_grp    int[]
)
returns float[]
as
$$
declare 
  v_indepdt_len           int[]       := 
    (
      select 
        array_agg(array_length(i_array, a_cur_dim) order by a_cur_dim) 
      from generate_series(1, array_ndims(i_array)) tb_a_cur_dim(a_cur_dim)
    )
  ;
  
begin
  i_cnt_per_grp := 
    sm_sc.fv_coalesce
    (
      v_indepdt_len[ : array_length(v_indepdt_len, 1) - coalesce(array_length(i_cnt_per_grp, 1), 0)] || i_cnt_per_grp
    , v_indepdt_len
    )
  ;

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
    return 
    (
      select 
        sm_sc.fa_mx_min
        (
          i_array
            [a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1]
        )
      from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
    )
    ;
    
  elsif array_length(i_cnt_per_grp, 1) = 2
  then
    return 
    (
      select 
        sm_sc.fa_mx_min
        (
          i_array
            [a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1]
            [a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]
        )
      from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_array, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
    )
    ;
    
  elsif array_length(i_cnt_per_grp, 1) = 3
  then
    return 
    (
      select 
        sm_sc.fa_mx_min
        (
          i_array
            [a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1]
            [a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]
            [a_cur_x3 : a_cur_x3 + i_cnt_per_grp[3] - 1]
        )
      from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_array, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
        , generate_series(1, array_length(i_array, 3), i_cnt_per_grp[3]) tb_a_cur_x3(a_cur_x3)
    )
    ;
    
  elsif array_length(i_cnt_per_grp, 1) = 4
  then
    return 
    (
      select 
        sm_sc.fa_mx_min
        (
          i_array
            [a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1]
            [a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]
            [a_cur_x3 : a_cur_x3 + i_cnt_per_grp[3] - 1]
            [a_cur_x4 : a_cur_x4 + i_cnt_per_grp[4] - 1]
        )
      from generate_series(1, array_length(i_array, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_array, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
        , generate_series(1, array_length(i_array, 3), i_cnt_per_grp[3]) tb_a_cur_x3(a_cur_x3)
        , generate_series(1, array_length(i_array, 4), i_cnt_per_grp[4]) tb_a_cur_x4(a_cur_x4)
    )
    ;
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_aggr_chunk_min
--   (
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]
--          ] :: float[]
--     , array[2, 3]
--   ) :: decimal[] ~=` 6

-- select
--   sm_sc.fv_aggr_chunk_min
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15])
--   , array[2, 3, 3]
--   )

-- select
--   sm_sc.fv_aggr_chunk_min
--   (
--     sm_sc.fv_new_rand(array[6, 9, 15, 8])
--   , array[2, 3, 3, 4]
--   )