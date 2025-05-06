-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_turn_90(anyarray, int[2]);
create or replace function sm_sc.fv_opr_turn_90
(
  i_arr            anyarray,
  i_dims_from_to    int[2]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;    
  if pg_typeof(i_arr) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_turn_90_py(i_arr, i_dims_from_to);
  else
    if i_dims_from_to = array[1, 2]
    then 
      return sm_sc.__fv_turn_y_x_90(i_arr);    
    elsif i_dims_from_to = array[1, 3]
    then
      return sm_sc.__fv_turn_y_x3_90(i_arr);   
    elsif i_dims_from_to = array[1, 4]
    then
      return sm_sc.__fv_turn_y_x4_90(i_arr);   
    elsif i_dims_from_to = array[2, 3]
    then
      return sm_sc.__fv_turn_x_x3_90(i_arr);   
    elsif i_dims_from_to = array[2, 4]
    then
      return sm_sc.__fv_turn_x_x4_90(i_arr);   
    elsif i_dims_from_to = array[3, 4]
    then
      return sm_sc.__fv_turn_x3_x4_90(i_arr);   
    elsif i_dims_from_to = array[2, 1]
    then 
      return sm_sc.__fv_turn_x_y_90(i_arr);    
    elsif i_dims_from_to = array[3, 1]
    then
      return sm_sc.__fv_turn_x3_y_90(i_arr);   
    elsif i_dims_from_to = array[4, 1]
    then
      return sm_sc.__fv_turn_x4_y_90(i_arr);   
    elsif i_dims_from_to = array[3, 2]
    then
      return sm_sc.__fv_turn_x3_x_90(i_arr);   
    elsif i_dims_from_to = array[4, 2]
    then
      return sm_sc.__fv_turn_x4_x_90(i_arr);   
    elsif i_dims_from_to = array[4, 3]
    then
      return sm_sc.__fv_turn_x4_x3_90(i_arr);
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_opr_turn_90
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[3, 4]
--   );