-- 2d area_replace
-- drop function if exists sm_sc.fv_area_replace(anyarray, int[2], anyarray);
create or replace function sm_sc.fv_area_replace
(
  i_array          anyarray,
  i_area_pos_2d    int[2],
  i_sub_tar_array  anyarray
)
returns anyarray
as
$$
declare -- here
  v_cur_y   int;
  v_cur_x   int;
begin
  -- 审查
  if array_ndims(i_array) <> 2 or array_ndims(i_sub_tar_array) <> 2 or array_ndims(i_area_pos_2d) <> 1
  then
    raise exception 'unsupport ndims!';
  end if;

  if array_length(i_area_pos_2d, 1) <> 2
  then
    return null; raise notice 'no method for such length! of i_area_pos_2d';
  end if;

  if array_length(i_sub_tar_array, 1) > array_length(i_array, 1) - i_area_pos_2d[1] + 1
    or array_length(i_sub_tar_array, 2) > array_length(i_array, 2) - i_area_pos_2d[2] + 1
  then 
    raise exception 'length of i_sub_tar_array overflow beyond i_array.';
  end if;

  -- 2d
  for v_cur_y in 
    select 
      a_idx_y
    from generate_series(1, array_length(i_sub_tar_array, 1)) tb_a_idx_y(a_idx_y)
  loop
    for v_cur_x in 
      select 
        a_idx_x
      from generate_series(1, array_length(i_sub_tar_array, 2)) tb_a_idx_x(a_idx_x)
    loop
      i_array[v_cur_y + i_area_pos_2d[1] - 1][v_cur_x + i_area_pos_2d[2] - 1] = i_sub_tar_array[v_cur_y][v_cur_x];
    end loop;
  end loop;

  return i_array;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_area_replace(array[['a', 'b', 'c'], ['e', 'f', 'g'], ['h', 'i', 'j'], ['x', 'y', 'z']], array[3, 2], array[['m', 'n'], ['p', 'q']])

-- ------------------------------
-- 1d area_replace
-- drop function if exists sm_sc.fv_area_replace(anyarray, int, anyarray);
create or replace function sm_sc.fv_area_replace
(
  i_array          anyarray,
  i_area_pos_1d    int,
  i_sub_tar_array  anyarray
)
returns anyarray
as
$$
declare -- here
  v_cur   int;
  v_cur_x   int;
begin
  -- 审查
  if array_ndims(i_array) <> 1 or array_ndims(i_sub_tar_array) <> 1
  then
    raise exception 'unsupport ndims!';
  end if;

  if array_length(i_sub_tar_array, 1) > array_length(i_array, 1) - i_area_pos_1d + 1
  then 
    raise exception 'length of i_sub_tar_array overflow beyond i_array.';
  end if;

  -- 1d
  for v_cur in 
    select 
      a_idx
    from generate_series(1, array_length(i_sub_tar_array, 1)) tb_a_idx(a_idx)
  loop
    i_array[v_cur + i_area_pos_1d - 1] = i_sub_tar_array[v_cur];
  end loop;

  return i_array;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_area_replace(array['a', 'b', 'c', 'e', 'f', 'g', 'h', 'i', 'j', 'x', 'y', 'z'], 6, array['m', 'n', 'p', 'q'])