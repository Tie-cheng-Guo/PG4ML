-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt(float[]);
create or replace function sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt
(
  i_dloss_ddepdt            float[]
)
returns float[]
as
$$
-- declare 
begin
  return sm_sc.fv_lower_tri_mx_ex(i_dloss_ddepdt, 0.0 :: float);

end
$$
language plpgsql stable
cost 100;

-- select 
--   sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt
--   (
--     array[[1, 2, 3, 4], [-1, -2, -3, 4], [-1, 2, -3, -4], [1, -2, 3, -4]]
--   );

-- select 
--   sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt
--   (
--     array
--     [
--       [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     , [[1, 2, 3, 4, 5, 6], [-1, -2, -3, -4, -5, -6], [-1, 2, -3, 4, 5, -6], [1, -2, 3, 4, -5, 6]]
--     ]
--   );

-- select 
--   sm_sc.fv_d_lower_tri_mx_ex_dloss_dindepdt
--   (
--     array
--     [
--       [
--         [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       ]
--     , [
--         [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       , [[1, 2, 3], [-1, -2, -3], [-1, 2, -3], [1, -2, 3]]
--       ]
--     ]
--   );