-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_reshape_dloss_dindepdt(float[], int[], int[]);
create or replace function sm_sc.fv_d_reshape_dloss_dindepdt
(
  i_dloss_ddepdt           float[]
, i_indepdt_len            int[]
)
returns float[]
as
$$
-- declare 
begin
  return sm_sc.fv_opr_reshape_py(i_dloss_ddepdt, i_indepdt_len);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_d_reshape_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[4,3,5,6])
--   , array[4,3,30]
--   );

