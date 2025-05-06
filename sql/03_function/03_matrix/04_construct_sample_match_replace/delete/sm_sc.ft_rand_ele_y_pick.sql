-- set search_path to sm_sc;
-- drop function if exists sm_sc.ft_rand_ele_y_pick(anyarray, int);
create or replace function sm_sc.ft_rand_ele_y_pick
(
  i_array          anyarray          ,
  i_pick_cnt       int
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
  elsif array_ndims(i_array) = 1 and i_pick_cnt <= array_length(i_array, 1)
  then 
    return query
      select 
        array_agg(a_cur) as o_ord_nos,
        array_agg(i_array[a_cur]) as o_slices
      from unnest(sm_sc.fv_rand_1d_ele_pick(array_length(i_array, 1), i_pick_cnt)) tb_a_cur(a_cur)
    ;
  elsif array_ndims(i_array) = 2 and i_pick_cnt <= array_length(i_array, 2)
  then
    return query
      with 
      cte_cur_xs AS
      (
        select 
          a_cur_y,
          sm_sc.fv_rand_1d_ele_pick(array_length(i_array, 2), i_pick_cnt) as a_cur_xs
        from generate_series(1, array_length(i_array, 1)) t_a_cur_y(a_cur_y)
      ),
      cte_new_y AS
      (
        select 
          tb_a_cur_y.a_cur_y,
          array[a_cur_xs] as a_ord_nos,
          array_agg(i_array[a_cur_y][a_cur_xs[a_cur_new_x]] order by a_cur_new_x) as a_y_eles
        from generate_series(1, i_pick_cnt) tb_a_cur_new_x(a_cur_new_x), cte_cur_xs tb_a_cur_y
        group by tb_a_cur_y.a_cur_y, tb_a_cur_y.a_cur_xs
      )
      select 
        sm_sc.fa_mx_concat_y(a_ord_nos order by a_cur_y) as o_ord_nos,
        array_agg(a_y_eles order by a_cur_y) as o_slices
      from cte_new_y
    ;
  else
    raise exception 'no method for such length!  Dim: %; pick_cnt: %;', array_dims(i_array), i_pick_cnt;
    return query select null, null where false; 
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select * from sm_sc.ft_rand_ele_y_pick
--   (
--     array[array[1, 2], array[3, 4], array[5, 6], array[7, 8], array[9, 10], array[11, 12]]
--     , 1
--   ) tb_a;
-- select * from sm_sc.ft_rand_ele_y_pick
--   (
--     array[array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]]
--     , 3
--   ) tb_a;
-- select * from sm_sc.ft_rand_ele_y_pick
--   (
--     array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
--     , 3
--   ) tb_a;

