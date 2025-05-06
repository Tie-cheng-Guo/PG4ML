-- drop function if exists sm_sc.fv_d_exp(float[], float[]);
create or replace function sm_sc.fv_d_exp
(
  i_indepdt_var float[] , 
  i_depdt_var   float[] default null
)
returns float[]
as
$$
declare 
begin
  return
    case when i_depdt_var is not null then i_depdt_var else ^` i_indepdt_var end      
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_exp(array[1.8, -4.6])
-- select 
--   sm_sc.fv_d_exp(array[[1.8, -4.6], [1.4, 3.6]])
-- select 
--   sm_sc.fv_d_exp(array[[[1.8, -4.6], [1.4, 3.6]],[[1.8, -4.6], [1.4, 3.6]]])
-- select 
--   sm_sc.fv_d_exp(array[[[[1.8, -4.6], [1.4, 3.6]],[[1.8, -4.6], [1.4, 3.6]]],[[[1.8, -4.6], [1.4, 3.6]],[[1.8, -4.6], [1.4, 3.6]]]])

-- select 
--   sm_sc.fv_d_exp
--   (
--     array[[1.8, -4.6], [1.4, 3.6]],
--     ^` array[[1.8, -4.6], [1.4, 3.6]]
--   )

-- select 
--   sm_sc.fv_d_exp
--   (
--     null,
--     ^` array[[1.8, -4.6], [1.4, 3.6]]
--   )