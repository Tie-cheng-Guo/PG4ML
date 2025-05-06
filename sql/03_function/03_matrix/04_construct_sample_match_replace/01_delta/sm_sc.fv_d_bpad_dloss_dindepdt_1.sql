-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_bpad_dloss_dindepdt_1(float[], int);
create or replace function sm_sc.fv_d_bpad_dloss_dindepdt_1
(
  i_dloss_ddepdt         float[]    ,
  i_indepdt_heigh        int
)
returns float[]
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_dloss_ddepdt) not between 2 and 4
    then 
      raise exception 'unsupport ndims.';
    end if;
  end if;
    
  if array_ndims(i_dloss_ddepdt) = 2
  then 
    return 
      i_dloss_ddepdt[1 : i_indepdt_heigh][ : ]
    ;
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    return 
      i_dloss_ddepdt[ : ][1 : i_indepdt_heigh][ : ]
    ;
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    return 
      i_dloss_ddepdt[ : ][ : ][1 : i_indepdt_heigh][ : ]
    ;
  end if;
end
$$
language plpgsql stable
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_bpad_dloss_dindepdt_1
--   (
--     array[[1, 2, 3, 4, 5],[11, 12, 13, 14, 15],[21, 22, 23, 24, 25],[31, 32, 33, 34, 35],[41, 42, 43, 44, 45]]
--   , 2
--   );