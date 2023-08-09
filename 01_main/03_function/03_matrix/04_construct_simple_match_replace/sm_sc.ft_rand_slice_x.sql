-- set search_path to sm_sc;
-- drop function if exists sm_sc.ft_rand_slice_x(anyarray, int);
create or replace function sm_sc.ft_rand_slice_x
(
  i_array          anyarray          ,
  i_select_cnt     int
)
returns table
(
  o_ord_nos   int[],
  o_slices    anyarray
)
as
$$
-- declare

begin
  -- set search_path to sm_sc;
  if array_ndims(i_array) is null
  then 
    return query
      select null, i_array;
  elsif array_ndims(i_array) = 2 and i_select_cnt <= array_length(i_array, 2)
  then
    return query
      select
        array_agg(a_cur) as o_ord_nos,
        sm_sc.fa_mx_concat_x(i_array[ : ][a_cur : a_cur]) as o_slices
      from unnest(sm_sc.fv_rand_1d_ele(array_length(i_array, 2), i_select_cnt)) tb_a_cur(a_cur)
    ;
  else
    raise notice 'no method for such length!  Ndim: %; pick_cnt: %; len_2: %;', array_ndims(i_array), i_select_cnt, array_length(i_array, 2);
    return query select null, null where false; 
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.ft_rand_slice_x
--   (
--     array[array[1, 2, 3, 4, 5, 6], array[7, 8, 9, 10, 11, 12]]
--     , 3
--     -- , true
--   );