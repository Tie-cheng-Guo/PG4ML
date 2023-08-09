-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_turn_right(anyarray);
create or replace function sm_sc.fv_opr_turn_right
(
  i_right     anyarray
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
    
  if array_ndims(i_right) is null
  then 
    return i_right;
  elsif array_ndims(i_right) = 2
  then
    return 	
    (
      select
        array_agg(array_x_new order by a_cur_x)
      from 
      (
        select 
          a_cur_x,
          array_agg(i_right[a_cur_y][a_cur_x] order by a_cur_y desc) as array_x_new
        from generate_series(1, array_length(i_right, 1)) tb_a_cur_y(a_cur_y)
          , generate_series(1, array_length(i_right, 2)) tb_a_cur_x(a_cur_x)
        group by a_cur_x
      ) t_array_x_new
    )
    ;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_turn_right
--   (
--     array[array[1, 2], array[3, 4]]
--   );
-- select sm_sc.fv_opr_turn_right
--   (
--     array[array[1, 2], array[3, 4], array[5, 6]]
--   );