-- set search_path to sm_sc;
-- drop function if exists sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1(float[], int[], int[]);
create or replace function sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
(
  i_dloss_ddepdt          float[]
, i_indepdt_len           int[]
, i_row_idx               int[]
)
returns float[]
as
$$
declare -- here
  v_indepdt_len_col       int    := i_indepdt_len[array_length(i_indepdt_len, 1) - 1];
  v_len_indepdt           int[]  
    :=  
      (select array_agg(array_length(i_dloss_ddepdt, a_dim) order by a_dim) from generate_series(1, array_ndims(i_dloss_ddepdt) - 2) tb_a_dim(a_dim))
      || 
      v_indepdt_len_col
      ||
      array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt))
  ;
  v_len_row_idx           int[]
    :=
      (select array_agg(array_length(i_row_idx, a_dim) order by a_dim) from generate_series(1, array_ndims(i_row_idx)) tb_a_dim(a_dim))
  ;
  v_dloss_dindepdt        float[];
  v_cur_y                 int    ;
  v_cur_x                 int    ;
  v_cur_x3                int    ;
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_length(v_len_indepdt, 1) not between 2 and 4 or array_ndims(i_row_idx) not between 2 and 4
    then
      raise exception 'no method for such ndims. ';
      
    elsif array_ndims(i_dloss_ddepdt) < array_ndims(i_row_idx)
    then 
      raise exception 'no method! i_col_arr ndims should >= i_row_idx. ';
      
    elsif array_length(i_row_idx, array_ndims(i_row_idx) - 1) <> 1
    then
      raise exception 'heigh of i_row_idx should be 1. ';
      
    elsif 
      (v_len_indepdt[array_length(v_len_indepdt, 1) - array_ndims(i_row_idx) + 1 : array_length(v_len_indepdt, 1) - 2] || v_indepdt_len_col || v_len_indepdt[array_length(v_len_indepdt, 1)])
      <>
      v_len_row_idx[ : array_ndims(i_row_idx)]
    then 
      raise exception 'unmatch array_length between indepdt and row_idx';
      
    elsif 
      sm_sc.fv_aggr_slice_and
      (
        i_row_idx <=` v_len_indepdt[array_length(v_len_indepdt, 1) - 1]
      )
    then 
      raise exception 'overflow length row_idx for indepdt''s heigh. ';
    end if;
  end if;

  -- 初始化自变量
  v_dloss_dindepdt := array_fill(0.0 :: float, v_len_indepdt);
  if array_length(v_len_row_idx, 1) = 2
  then 
    if array_length(v_len_indepdt, 1) = 2
    then
      for v_cur_x in 1 .. v_len_indepdt[2]
      loop 
        v_dloss_dindepdt[i_row_idx[1][v_cur_x]][v_cur_x] := i_dloss_ddepdt[1][v_cur_x];
      end loop;
    
    elsif array_length(v_len_indepdt, 1) = 3
    then
      for v_cur_y in 1 .. v_len_indepdt[1]
      loop 
        for v_cur_x3 in 1 .. v_len_indepdt[3]
        loop 
          v_dloss_dindepdt[v_cur_y][i_row_idx[1][v_cur_x3]][v_cur_x3] := i_dloss_ddepdt[v_cur_y][1][v_cur_x3];
        end loop;
      end loop;
      
    elsif array_length(v_len_indepdt, 1) = 4
    then
      for v_cur_y in 1 .. v_len_indepdt[1]
      loop 
        for v_cur_x in 1 .. v_len_indepdt[2]
        loop 
          for v_cur_x4 in 1 .. v_len_indepdt[4]
          loop 
            v_dloss_dindepdt[v_cur_y][v_cur_x][i_row_idx[1][v_cur_x4]][v_cur_x4] := i_dloss_ddepdt[v_cur_y][v_cur_x][1][v_cur_x4];
          end loop;
        end loop;
      end loop;
      
    end if;
  
  elsif array_length(v_len_row_idx, 1) = 3
  then 
    if array_length(v_len_indepdt, 1) = 3
    then 
      for v_cur_y in 1 .. v_len_indepdt[1]
      loop 
        for v_cur_x3 in 1 .. v_len_indepdt[3]
        loop 
          v_dloss_dindepdt[v_cur_y][i_row_idx[v_cur_y][1][v_cur_x3]][v_cur_x3] := i_dloss_ddepdt[v_cur_y][1][v_cur_x3];
        end loop;
      end loop;
    
    elsif array_length(v_len_indepdt, 1) = 4
    then
      for v_cur_y in 1 .. v_len_indepdt[1]
      loop 
        for v_cur_x in 1 .. v_len_indepdt[2]
        loop 
          for v_cur_x4 in 1 .. v_len_indepdt[4]
          loop 
            v_dloss_dindepdt[v_cur_y][v_cur_x][i_row_idx[v_cur_x][1][v_cur_x4]][v_cur_x4] := i_dloss_ddepdt[v_cur_y][v_cur_x][1][v_cur_x4];
          end loop;
        end loop;
      end loop;
    end if;
    
  elsif array_length(v_len_row_idx, 1) = 4
  then 
    for v_cur_y in 1 .. v_len_indepdt[1]
    loop 
      for v_cur_x in 1 .. v_len_indepdt[2]
      loop 
        for v_cur_x4 in 1 .. v_len_indepdt[4]
        loop 
          v_dloss_dindepdt[v_cur_y][v_cur_x][i_row_idx[v_cur_y][v_cur_x][1][v_cur_x4]][v_cur_x4] := i_dloss_ddepdt[v_cur_y][v_cur_x][1][v_cur_x4];
        end loop;
      end loop;
    end loop;
    
  end if;
  
  return v_dloss_dindepdt;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
--   ( 
--     sm_sc.fv_new_rand(array[1, 5]) 
--   , array[3, 5]
--   , ((sm_sc.fv_new_rand(array[1, 5]) *` 3.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )
-- select 
--   sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
--   ( 
--     sm_sc.fv_new_rand(array[2, 1, 5]) 
--   , array[2, 3, 5]
--   , ((sm_sc.fv_new_rand(array[1, 5]) *` 3.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )
-- select 
--   sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
--   ( 
--     sm_sc.fv_new_rand(array[2, 2, 1, 5]) 
--   , array[2, 2, 3, 5]
--   , ((sm_sc.fv_new_rand(array[1, 5]) *` 3.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )

-- select 
--   sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
--   ( 
--     sm_sc.fv_new_rand(array[2, 1, 5]) 
--   , array[2, 3, 5]
--   , ((sm_sc.fv_new_rand(array[2, 1, 5]) *` 3.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )
-- select 
--   sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5]) 
--   , array[2, 3, 3, 5]
--   , ((sm_sc.fv_new_rand(array[   3, 1, 5]) *` 3.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )

-- select 
--   sm_sc.ufv_d_query_by_width_row_idx_from_col_dloss_dindepdt_1
--   ( 
--     sm_sc.fv_new_rand(array[2, 3, 1, 5]) 
--   , array[2, 3, 3, 5]
--   , ((sm_sc.fv_new_rand(array[2, 3, 1, 5]) *` 3.0 :: float) :: decimal[] +` 0.5 ~=` 0) :: int[]
--   )