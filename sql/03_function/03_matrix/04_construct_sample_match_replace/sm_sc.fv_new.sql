-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new(anynonarray, int[]);
create or replace function sm_sc.fv_new
(
  i_meta_val                anynonarray    ,
  i_dims_repeat_times       int[]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if array_ndims(i_dims_repeat_times) > 1
  then
    raise exception 'no method!';
  elsif array_ndims(i_dims_repeat_times) is null
  then 
    return array[] :: i_meta_val%type;
  else
    return array_fill(i_meta_val, i_dims_repeat_times);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new
--   (
--     12.3,
--     array[5, 6]
--   );

-- drop function if exists sm_sc.fv_new(anyarray, int[]);
create or replace function sm_sc.fv_new
(
  i_meta_val     anyarray    ,
  i_dims_times        int[]
)
returns anyarray
as
$$
declare 
  v_ret     i_meta_val%type      :=   array_fill(nullif(i_meta_val[1], i_meta_val[1]), (select array_agg(array_length(i_meta_val, a_no)) from generate_series(1, array_ndims(i_meta_val)) tb_a(a_no)) * i_dims_times);
  v_cur_1   int                  ;
  v_cur_2   int                  ;
  v_cur_3   int                  ;
  v_cur_4   int                  ;
  v_cur_5   int                  ;
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_meta_val) not between 1 and 5
      or array_ndims(i_dims_times) <> 1 
      or array_length(i_dims_times, 1) > array_ndims(i_meta_val)
    then
      raise exception 'no method!';
    end if;
  end if;
  
  if array_ndims(i_meta_val) is null
  then 
    return array[] :: i_meta_val%type;
  elsif array_ndims(i_meta_val) = 1
  then
    -- -- return (select sm_sc.fa_array_concat(i_meta_val) from generate_series(1, coalesce(i_dims_times[1], 1)) tb_a);
    for v_cur_1 in 1 .. coalesce(i_dims_times[1], 0)
    loop 
      v_ret[array_length(i_meta_val, 1) * (v_cur_1 - 1) + 1 : array_length(i_meta_val, 1) * v_cur_1]   
        := i_meta_val;
    end loop;
    
  elsif array_ndims(i_meta_val) = 2
  then
    -- -- return 
    -- -- (
    -- --   with
    -- --   cte_y as 
    -- --   (
    -- --     select 
    -- --       sm_sc.fa_mx_concat_x(i_meta_val) as a_x_meta_val
    -- --     from generate_series(1, coalesce(i_dims_times[2], 0)) tb_a_x(a_x_no)
    -- --   )
    -- --   select 
    -- --     sm_sc.fa_mx_concat_y(a_x_meta_val) 
    -- --   from cte_y, generate_series(1, coalesce(i_dims_times[1], 0)) tb_a_y(a_y_no)
    -- -- );
    for v_cur_1 in 1 .. coalesce(i_dims_times[1], 0)
    loop 
      for v_cur_2 in 1 .. coalesce(i_dims_times[2], 0)
      loop 
        v_ret[array_length(i_meta_val, 1) * (v_cur_1 - 1) + 1 : array_length(i_meta_val, 1) * v_cur_1]   
             [array_length(i_meta_val, 2) * (v_cur_2 - 1) + 1 : array_length(i_meta_val, 2) * v_cur_2]
          := i_meta_val;
      end loop;
    end loop;
    
  elsif array_ndims(i_meta_val) = 3
  then
    -- -- return 
    -- -- (
    -- --   with
    -- --   cte_x as 
    -- --   (
    -- --     select 
    -- --       sm_sc.fa_mx_concat_x3(i_meta_val) as a_x_meta_val
    -- --     from generate_series(1, coalesce(i_dims_times[3], 0)) tb_a_x3(a_x3_no)
    -- --   ),
    -- --   cte_y_x as 
    -- --   (
    -- --     select 
    -- --       sm_sc.fa_mx_concat_x(a_x_meta_val) as a_y_x_meta_val
    -- --     from cte_x, generate_series(1, coalesce(i_dims_times[2], 0)) tb_a_x(a_x_no)
    -- --   )
    -- --   select 
    -- --     sm_sc.fa_mx_concat_y(a_y_x_meta_val) 
    -- --   from cte_y_x, generate_series(1, coalesce(i_dims_times[1], 0)) tb_a_y(a_y_no)
    -- -- );
    for v_cur_1 in 1 .. coalesce(i_dims_times[1], 0)
    loop 
      for v_cur_2 in 1 .. coalesce(i_dims_times[2], 0)
      loop 
        for v_cur_3 in 1 .. coalesce(i_dims_times[3], 0)
        loop 
          v_ret[array_length(i_meta_val, 1) * (v_cur_1 - 1) + 1 : array_length(i_meta_val, 1) * v_cur_1]   
               [array_length(i_meta_val, 2) * (v_cur_2 - 1) + 1 : array_length(i_meta_val, 2) * v_cur_2] 
               [array_length(i_meta_val, 3) * (v_cur_3 - 1) + 1 : array_length(i_meta_val, 3) * v_cur_3]
            := i_meta_val;
        end loop;
      end loop;
    end loop;
    
  elsif array_ndims(i_meta_val) = 4
  then
    -- -- return 
    -- -- (
    -- --   with
    -- --   cte_x3 as 
    -- --   (
    -- --     select 
    -- --       sm_sc.fa_mx_concat_x4(i_meta_val) as a_x3_meta_val
    -- --     from generate_series(1, coalesce(i_dims_times[4], 0)) tb_a_x4(a_x4_no)
    -- --   ),
    -- --   cte_x_x3 as 
    -- --   (
    -- --     select 
    -- --       sm_sc.fa_mx_concat_x3(a_x3_meta_val) as a_x_x3_meta_val
    -- --     from cte_x3, generate_series(1, coalesce(i_dims_times[3], 0)) tb_a_x3(a_x3_no)
    -- --   ),
    -- --   cte_y_x_x3 as 
    -- --   (
    -- --     select 
    -- --       sm_sc.fa_mx_concat_x(a_x_x3_meta_val) as a_y_x_x3_meta_val
    -- --     from cte_x_x3, generate_series(1, coalesce(i_dims_times[2], 0)) tb_a_x(a_x_no)
    -- --   )
    -- --   select 
    -- --     sm_sc.fa_mx_concat_y(a_y_x_x3_meta_val) 
    -- --   from cte_y_x_x3, generate_series(1, coalesce(i_dims_times[1], 0)) tb_a_y(a_y_no)
    -- -- );
    for v_cur_1 in 1 .. coalesce(i_dims_times[1], 0)
    loop 
      for v_cur_2 in 1 .. coalesce(i_dims_times[2], 0)
      loop 
        for v_cur_3 in 1 .. coalesce(i_dims_times[3], 0)
        loop 
          for v_cur_4 in 1 .. coalesce(i_dims_times[4], 0)
          loop 
            v_ret[array_length(i_meta_val, 1) * (v_cur_1 - 1) + 1 : array_length(i_meta_val, 1) * v_cur_1]   
                 [array_length(i_meta_val, 2) * (v_cur_2 - 1) + 1 : array_length(i_meta_val, 2) * v_cur_2] 
                 [array_length(i_meta_val, 3) * (v_cur_3 - 1) + 1 : array_length(i_meta_val, 3) * v_cur_3]
                 [array_length(i_meta_val, 4) * (v_cur_4 - 1) + 1 : array_length(i_meta_val, 4) * v_cur_4]
              := i_meta_val;
          end loop;
        end loop;
      end loop;
    end loop;
    
  elsif array_ndims(i_meta_val) = 5
  then
    for v_cur_1 in 1 .. coalesce(i_dims_times[1], 0)
    loop 
      for v_cur_2 in 1 .. coalesce(i_dims_times[2], 0)
      loop 
        for v_cur_3 in 1 .. coalesce(i_dims_times[3], 0)
        loop 
          for v_cur_4 in 1 .. coalesce(i_dims_times[4], 0)
          loop 
            for v_cur_5 in 1 .. coalesce(i_dims_times[5], 0)
            loop 
              v_ret[array_length(i_meta_val, 1) * (v_cur_1 - 1) + 1 : array_length(i_meta_val, 1) * v_cur_1]   
                   [array_length(i_meta_val, 2) * (v_cur_2 - 1) + 1 : array_length(i_meta_val, 2) * v_cur_2] 
                   [array_length(i_meta_val, 3) * (v_cur_3 - 1) + 1 : array_length(i_meta_val, 3) * v_cur_3]
                   [array_length(i_meta_val, 4) * (v_cur_4 - 1) + 1 : array_length(i_meta_val, 4) * v_cur_4]
                   [array_length(i_meta_val, 5) * (v_cur_5 - 1) + 1 : array_length(i_meta_val, 5) * v_cur_5]
                := i_meta_val;
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;
    
  end if;
  
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new
--   (
--     array[12.3, 156.6, 7.8, -93.6],
--     array[5]
--   );
-- select sm_sc.fv_new
--   (
--     array[[12.3, 156.6, 7.8, -93.6]],
--     array[5, 2]
--   );
-- select sm_sc.fv_new
--   (
--     array[[12.3, 3.3], [156.6, 3.3], [7.8, 3.3], [-93.6, 3.3]],
--     array[5, 2]
--   );
-- select sm_sc.fv_new
--   (
--     array[[12.3]],
--     array[5, 2]
--   );
-- select sm_sc.fv_new
--   (
--     array[[[1.2, 3.4],[5.6, 7.8]],[[-1.2, -3.4],[-5.6, -7.8]]],
--     array[4, 2, 3]
--   );
-- select sm_sc.fv_new
--   (
--     array[[[[1.2, 3.4],[5.6, 7.8]],[[-1.2, -3.4],[-5.6, -7.8]]],[[[0.2, 0.4],[0.6, 0.8]],[[-0.2, -0.4],[-0.6, -0.8]]]],
--     array[4, 2, 3, 2]
--   );
-- select sm_sc.fv_new
--   (
--     array[[[[[1.2, 3.4],[5.6, 7.8]],[[-1.2, -3.4],[-5.6, -7.8]]],[[[0.2, 0.4],[0.6, 0.8]],[[-0.2, -0.4],[-0.6, -0.8]]]],[[[[1.2, 3.4],[5.6, 7.8]],[[-1.2, -3.4],[-5.6, -7.8]]],[[[0.2, 0.4],[0.6, 0.8]],[[-0.2, -0.4],[-0.6, -0.8]]]]]
--   , array[4, 2, 3, 2, 2]
--   );