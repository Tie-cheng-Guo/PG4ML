-- drop function if exists sm_sc.fv_mx_reorder_col(float[][], int[]);
create or replace function sm_sc.fv_mx_reorder_col
(
  in i_matrix       float[][],
  in i_new_order    int[]     -- etc.: (array[null,2,4,5,3]) mean old_4->new_3; old_5->new_4; old_3->new_5
)
  returns float[][]
as
$$
-- declare here
begin
  if array_length(i_new_order, 1) > array_length(i_matrix, 2)
    or
    exists 
    (
      select 
      from (select cur_old_pos_tar from unnest(i_new_order) cur_old_pos_tar where cur_old_pos_tar is not null) t1
      full join (select cur_new_pos_tar from generate_series(1, array_length(i_new_order, 1)) cur_new_pos_tar where i_new_order[cur_new_pos_tar] is not null) t2
      on t1.cur_old_pos_tar = t2.cur_new_pos_tar
      where i_new_order[t2.cur_new_pos_tar] is null
        or t1.cur_old_pos_tar is null
    )
  then 
    return null;
  else
    return
    (
      select 
        array_agg(array_new_x order by new_y_ord)
      from
      (
        select 
          v_cur_y as new_y_ord,
          array_agg(i_matrix[v_cur_y][coalesce(i_new_order[v_cur_new_x], v_cur_new_x)] order by v_cur_new_x) as array_new_x
        from generate_series(1, array_length(i_matrix, 1)) v_cur_y
          , generate_series(1, array_length(i_matrix, 2)) v_cur_new_x
        group by v_cur_y
      ) t_tmp_array_y
    )
    ;
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_reorder_col(array[[1,3,5,7],[3,4,6,8],[5,6,6,8],[7,8,8,8]], array[null,3,4,2])
-- select sm_sc.fv_mx_reorder_col(array[[1,3,5,7],[3,4,6,8],[5,6,6,8],[7,8,8,8]], array[null,3,4,2,6,5])
-- select sm_sc.fv_mx_reorder_col(array[[1,3,5,7],[3,4,6,8],[5,6,6,8],[7,8,8,8]], array[null,4,null,2])