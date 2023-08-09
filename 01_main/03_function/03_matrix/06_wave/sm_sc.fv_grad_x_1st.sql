-- drop function if exists sm_sc.fv_grad_x_1st;
create or replace function sm_sc.fv_grad_x_1st
(
  i_array        anyarray
)
returns anyarray
as
$$
-- declare

begin
  if array_ndims(i_array) > 2
  then
    raise exception 'no method!';

  elsif array_ndims(i_array) = 1 and array_length(i_array, 1) > 1
  then
    return 
      i_array[2 : ] -` i_array[ : array_length(i_array, 1) - 1];
  
  elsif array_length(i_array, 2) > 1
  then
    return
      i_array[ : ][2 : ] -` i_array[ : ][ : array_length(i_array, 2) - 1];
  
  else 
    return array[] :: i_array%type;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_grad_x_1st
--   (
--     array[array[1, 2, 3, 4], array[-1, -2, -3, -4], array[-3, -2, -4, -1]]
--   );

-- select sm_sc.fv_grad_x_1st
--   (
--     array[1, 2, 3, 4]
--   );