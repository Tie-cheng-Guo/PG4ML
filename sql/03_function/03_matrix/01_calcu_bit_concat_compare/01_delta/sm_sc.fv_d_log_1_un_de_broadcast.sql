-- drop function if exists sm_sc.fv_d_log_1_un_de_broadcast(float[], float[], float[]);
create or replace function sm_sc.fv_d_log_1_un_de_broadcast
(
  i_indepdt_var float[] , 
  i_co_value    float[] ,
  i_depdt_var   float[] default null
)
returns float[]
as
$$
declare 
begin
  return
    case 
      when i_depdt_var is not null 
        then -` (i_depdt_var ^` 2.0 :: float) /` (i_indepdt_var *` (^!` i_co_value :: decimal[]) :: float[])      -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      else (-` ((i_indepdt_var :: decimal[] ^!` i_co_value :: decimal[]) :: float[] ^` 2.0 :: float)) /` (i_indepdt_var *` (^!` i_co_value :: decimal[]) :: float[])      -- -- sm_sc.fv_nullif(... , 0.0 :: float)
    end     -- 优先使用 i_depdt_var
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_log_1_un_de_broadcast(array[2.8, 3.6]
--                  , array[1.8, 4.6])
-- select 
--   sm_sc.fv_d_log_1_un_de_broadcast(array[[2.8, 3.6], [2.4, 1.6]]
--                  , array[[1.8, 4.6], [1.4, 3.6]])
-- select 
--   sm_sc.fv_d_log_1_un_de_broadcast(array[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]]
--                  , array[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]])
-- select 
--   sm_sc.fv_d_log_1_un_de_broadcast(array[[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]],[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]]]
--                  , array[[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]],[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]]])


-- select 
--   sm_sc.fv_d_log_1_un_de_broadcast
--   (
--     array[[2.8, 3.6], [2.4, 1.6]], 
--     array[[1.8, 4.6], [1.4, 3.6]],
--     array[[2.8, 3.6], [2.4, 1.6]] ^!` array[[1.8, 4.6], [1.4, 3.6]]
--   )