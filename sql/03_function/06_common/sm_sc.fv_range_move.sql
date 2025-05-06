-- drop function if exists sm_sc.fv_range_move(anyrange, anyelement);
create or replace function sm_sc.fv_range_move
(
  i_range          anyrange,
  i_move           anyelement
)
returns anyrange
as
$$
-- declare
--   v_range    text   :=   i_range;
begin
  return 
    case when lower_inc(i_range) then '[' else '(' end ||       -- substr(v_range, 1, 1) || 
    lower(i_range) + i_move || 
    ',' || 
    upper(i_range) + i_move || 
    case when upper_inc(i_range) then ']' else ')' end
  ;
end 
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_range_move(int8range(1, 3, '[]'), 6 :: bigint)
-- select sm_sc.fv_range_move(numrange(1.6, 3.9, '[]'), -2.9)