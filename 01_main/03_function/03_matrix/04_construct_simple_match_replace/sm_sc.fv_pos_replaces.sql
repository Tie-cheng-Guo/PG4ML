-- drop function if exists sm_sc.fv_pos_replaces(anyarray, int[], anyelement);
create or replace function sm_sc.fv_pos_replaces
(
  i_sour_arr     anyarray,
  i_pos_s        int[],
  i_tar_ele      anyelement
)
returns anyarray
as
$$
declare -- here
  v_cur_pos_1d   int;
  v_cur_pos_2d   int[2];
begin
  -- 审查
  if array_ndims(i_sour_arr) > 2 or array_ndims(i_sour_arr) <> array_ndims(i_pos_s)
  then 
    raise exception 'unsupport ndims!';
  end if;

  if array_ndims(i_pos_s) = 2 and array_length(i_pos_s, 2) <> 2
  then 
    return null; raise notice 'no method for such length!  array_length(i_pos_s, 2) should not be %.', array_length(i_pos_s, 2);
  end if;
  
  -- 1d
  if array_ndims(i_sour_arr) = 1
  then
    foreach v_cur_pos_1d in array i_pos_s
    loop
      i_sour_arr[v_cur_pos_1d] := i_tar_ele;
    end loop;
  end if;

  -- 2d
  if array_ndims(i_sour_arr) = 2
  then
    for v_cur_pos_2d in
      select 
        array[i_pos_s[a_idx][1], i_pos_s[a_idx][2]]
      from generate_series(1, array_length(i_pos_s, 1)) tb_a_idx(a_idx)
    loop
      i_sour_arr[v_cur_pos_2d[1]][v_cur_pos_2d[2]] := i_tar_ele;
    end loop;
  end if;

  return i_sour_arr;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_pos_replaces(array['a', 'b', 'c'], array[1, 3], 'd')
-- select sm_sc.fv_pos_replaces(array[['a', 'b', 'c'], ['e', 'f', 'g']], array[[1, 3], [2, 2]], 'd')