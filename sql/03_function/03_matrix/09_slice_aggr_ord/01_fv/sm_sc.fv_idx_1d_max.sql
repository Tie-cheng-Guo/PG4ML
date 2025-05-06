-- drop function if exists sm_sc.fv_idx_1d_max(anyarray);
create or replace function sm_sc.fv_idx_1d_max
(
  i_arr           anyarray
)
  returns int
as
$$
declare
  v_cur_max_pos      int;
  v_cur              int    :=   1;
  v_len              int;
begin
  if array_ndims(i_arr) = 1
  then
    v_cur_max_pos := 1;
    v_len :=  array_length(i_arr, 1);
    while v_cur < v_len
    loop
      -- 从第二个遍历至最后一个
      v_cur := v_cur + 1;
    
      if i_arr[v_cur] > i_arr[1]
      then
        i_arr[1] := i_arr[v_cur];
        v_cur_max_pos := v_cur;
      end if;
    end loop;

  elsif array_ndims(i_arr) = 2 and array_length(i_arr, 1) = 1 and array_length(i_arr, 2) >= 1
  then
    v_cur_max_pos := 1;
    v_len :=  array_length(i_arr, 2);
    while v_cur < v_len
    loop
      -- 从第二个遍历至最后一个
      v_cur := v_cur + 1;
    
      if i_arr[1][v_cur] > i_arr[1][1]
      then
        i_arr[1][1] := i_arr[1][v_cur];
        v_cur_max_pos := v_cur;
      end if;
    end loop;

  elsif array_ndims(i_arr) = 2 and array_length(i_arr, 2) = 1 and array_length(i_arr, 1) >= 1
  then
    v_cur_max_pos := 1;
    v_len :=  array_length(i_arr, 1);
    while v_cur < v_len
    loop
      -- 从第二个遍历至最后一个
      v_cur := v_cur + 1;
    
      if i_arr[v_cur][1] > i_arr[1][1]
      then
        i_arr[1][1] := i_arr[v_cur][1];
        v_cur_max_pos := v_cur;
      end if;
    end loop;

  elsif array_ndims(i_arr) = 2 and array_length(i_arr, 1) >= 1 and array_length(i_arr, 2) >= 1
  then
    raise exception 'unsupport 2-dims with array_length(i_arr, 1) > 1 and array_length(i_arr, 2) > 1';
  elsif array_ndims(i_arr) > 2
  then
    raise exception 'unsupport n-dims(n > 2)';
  end if;

  return v_cur_max_pos;
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_idx_1d_max(array[1.2, 2.3, 5.6, 52.1])
-- select sm_sc.fv_idx_1d_max(array[array[1.2, 2.3, 5.6, 52.1]])
-- select sm_sc.fv_idx_1d_max(array[array[1.2], array[2.3], array[5.6], array[52.1]])
