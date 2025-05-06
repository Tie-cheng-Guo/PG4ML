-- drop function if exists sm_sc.fv_multirange_len(anymultirange);
create or replace function sm_sc.fv_multirange_len
(
  i_multirange     anymultirange
)
returns anyelement
as
$$
--declare
begin
  return 
  (
    select 
      sum(upper(a_range) - lower(a_range))
    from unnest(i_multirange) tb_a_range(a_range)
  )
  ;
end 
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_multirange_len(int8multirange(int8range(1, 3, '[]'), int8range(9, 10, '[]')))
-- select sm_sc.fv_multirange_len(nummultirange(numrange(1.6, 3.9, '[]'), numrange(9.1, 10.8, '[]')))