-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_chunk(anyarray, int[2][]);
create or replace function sm_sc.fv_chunk
(
  i_arr            anyarray,
  i_chunk_range    int[2][]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_arr) > 4 
      or array_ndims(i_arr) <> array_length(i_chunk_range, 2)
    then 
      raise exception 'unsupport ndims of i_arr or slice range.';
    elsif true = any(i_chunk_range[1][ : ] <=` 0)
      or true = any(i_chunk_range[1][ : ] >` i_chunk_range[2][ : ])
      or true = any(i_chunk_range[2][ : ] >` (select array[array_agg(array_length(i_arr, a_no) order by a_no)] from generate_series(1, array_ndims(i_arr)) tb_a(a_no)))
    then
      raise exception 'unmatched slice range.';
    end if;
  end if;
  
  if array_ndims(i_arr) = 1
  then 
    return 
      i_arr
        [i_chunk_range[1][1] : i_chunk_range[2][1]]
    ;
  elsif array_ndims(i_arr) = 2
  then 
    return 
      i_arr
        [i_chunk_range[1][1] : i_chunk_range[2][1]]
        [i_chunk_range[1][2] : i_chunk_range[2][2]]
    ;
  elsif array_ndims(i_arr) = 3
  then 
    return 
      i_arr
        [i_chunk_range[1][1] : i_chunk_range[2][1]]
        [i_chunk_range[1][2] : i_chunk_range[2][2]]
        [i_chunk_range[1][3] : i_chunk_range[2][3]]
    ;
  elsif array_ndims(i_arr) = 4
  then 
    return 
      i_arr
        [i_chunk_range[1][1] : i_chunk_range[2][1]]
        [i_chunk_range[1][2] : i_chunk_range[2][2]]
        [i_chunk_range[1][3] : i_chunk_range[2][3]]
        [i_chunk_range[1][4] : i_chunk_range[2][4]]
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_chunk
--   (
--     sm_sc.fv_new_rand(array[4,3,5,6])
--   , array[[2,1,2,1],[3,3,4,4]]
--   );