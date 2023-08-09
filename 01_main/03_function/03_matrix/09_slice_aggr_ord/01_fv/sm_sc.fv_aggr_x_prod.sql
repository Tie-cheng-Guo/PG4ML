-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_x_prod(anyarray);
create or replace function sm_sc.fv_aggr_x_prod
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
        array_agg(array[sm_sc.fv_aggr_slice_prod(i_array[col_a_y : col_a_y][ : ])] order by col_a_y)
      from generate_series(1, array_length(i_array, 1)) tb_a_y(col_a_y)
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
-- select sm_sc.fv_aggr_x_prod
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--          ]::float[]
--   );
