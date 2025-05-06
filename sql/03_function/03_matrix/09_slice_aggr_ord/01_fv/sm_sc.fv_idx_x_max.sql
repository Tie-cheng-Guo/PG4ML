-- drop function if exists sm_sc.fv_idx_x_max(anyarray);
create or replace function sm_sc.fv_idx_x_max
(
  i_arr           anyarray
)
  returns int[]
as
$$
-- declare
begin
  if array_ndims(i_arr) = 2
  then
    return
    (
      select 
        array[array_agg(sm_sc.fv_idx_1d_max(i_arr[ : ][a_cur_y : a_cur_y]) order by a_cur_y)]
      from generate_series(1, array_length(i_arr, 2)) tb_a_cur_y(a_cur_y)
    );
  else
    raise exception 'unsupport array_ndims.  ';
  end if;
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_idx_x_max(array[array[1.2, 2.3, 5.6, 52.1], array[-1.2, 2.3, -5.6, 2.1]])
-- select sm_sc.fv_idx_x_max(array[array[1.2, 2.3], array[2.3, 5.6], array[1.2, 5.6], array[2.3, 52.1]])
