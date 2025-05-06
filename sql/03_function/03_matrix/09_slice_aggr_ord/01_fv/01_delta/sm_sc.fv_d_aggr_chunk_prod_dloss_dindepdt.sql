-- drop function if exists sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt(anyarray, anyarray, anyarray);
create or replace function sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt
(
  i_indepdt        anyarray,
  i_depdt          anyarray,
  i_dloss_ddepdt   anyarray
)
returns anyarray
as
$$
declare   
  v_dloss_ddepdt_len_y    int         := array_length(i_dloss_ddepdt, 1);
  v_dloss_ddepdt_len_x    int         := array_length(i_dloss_ddepdt, 2);
  v_dloss_ddepdt_len_x3   int         := array_length(i_dloss_ddepdt, 3);
  v_dloss_ddepdt_len_x4   int         := array_length(i_dloss_ddepdt, 4);
  v_indepdt_len_y         int         := array_length(i_indepdt, 1);
  v_indepdt_len_x         int         := array_length(i_indepdt, 2);
  v_indepdt_len_x3        int         := array_length(i_indepdt, 3);
  v_indepdt_len_x4        int         := array_length(i_indepdt, 4);
  v_ret                   float[]     ;
  v_cur_y                 int         ;
  v_cur_x                 int         ;
  v_cur_x3                int         ;
  v_cur_x4                int         ;
begin
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_indepdt) <> array_ndims(i_depdt)
      or array_ndims(i_indepdt) <> array_ndims(i_dloss_ddepdt)
    then 
      raise exception 'unmatch between dims of i_indepdt, i_depdt and i_dloss_ddepdt.';
    elsif 
      0 <> any 
      (
        (
          select 
            array_agg(array_length(i_indepdt, a_cur_dim) order by a_cur_dim) 
          from generate_series(1, array_ndims(i_indepdt)) tb_a_cur_dim(a_cur_dim)
        )
        %` 
        (
          select 
            array_agg(array_length(i_depdt, a_cur_dim) order by a_cur_dim) 
          from generate_series(1, array_ndims(i_depdt)) tb_a_cur_dim(a_cur_dim)
        )
      )
      or array_dims(i_indepdt) <> array_dims(i_dloss_ddepdt)
    then 
      raise exception 'unperfect i_indepdt''s length for i_depdt and i_dloss_ddepdt at some dims';
    end if;
  end if;
    
  if i_dloss_ddepdt is null
  then 
    return null;
    
  elsif array_ndims(i_dloss_ddepdt) = 1
  then    
    v_ret := array_fill(null :: float, array[v_indepdt_len_y]);
    for v_cur_y in 1 .. v_indepdt_len_y / v_dloss_ddepdt_len_y
    loop 
      v_ret
        [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
      :=
        i_dloss_ddepdt *` 
        i_depdt /` 
        i_indepdt
          [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
      ;        
    end loop;
    
  elsif array_ndims(i_dloss_ddepdt) = 2
  then  
    v_ret := array_fill(null :: float, array[v_indepdt_len_y, v_indepdt_len_x]);  
    for v_cur_y in 1 .. v_indepdt_len_y / v_dloss_ddepdt_len_y
    loop 
      for v_cur_x in 1 .. v_indepdt_len_x / v_dloss_ddepdt_len_x
      loop 
        v_ret
          [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
          [(v_cur_x - 1) * v_dloss_ddepdt_len_x + 1 : v_cur_x * v_dloss_ddepdt_len_x]
        :=
          i_dloss_ddepdt *` 
          i_depdt /` 
          i_indepdt
            [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
            [(v_cur_x - 1) * v_dloss_ddepdt_len_x + 1 : v_cur_x * v_dloss_ddepdt_len_x]
        ;        
      end loop;
    end loop;
    
  elsif array_ndims(i_dloss_ddepdt) = 3
  then    
    v_ret := array_fill(null :: float, array[v_indepdt_len_y, v_indepdt_len_x, v_indepdt_len_x3]);  
    for v_cur_y in 1 .. v_indepdt_len_y / v_dloss_ddepdt_len_y
    loop 
      for v_cur_x in 1 .. v_indepdt_len_x / v_dloss_ddepdt_len_x
      loop 
        for v_cur_x3 in 1 .. v_indepdt_len_x3 / v_dloss_ddepdt_len_x3
        loop 
          v_ret
            [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
            [(v_cur_x - 1) * v_dloss_ddepdt_len_x + 1 : v_cur_x * v_dloss_ddepdt_len_x]
            [(v_cur_x3 - 1) * v_dloss_ddepdt_len_x3 + 1 : v_cur_x3 * v_dloss_ddepdt_len_x3]
          :=
            i_dloss_ddepdt *` 
            i_depdt /` 
            i_indepdt
              [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
              [(v_cur_x - 1) * v_dloss_ddepdt_len_x + 1 : v_cur_x * v_dloss_ddepdt_len_x]
              [(v_cur_x3 - 1) * v_dloss_ddepdt_len_x3 + 1 : v_cur_x3 * v_dloss_ddepdt_len_x3]
          ;        
        end loop;
      end loop;
    end loop;
    
  elsif array_ndims(i_dloss_ddepdt) = 4
  then    
    v_ret := array_fill(null :: float, array[v_indepdt_len_y, v_indepdt_len_x, v_indepdt_len_x3, v_indepdt_len_x4]);  
    for v_cur_y in 1 .. v_indepdt_len_y / v_dloss_ddepdt_len_y
    loop 
      for v_cur_x in 1 .. v_indepdt_len_x / v_dloss_ddepdt_len_x
      loop 
        for v_cur_x3 in 1 .. v_indepdt_len_x3 / v_dloss_ddepdt_len_x3
        loop 
          for v_cur_x4 in 1 .. v_indepdt_len_x4 / v_dloss_ddepdt_len_x4
          loop 
            v_ret
              [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
              [(v_cur_x - 1) * v_dloss_ddepdt_len_x + 1 : v_cur_x * v_dloss_ddepdt_len_x]
              [(v_cur_x3 - 1) * v_dloss_ddepdt_len_x3 + 1 : v_cur_x3 * v_dloss_ddepdt_len_x3]
              [(v_cur_x4 - 1) * v_dloss_ddepdt_len_x4 + 1 : v_cur_x4 * v_dloss_ddepdt_len_x4]
            :=
              i_dloss_ddepdt *` 
              i_depdt /` 
              i_indepdt
                [(v_cur_y - 1) * v_dloss_ddepdt_len_y + 1 : v_cur_y * v_dloss_ddepdt_len_y]
                [(v_cur_x - 1) * v_dloss_ddepdt_len_x + 1 : v_cur_x * v_dloss_ddepdt_len_x]
                [(v_cur_x3 - 1) * v_dloss_ddepdt_len_x3 + 1 : v_cur_x3 * v_dloss_ddepdt_len_x3]
                [(v_cur_x4 - 1) * v_dloss_ddepdt_len_x4 + 1 : v_cur_x4 * v_dloss_ddepdt_len_x4]
            ;        
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

-- with 
-- cte_rand as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[6]) as a_indepdt
-- )
-- select 
--   sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_chunk_prod(a_indepdt, array[3])
--   , sm_sc.fv_new_rand(array[3])
--   )
-- from cte_rand

-- with 
-- cte_rand as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[6, 8]) as a_indepdt
-- )
-- select 
--   sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_chunk_prod(a_indepdt, array[3, 2])
--   , sm_sc.fv_new_rand(array[3, 2])
--   )
-- from cte_rand

-- with 
-- cte_rand as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[6, 8, 8]) as a_indepdt
-- )
-- select 
--   sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_chunk_prod(a_indepdt, array[3, 2, 2])
--   , sm_sc.fv_new_rand(array[3, 2, 2])
--   )
-- from cte_rand

-- with 
-- cte_rand as 
-- (
--   select 
--     sm_sc.fv_new_rand(array[6, 8, 8, 6]) as a_indepdt
-- )
-- select 
--   sm_sc.fv_d_aggr_chunk_prod_dloss_dindepdt
--   (
--     a_indepdt
--   , sm_sc.fv_aggr_chunk_prod(a_indepdt, array[3, 2, 2, 3])
--   , sm_sc.fv_new_rand(array[3, 2, 2, 3])
--   )
-- from cte_rand