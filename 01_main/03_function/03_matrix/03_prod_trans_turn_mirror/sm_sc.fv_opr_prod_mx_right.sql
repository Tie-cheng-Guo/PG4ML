-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_mx_right(float[], float[]);
create or replace function sm_sc.fv_opr_prod_mx_right
(
  i_right     float[]
)
returns float[]
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if array_ndims(i_right) <> 2
  then
    raise exception 'unsupport ndims!';
  end if;

  return (|^~| i_right) |**| i_right;

end
$$
language plpgsql stable
parallel safe
-- -- cost 100;
-- -- -- -- set search_path to sm_sc;
-- -- -- select sm_sc.fv_opr_prod_mx_right
-- -- --   (
-- -- --     array[array[1.0000,2.0000,3.0000], array[4.0000,5.0000,6.0000]]
-- -- --   );