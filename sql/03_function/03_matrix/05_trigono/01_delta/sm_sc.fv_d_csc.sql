-- drop function if exists sm_sc.fv_d_csc(float[][], float[][]);
create or replace function sm_sc.fv_d_csc
(
  i_indepdt_var float[][] , 
  i_depdt_var   float[][] default null
)
returns float[][]
as
$$
declare 
begin
  return
    case 
      when i_depdt_var is not null
        then (-` i_depdt_var) *` sm_sc.fv_cot(i_indepdt_var)::float[][]
      else -` (sm_sc.fv_cot(i_indepdt_var)::float[][] /` sm_sc.fv_sin(i_indepdt_var)::float[][])      -- 优先使用 i_depdt_var     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
    end  
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_csc(array[[0.8, -0.6], [0.4, 0.3]])

-- select 
--   sm_sc.fv_d_csc
--   (
--     array[[0.8, -0.6], [0.4, 0.3]],
--     sm_sc.fv_csc(array[[0.8, -0.6], [0.4, 0.3]])
--   )
