-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_mirror(anyarray, int);
create or replace function sm_sc.fv_opr_mirror
(
  i_arr            anyarray,
  i_dim            int
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;    
  if pg_typeof(i_arr) = ('double precision[]' :: regtype)
  then 
    return sm_sc.fv_opr_mirror_py(i_arr, i_dim);
  else
    if i_dim = 1
    then 
      return sm_sc.__fv_mirror_y(i_arr);    
    elsif i_dim = 2
    then
      return sm_sc.__fv_mirror_x(i_arr);   
    elsif i_dim = 3
    then
      return sm_sc.__fv_mirror_x3(i_arr);   
    elsif i_dim = 4
    then
      return sm_sc.__fv_mirror_x4(i_arr);
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_opr_mirror
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , 3
--   );

