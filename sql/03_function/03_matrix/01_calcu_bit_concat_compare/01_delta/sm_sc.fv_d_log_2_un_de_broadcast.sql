-- drop function if exists sm_sc.fv_d_log_2_un_de_broadcast(float[][], float[][]);
create or replace function sm_sc.fv_d_log_2_un_de_broadcast
(
  i_indepdt_var float[][] , 
  i_co_value    float[][]
)
returns float[][]
as
$$
declare 
begin
  return
    /` (i_indepdt_var *` (^!` i_co_value :: decimal[]) :: float[])
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_log_2_un_de_broadcast
--   (
--     array[2.8, 3.6]
--   , array[1.8, 4.6]
--   )
-- select 
--   sm_sc.fv_d_log_2_un_de_broadcast
--   (
--     array[[1.8, 4.6], [1.4, 3.6]], 
--     array[[2.8, 3.6], [2.4, 1.6]]
--   )
-- select 
--   sm_sc.fv_d_log_2_un_de_broadcast(array[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]]
--                  , array[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]])
-- select 
--   sm_sc.fv_d_log_2_un_de_broadcast(array[[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]],[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]]]
--                  , array[[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]],[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]]])
