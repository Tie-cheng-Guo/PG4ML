-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_norm(float[]);
create or replace function sm_sc.fv_opr_norm
(
  i_right     float[]
)
returns float[]
as
$$
-- declare 
begin
  return sm_sc.fv_opr_abs(i_right);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_norm
--   (
--     array[[-45.6], [-45.6]]
--   );
-- select sm_sc.fv_opr_norm
--   (
--     array[100.0]
--   );

-- drop function if exists sm_sc.fv_opr_norm(decimal[]);
create or replace function sm_sc.fv_opr_norm
(
  i_right     decimal[]
)
returns decimal[]
as
$$
-- declare 
begin
  return sm_sc.fv_opr_abs(i_right);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_norm
--   (
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_norm
--   (
--     100.0
--   );