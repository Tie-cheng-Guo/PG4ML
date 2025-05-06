-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_chunk_transpose_dloss_dindepdt(anyarray, int[2]);
create or replace function sm_sc.fv_d_chunk_transpose_dloss_dindepdt
(
  i_dloss_ddepdt     anyarray
, i_chunk_len        int[2]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
    
  if array_ndims(i_dloss_ddepdt) is null
  then 
    return i_dloss_ddepdt;
  elsif array_ndims(i_dloss_ddepdt) between 2 and 4
  then
    return 	
      sm_sc.fv_chunk_transpose(i_dloss_ddepdt, array[i_chunk_len[2], i_chunk_len[1]])
    ;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_dloss_ddepdt);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select 
--   sm_sc.fv_d_chunk_transpose_dloss_dindepdt
--   (
--     sm_sc.fv_chunk_transpose
--     (
--       sm_sc.fv_new_rand(array[6, 15])
--     , array[3, 5]
--     )
--   , array[3, 5]
--   );
-- select 
--   sm_sc.fv_d_chunk_transpose_dloss_dindepdt
--   (
--     sm_sc.fv_chunk_transpose
--     (
--       sm_sc.fv_new_rand(array[2, 6, 15])
--     , array[3, 5]
--     )
--   , array[3, 5]
--   );
-- select 
--   sm_sc.fv_d_chunk_transpose_dloss_dindepdt
--   (
--     sm_sc.fv_chunk_transpose
--     (
--       sm_sc.fv_new_rand(array[3, 2, 6, 15])
--     , array[3, 5]
--     )
--   , array[3, 5]
--   );