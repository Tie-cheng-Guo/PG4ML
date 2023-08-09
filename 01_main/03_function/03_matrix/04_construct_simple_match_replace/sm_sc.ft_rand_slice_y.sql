-- set search_path to sm_sc;
-- drop function if exists sm_sc.ft_rand_slice_y(anyarray, int);
create or replace function sm_sc.ft_rand_slice_y
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
  elsif array_ndims(i_array) = 2 and i_select_cnt <= array_length(i_array, 1)
  then
    return query	
      select
        array_agg(a_cur) as o_ord_nos,
        sm_sc.fa_mx_concat_y(i_array[a_cur : a_cur][ : ]) as o_slices
      from unnest(sm_sc.fv_rand_1d_ele(array_length(i_array, 1), i_select_cnt)) tb_a_cur(a_cur)
  ;
  else
    raise notice 'no method for such length!  Ndim: %; pick_cnt: %; len_1: %;', array_ndims(i_array), i_select_cnt, array_length(i_array, 1);
    return query select null, null where false; 
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select * from sm_sc.ft_rand_slice_y
--   (
--     array[array[1.0 :: float, 2.0], array[3.0, 4.0], array[5.0, 6.0], array[7.0, 8.0], array[9.0, 10.0], array[11.0 :: float, 12.0]]
--     , 3
--     -- , true
--   ) tb_a;
