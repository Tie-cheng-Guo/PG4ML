-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_chunk_dloss_dindepdt(float[], int[], int[]);
create or replace function sm_sc.fv_d_chunk_dloss_dindepdt
(
  i_dloss_ddepdt           float[]    ,
  i_indepdt_len            int[]      ,
  i_chunk_pos_per_dim      int[]
)
returns float[]
as
$$
declare 
  v_depdt_len   int[]    := (select array_agg(array_length(i_dloss_ddepdt, a_no) order by a_no) from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a(a_no));
begin
  -- set search_path to sm_sc;
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_dloss_ddepdt) not between 1 and 6
    then 
      raise exception 'unsupport ndims of i_dloss_ddepdt.';
    elsif array_length(i_indepdt_len, 1) <> array_ndims(i_dloss_ddepdt)
      or array_length(i_chunk_pos_per_dim, 1) <> array_ndims(i_dloss_ddepdt)
    then 
      raise exception 'unmatch i_indepdt_len or i_chunk_pos_per_dim. ';
    elsif true = any(i_indepdt_len <=` 0)
      or true = any(i_chunk_pos_per_dim <=` 0)
      or true = any((i_chunk_pos_per_dim +` i_indepdt_len) >` v_depdt_len)
    then 
      raise exception 'overflow of i_chunk_pos_per_dim + i_indepdt_len. ';
    end if;
  end if;
  
  return sm_sc.fv_area_replace(array_fill(0.0 :: float, i_indepdt_len), i_chunk_pos_per_dim, i_dloss_ddepdt);
  
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_d_chunk_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[4,3,5,6])
--   , array[8,7,9,8]
--   , array[3,2,1,2]
--   );

