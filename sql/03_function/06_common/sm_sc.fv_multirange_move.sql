-- drop function if exists sm_sc.fv_multirange_move(anymultirange, anyelement);
create or replace function sm_sc.fv_multirange_move
(
  i_multirange     anymultirange,
  i_move           anyelement
)
returns anymultirange
as
$$
--declare
begin
  return 
  (
    select 
      sm_sc.fa_range_or(multirange(sm_sc.fv_range_move(a_range, i_move)))
    from unnest(i_multirange) tb_a_range(a_range)
  )
  ;
end 
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_multirange_move(int8multirange(int8range(1, 3, '[]'), int8range(9, 10, '[]')), 10 :: bigint)
-- select sm_sc.fv_multirange_move(nummultirange(numrange(1.6, 3.9, '[]'), numrange(9.1, 10.8, '[]')), 12.1)