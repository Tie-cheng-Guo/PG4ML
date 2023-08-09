-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_y_coalesce(anyarray);
create or replace function sm_sc.fv_aggr_y_coalesce
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
        array[array_agg(sm_sc.fv_aggr_slice_coalesce(i_array[ : ][col_a_x : col_a_x]) order by col_a_x)]
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
-- select sm_sc.fv_aggr_y_coalesce
--   (
--     array[array[1,2,null,4,5,6]
--         , array[null,20,30,40,null,60]
--         , array[100,null,300,400,500,null]
--         , array[-1,null,-3,null,-5,-6]
--         , array[-10,null,-30,null,null,-60]
--          ]
--   );
