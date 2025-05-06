-- drop function if exists sm_sc.fv_d_tanh(float[][], float[][]);
create or replace function sm_sc.fv_d_tanh
(
  i_indepdt_var float[][],
  i_depdt_var   float[][]  default null
)
returns float[][]
as
$$
declare 
begin
  return
    case 
      when i_depdt_var is not null
        then 1.0 :: float-` (i_depdt_var ^` 2.0 :: float) 
      else
        -- /` (sm_sc.fv_cosh(i_indepdt_var)::float[][] ^` 2.0 :: float)      -- 优先使用 i_depdt_var     -- -- sm_sc.fv_nullif(... , 0.0 :: float)
        1.0 :: float-` (sm_sc.fv_tanh(i_indepdt_var)::float[][] ^` 2.0 :: float) 
    end
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_tanh(array[[1.8, 3.6], [2.4, 1.6]])

-- select 
--   sm_sc.fv_d_tanh
--   (
--     array[[1.8, 3.6], [2.4, 1.6]],
--     sm_sc.fv_tanh(array[[1.8, 3.6], [2.4, 1.6]])
--   )

-- select 
--   sm_sc.fv_d_tanh
--   (
--     null,
--     sm_sc.fv_tanh(array[[1.8, 3.6], [2.4, 1.6]])
--   )