-- drop function if exists sm_sc.fv_d_mx_concat_x4_dloss_dindepdt_n(float[], int, int, int[]);
create or replace function sm_sc.fv_d_mx_concat_x4_dloss_dindepdt_n
(
  i_dloss_ddepdt       float[] ,
  i_range_lower        int     ,
  i_range_upper        int     ,
  i_indepdt_len        int[]   default null
)
returns float[]
as
$$
declare 
begin
  return 
    sm_sc.fv_aggr_chunk_sum
    (
      i_dloss_ddepdt[ : ][ : ][ : ][i_range_lower : i_range_upper]
    , i_indepdt_len
    )
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_mx_concat_x4_dloss_dindepdt_n
--   (
--     array
--     [[[
--       [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
--     , [1.1, 2.1, 3.1, 4.1, 5.1, 6.1]
--     , [1.2, 2.2, 3.2, 4.2, 5.2, 6.2]
--     , [1.3, 2.3, 3.3, 4.3, 5.3, 6.3]
--     , [1.4, 2.4, 3.4, 4.4, 5.4, 6.4]
--     ]]]
--   , 2
--   , 3
--   )