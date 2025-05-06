-- drop function if exists sm_sc.fv_idx_mx_max(anyarray);
create or replace function sm_sc.fv_idx_mx_max
(
  i_arr           anyarray
)
  returns int[2]
as
$$
declare
  v_cur_max_pos      int[2];
  v_cur_y            int;
  v_cur_x            int;
  v_len_y            int    :=   array_length(i_arr, 1);
  v_len_x            int    :=   array_length(i_arr, 2);
begin
  if array_ndims(i_arr) = 2
  then
    if array_length(i_arr, 1) > 0 and array_length(i_arr, 2) > 0
    then
      v_cur_max_pos := array[1, 1];
    end if;

    v_cur_y := 1;
    while v_cur_y <= v_len_y
    loop 
      v_cur_x := 1;
      while v_cur_x <= v_len_x
      loop 
        if i_arr[v_cur_y][v_cur_x] > i_arr[1][1]
        then
          i_arr[1][1] := i_arr[v_cur_y][v_cur_x];
          v_cur_max_pos := array[v_cur_y, v_cur_x];
        end if;
        v_cur_x := v_cur_x + 1;
      end loop;
      v_cur_y := v_cur_y + 1;
    end loop;
  else
    raise exception 'unsupport n-dims';
  end if;

  return v_cur_max_pos;
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_idx_mx_max(array[array[1.2, 2.3, 5.6, 52.1]])
-- select sm_sc.fv_idx_mx_max(array[array[1.2], array[2.3], array[5.6], array[52.1]])
