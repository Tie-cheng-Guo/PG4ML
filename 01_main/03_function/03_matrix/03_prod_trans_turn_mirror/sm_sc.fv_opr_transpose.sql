-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_transpose(anyarray);
create or replace function sm_sc.fv_opr_transpose
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
        array_agg(array_x_new order by a_cur_xy)
      from 
      (
        select 
          a_cur_xy,
          array_agg(i_right[a_cur_yx][a_cur_xy] order by a_cur_yx) as array_x_new
        from generate_series(1, array_length(i_right, 1)) tb_a_cur_yx(a_cur_yx)
          , generate_series(1, array_length(i_right, 2)) tb_a_cur_xy(a_cur_xy)
        group by a_cur_xy
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
-- select sm_sc.fv_opr_transpose
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]]
--   );
-- select sm_sc.fv_opr_transpose_i
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6], array[1.2, 2.3]]
--   );