-- drop function if exists sm_sc.fv_arr_remove_1d(anyarray, anyarray);
create or replace function sm_sc.fv_arr_remove_1d
(
  i_arr                anyarray
, i_remove_eles        anyarray
)
returns anyarray
as
$$
declare -- here
  v_cur    int;
begin
  for v_cur in 1 .. array_length(i_remove_eles, 1)
  loop 
    i_arr := array_remove(i_arr, i_remove_eles[v_cur]);
  end loop;
  
  return i_arr;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_arr_remove_1d(array[1,2,3,4,5,3,4,5,6,7], array[3,5]);