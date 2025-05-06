-- set search_path to sm_sc;
-- drop function if exists sm_sc.ufv_query_by_heigh_col_idx_from_row(float[], int[]);
create or replace function sm_sc.ufv_query_by_heigh_col_idx_from_row
(
  i_row_arr    float[]
, i_col_idx    int[]
)
returns float[]
as
$$
declare -- here
  v_len_row_arr      int[]         := (select array_agg(array_length(i_row_arr, a_dim) order by a_dim) from generate_series(1, array_ndims(i_row_arr)) tb_a_dim(a_dim));
  v_len_col_idx      int[]         := (select array_agg(array_length(i_col_idx, a_dim) order by a_dim) from generate_series(1, array_ndims(i_col_idx)) tb_a_dim(a_dim));
  v_ret              i_row_arr%type;
  v_cur_y            int           ;
  v_cur_x            int           ;
  v_cur_x3           int           ;
  -- v_cur_x4           int           ;
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_row_arr) not between 2 and 4 or array_ndims(i_col_idx) not between 2 and 4
    then
      raise exception 'no method for such ndims. ';
      
    elsif array_ndims(i_row_arr) < array_ndims(i_col_idx)
    then 
      raise exception 'no method! i_row_arr ndims should >= i_col_idx. ';
      
    elsif v_len_col_idx[array_ndims(i_col_idx)] <> 1
    then 
      raise exception 'width of i_col_idx should be 1. ';
      
    elsif 
      v_len_row_arr[array_ndims(i_row_arr) - array_ndims(i_col_idx) + 1 : array_ndims(i_row_arr) - 1]
      <>
      v_len_col_idx[ : array_ndims(i_col_idx) - 1]
    then 
      raise exception 'unmatch array_length between row_arr and col_idx';
      
    elsif 
      sm_sc.fv_aggr_slice_and
      (
        i_col_idx <=` v_len_row_arr[array_ndims(i_row_arr)]
      )
    then 
      raise exception 'overflow length col_idx for row_arr''s width. ';
      
    end if;
  end if;

  if array_length(v_len_col_idx, 1) = 2
  then 
    if array_length(v_len_row_arr, 1) = 2
    then 
      v_ret := array_fill(0.0 :: float, v_len_col_idx);
      for v_cur_y in 1 .. v_len_row_arr[1]
      loop 
        v_ret[v_cur_y][1] := i_row_arr[v_cur_y][i_col_idx[v_cur_y][1]];
      end loop;
      -- -- return 
      -- -- (
      -- --   select 
      -- --     sm_sc.fa_mx_concat_y
      -- --     (
      -- --       i_row_arr[a_row_idx][i_col_idx[a_row_idx]]
      -- --       order by a_row_idx
      -- --     )
      -- --   from generate_series(1, v_len_row_arr[1]) tb_a_row_idx(a_row_idx)
      -- -- )
      -- -- ;
      
    elsif array_length(v_len_row_arr, 1) = 3
    then
      v_ret := array_fill(0.0 :: float, v_len_row_arr[1] || v_len_col_idx);
      for v_cur_y in 1 .. v_len_row_arr[1]
      loop 
        for v_cur_x in 1 .. v_len_row_arr[2]
        loop 
          v_ret[v_cur_y][v_cur_x][1] := i_row_arr[v_cur_y][v_cur_x][i_col_idx[v_cur_x][1]];
        end loop;
      end loop;
    
    elsif array_length(v_len_row_arr, 1) = 4
    then
      v_ret := array_fill(0.0 :: float, v_len_row_arr[1 : 2] || v_len_col_idx);
      for v_cur_y in 1 .. v_len_row_arr[1]
      loop 
        for v_cur_x in 1 .. v_len_row_arr[2]
        loop 
          for v_cur_x3 in 1 .. v_len_row_arr[3]
          loop 
            v_ret[v_cur_y][v_cur_x][v_cur_x3][1] := i_row_arr[v_cur_y][v_cur_x][v_cur_x3][i_col_idx[v_cur_x3][1]];
          end loop;
        end loop;
      end loop;
    end if;
  
  elsif array_length(v_len_col_idx, 1) = 3
  then 
    if array_length(v_len_row_arr, 1) = 3
    then
      v_ret := array_fill(0.0 :: float, v_len_col_idx);
      for v_cur_y in 1 .. v_len_row_arr[1]
      loop 
        for v_cur_x in 1 .. v_len_row_arr[2]
        loop 
          v_ret[v_cur_y][v_cur_x][1] := i_row_arr[v_cur_y][v_cur_x][i_col_idx[v_cur_y][v_cur_x][1]];
        end loop;
      end loop;
    
    elsif array_length(v_len_row_arr, 1) = 4
    then
      v_ret := array_fill(0.0 :: float, v_len_row_arr[1] || v_len_col_idx);
      for v_cur_y in 1 .. v_len_row_arr[1]
      loop 
        for v_cur_x in 1 .. v_len_row_arr[2]
        loop 
          for v_cur_x3 in 1 .. v_len_row_arr[3]
          loop 
            v_ret[v_cur_y][v_cur_x][v_cur_x3][1] := i_row_arr[v_cur_y][v_cur_x][v_cur_x3][i_col_idx[v_cur_x][v_cur_x3][1]];
          end loop;
        end loop;
      end loop;
    end if; 
    
  elsif array_length(v_len_col_idx, 1) = 4
  then 
    if array_length(v_len_row_arr, 1) = 4
    then
      v_ret := array_fill(0.0 :: float, v_len_col_idx);
      for v_cur_y in 1 .. v_len_row_arr[1]
      loop 
        for v_cur_x in 1 .. v_len_row_arr[2]
        loop 
          for v_cur_x3 in 1 .. v_len_row_arr[3]
          loop 
            v_ret[v_cur_y][v_cur_x][v_cur_x3][1] := i_row_arr[v_cur_y][v_cur_x][v_cur_x3][i_col_idx[v_cur_y][v_cur_x][v_cur_x3][1]];
          end loop;
        end loop;
      end loop;
    end if; 
    
  end if;
  
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.ufv_query_by_heigh_col_idx_from_row
--   ( 
--     sm_sc.fv_new_rand(array[3, 5]) 
--   , ((sm_sc.fv_new_rand(array[3, 1]) *` 5.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )
-- select 
--   sm_sc.ufv_query_by_heigh_col_idx_from_row
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 5]) 
--   , ((sm_sc.fv_new_rand(array[3, 1]) *` 5.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )
-- select 
--   sm_sc.ufv_query_by_heigh_col_idx_from_row
--   ( 
--     sm_sc.fv_new_rand(array[2, 2, 3, 5]) 
--   , ((sm_sc.fv_new_rand(array[3, 1]) *` 5.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )

-- select 
--   sm_sc.ufv_query_by_heigh_col_idx_from_row
--   ( 
--     sm_sc.fv_new_rand(array[3, 2, 5]) 
--   , ((sm_sc.fv_new_rand(array[3, 2, 1]) *` 5.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )
-- select 
--   sm_sc.ufv_query_by_heigh_col_idx_from_row
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 2, 5]) 
--   , ((sm_sc.fv_new_rand(array[   3, 2, 1]) *` 5.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )

-- select 
--   sm_sc.ufv_query_by_heigh_col_idx_from_row
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 2, 5]) 
--   , ((sm_sc.fv_new_rand(array[2, 3, 2, 1]) *` 5.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )