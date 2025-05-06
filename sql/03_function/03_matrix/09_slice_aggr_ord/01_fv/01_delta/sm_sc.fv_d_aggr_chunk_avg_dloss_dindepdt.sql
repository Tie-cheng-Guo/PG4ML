-- drop function if exists sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt(int[], anyarray);
create or replace function sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt
(
  i_indepdt_len    int[],
  i_dloss_ddepdt   anyarray
)
returns anyarray
as
$$
declare   
  v_dloss_ddepdt_len   int[]   :=  (select array_agg(array_length(i_dloss_ddepdt, a_ndim)) from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a_ndims(a_ndim));
begin
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_indepdt_len) <> 1
    then 
      raise exception 'unsupport for ndims of i_indepdt_len > 1';
    elsif array_ndims(i_dloss_ddepdt) <> array_length(i_indepdt_len, 1)
    then 
      raise exception 'unmatch between dims of i_indepdt, i_depdt and i_dloss_ddepdt.';
    elsif 0 <> any(i_indepdt_len %` v_dloss_ddepdt_len)
    then
      raise exception 'unperfect i_indepdt_len for i_dloss_ddepdt at some dims';
    end if;
  end if;
    
  if i_dloss_ddepdt is null
  then 
    return null;
  else
    return sm_sc.fv_new
    (
      i_dloss_ddepdt /` sm_sc.fv_aggr_slice_prod(i_indepdt_len / v_dloss_ddepdt_len) :: float
    , i_indepdt_len / v_dloss_ddepdt_len
    );
  end if;
  
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt
--   (
--     array[6]
--   , sm_sc.fv_new_rand(array[3])
--   )

-- select 
--   sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt
--   (
--     array[6, 8]
--   , sm_sc.fv_new_rand(array[3, 2])
--   )

-- select 
--   sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt
--   (
--     array[6, 8, 8]
--   , sm_sc.fv_new_rand(array[3, 2, 2])
--   )

-- select 
--   sm_sc.fv_d_aggr_chunk_avg_dloss_dindepdt
--   (
--     array[6, 8, 8, 6]
--   , sm_sc.fv_new_rand(array[3, 2, 2, 3])
--   )