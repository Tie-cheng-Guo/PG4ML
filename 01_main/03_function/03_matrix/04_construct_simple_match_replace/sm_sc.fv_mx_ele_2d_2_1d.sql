-- drop function if exists sm_sc.fv_mx_ele_2d_2_1d(anyarray);
create or replace function sm_sc.fv_mx_ele_2d_2_1d
(
  i_ele_2d        anyarray
)
returns anyarray
as
$$
-- declare

begin
  return 
    array(select unnest(i_ele_2d))
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_ele_2d_2_1d
--   (
--     array[array[1, 2, 3, 4]]
--   );
-- select sm_sc.fv_mx_ele_2d_2_1d
--   (
--     array[array[1], array[2], array[3], array[4]]
--   );