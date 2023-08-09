-- set search_path to sm_sc;
-- drop function if exists sm_sc.ft_rand_ele_x(anyarray, int);
create or replace function sm_sc.ft_rand_ele_x
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
  elsif array_ndims(i_array) = 1 and i_select_cnt <= array_length(i_array, 1)
  then 
    return query
      select 
        array_agg(a_cur) as o_ord_nos,
        array_agg(i_array[a_cur]) as o_slices
      from unnest(sm_sc.fv_rand_1d_ele(array_length(i_array, 1), i_select_cnt)) tb_a_cur(a_cur)
    ;
  elsif array_ndims(i_array) = 2 and i_select_cnt <= array_length(i_array, 1)
  then
    return query
      with 
      cte_cur_ys AS
      (
        select 
          a_cur_x,
          sm_sc.fv_rand_1d_ele(array_length(i_array, 1), i_select_cnt) as a_cur_ys
        from generate_series(1, array_length(i_array, 2)) t_a_cur_x(a_cur_x)
      ),
      cte_new_x AS
      (
        select 
          tb_a_cur_x.a_cur_x,
          array[a_cur_ys] as a_ord_nos,
          array_agg(i_array[a_cur_ys[a_cur_new_y]][a_cur_x] order by a_cur_new_y) as a_y_eles
        from generate_series(1, i_select_cnt) tb_a_cur_new_y(a_cur_new_y), cte_cur_ys tb_a_cur_x
        group by tb_a_cur_x.a_cur_x, tb_a_cur_x.a_cur_ys
      )
      select 
        |^~| sm_sc.fa_mx_concat_y(a_ord_nos order by a_cur_x) as o_ord_nos,
        |^~| array_agg(a_y_eles order by a_cur_x)
      from cte_new_x
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
-- select * from sm_sc.ft_rand_ele_x
--   (
--     array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10]]
--     , 1
--   ) tb_a;
-- select * from sm_sc.ft_rand_ele_x
--   (
--     array[array[1, 2], array[3, 4], array[5, 6], array[7, 8], array[9, 10], array[11, 12]]
--     , 3
--   ) tb_a;
-- select * from sm_sc.ft_rand_ele_x
--   (
--     array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
--     , 3
--   ) tb_a;
