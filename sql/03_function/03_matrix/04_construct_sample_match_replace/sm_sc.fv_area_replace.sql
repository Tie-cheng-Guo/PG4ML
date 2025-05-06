-- 2d area_replace
-- drop function if exists sm_sc.fv_area_replace(anyarray, int[], anyarray);
create or replace function sm_sc.fv_area_replace
(
  i_array          anyarray,
  i_area_pos       int[],
  i_sub_tar_array  anyarray
)
returns anyarray
as
$$
-- declare -- here
begin
  -- 审查
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array) > 4 
      or array_ndims(i_sub_tar_array) > 4 
      or array_ndims(i_area_pos) <> 1
      or array_ndims(i_sub_tar_array) <> array_length(i_area_pos, 1)
    then
      raise exception 'unsupport ndims!';
    elsif array_length(i_sub_tar_array, 1) > array_length(i_array, 1) - i_area_pos[1] + 1
      or array_length(i_sub_tar_array, 2) > array_length(i_array, 2) - i_area_pos[2] + 1
      or array_length(i_sub_tar_array, 3) > array_length(i_array, 3) - i_area_pos[3] + 1
      or array_length(i_sub_tar_array, 4) > array_length(i_array, 4) - i_area_pos[4] + 1
    then 
      raise exception 'length of i_sub_tar_array overflow beyond i_array.';
    end if;
  end if;

  if array_ndims(i_array) = 1
  then 
    i_array[i_area_pos[1] : i_area_pos[1] + array_length(i_sub_tar_array, 1) - 1]
      := i_sub_tar_array;
  elsif array_ndims(i_array) = 2
  then
    i_array[i_area_pos[1] : i_area_pos[1] + array_length(i_sub_tar_array, 1) - 1]
           [i_area_pos[2] : i_area_pos[2] + array_length(i_sub_tar_array, 2) - 1]
      := i_sub_tar_array;
  elsif array_ndims(i_array) = 3
  then
    i_array[i_area_pos[1] : i_area_pos[1] + array_length(i_sub_tar_array, 1) - 1]
           [i_area_pos[2] : i_area_pos[2] + array_length(i_sub_tar_array, 2) - 1]
           [i_area_pos[3] : i_area_pos[3] + array_length(i_sub_tar_array, 3) - 1]
      := i_sub_tar_array;
  elsif array_ndims(i_array) = 4
  then
    i_array[i_area_pos[1] : i_area_pos[1] + array_length(i_sub_tar_array, 1) - 1]
           [i_area_pos[2] : i_area_pos[2] + array_length(i_sub_tar_array, 2) - 1]
           [i_area_pos[3] : i_area_pos[3] + array_length(i_sub_tar_array, 3) - 1]
           [i_area_pos[4] : i_area_pos[4] + array_length(i_sub_tar_array, 4) - 1]
      := i_sub_tar_array;
  end if;
  
  return i_array;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_area_replace(array[['a', 'b', 'c'], ['e', 'f', 'g'], ['h', 'i', 'j'], ['x', 'y', 'z']], array[3, 2], array[['m', 'n'], ['p', 'q']])
-- select sm_sc.fv_area_replace
--   (
--     array[[[[1, 2, 3, 4, 5, 6],[-1, -2, -3, -4, -5, -6]],[[1, 2, 3, 4, 5, 6],[-1, -2, -3, -4, -5, -6]],[[1, 2, 3, 4, 5, 6],[-1, -2, -3, -4, -5, -6]]]]
--   , array[1 ,1, 1, 1]
--   , array[[[[7, 8],[9, 0]],[[7, 8],[9, 0]],[[7, 8],[9, 0]]]]
--   )
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
-- declare -- here
begin
  return sm_sc.fv_area_replace(i_array, array[i_area_pos_1d], i_sub_tar_array);
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_area_replace(array['a', 'b', 'c', 'e', 'f', 'g', 'h', 'i', 'j', 'x', 'y', 'z'], 6, array['m', 'n', 'p', 'q'])