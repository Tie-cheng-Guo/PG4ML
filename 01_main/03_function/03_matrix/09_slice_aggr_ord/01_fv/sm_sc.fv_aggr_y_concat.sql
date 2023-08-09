-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_y_concat(anyarray);
create or replace function sm_sc.fv_aggr_y_concat
(
  i_array          anyarray
)
returns anyarray
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2
  then
    return 
    (
      select 
        array[array_agg(sm_sc.fv_aggr_slice_concat(i_array[ : ][col_a_x : col_a_x]) order by col_a_x)]
      from generate_series(1, array_length(i_array, 2)) tb_a_x(col_a_x)
    );
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_y_concat
--   (
--     array[array['afwe', 'bbrg', 'ccc']
--         , array['a2gg', 'b2ykjk', 'c2gfh']
--         , array['a3hj', 'b3jy', 'c3jm']
--         , array['a4 nnf', 'b4nn', 'c4t']
--         , array['a5 gse', 'b5hht d', 'c5kuk']
--         , array['a6grrg', 'b6hn', 'c6k']
--          ]
--   );
