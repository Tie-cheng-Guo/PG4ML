-- drop function if exists sm_sc.fv_mx_slice_4d_2_3d(anyarray, int, int);
create or replace function sm_sc.fv_mx_slice_4d_2_3d
(
  i_array_4d        anyarray,  
  i_dim_sliced      int     ,                    -- 被切片维度
  i_slice_pos       int     default  1           -- 被切片位置序号。
)
returns anyarray
as
$$
declare
  v_ret      i_array_4d%type;
  v_len_1    int   :=   array_length(i_array_4d, 1);
  v_len_2    int   :=   array_length(i_array_4d, 2);
  v_len_3    int   :=   array_length(i_array_4d, 3);
  v_len_4    int   :=   array_length(i_array_4d, 4);
  v_cur_m    int   ;
  v_cur_n    int   ;
begin
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if i_dim_sliced not between 1 and 4
    then 
      raise exception 'i_dim_sliced is out of length.';
    elsif array_ndims(i_array_4d) <> 4
    then 
      raise exception 'ndims of i_array_4d should be 4.';
    elsif i_slice_pos not between 1 and array_length(i_array_4d, i_dim_sliced)
    then 
      raise exception 'i_slice_pos is out of length of i_array_4d.';
    end if;
  end if;

  if i_array_4d is null 
  then 
    return null;
  elsif i_dim_sliced = 1
  then
    v_ret := array_fill(nullif(i_array_4d[1][1][1][1], i_array_4d[1][1][1][1]), array[v_len_2, v_len_3, v_len_4]);
    for v_cur_m in 1 .. v_len_2
    loop 
      for v_cur_n in 1 .. v_len_2
      loop 
        v_ret[ : ][ : ][ : ] := i_array_4d[i_slice_pos : i_slice_pos][ : ][ : ][ : ];
      end loop;
    end loop;
    return v_ret ;
  elsif i_dim_sliced = 2
  then
    v_ret := array_fill(nullif(i_array_4d[1][1][1][1], i_array_4d[1][1][1][1]), array[v_len_1, v_len_3, v_len_4]);
    for v_cur_m in 1 .. v_len_1
    loop 
      for v_cur_n in 1 .. v_len_3
      loop 
        v_ret[v_cur_m : v_cur_m][v_cur_n : v_cur_n][ : ] := i_array_4d[v_cur_m : v_cur_m][i_slice_pos : i_slice_pos][v_cur_n : v_cur_n][ : ];
      end loop;
    end loop;
    return v_ret ;
  elsif i_dim_sliced = 3
  then
    v_ret := array_fill(nullif(i_array_4d[1][1][1][1], i_array_4d[1][1][1][1]), array[v_len_1, v_len_2, v_len_4]);
    for v_cur_m in 1 .. v_len_1
    loop 
      for v_cur_n in 1 .. v_len_2
      loop 
        v_ret[v_cur_m : v_cur_m][v_cur_n : v_cur_n][ : ] := i_array_4d[v_cur_m : v_cur_m][v_cur_n : v_cur_n][i_slice_pos : i_slice_pos][ : ];
      end loop;
    end loop;
    return v_ret ;
  elsif i_dim_sliced = 4
  then
    v_ret := array_fill(nullif(i_array_4d[1][1][1][1], i_array_4d[1][1][1][1]), array[v_len_1, v_len_2, v_len_3]);
    for v_cur_m in 1 .. v_len_1
    loop 
      for v_cur_n in 1 .. v_len_2
      loop 
        v_ret[v_cur_m : v_cur_m][v_cur_n : v_cur_n][ : ] := i_array_4d[v_cur_m : v_cur_m][v_cur_n : v_cur_n][ : ][i_slice_pos : i_slice_pos];
      end loop;
    end loop;
    return v_ret ;
  end if;
end;
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select 
-- sm_sc.fv_mx_slice_4d_2_3d
-- (
--   (
--     array
--     [
--       [
--         [
--           [1, 2, 3, 4, 5]     ,
--           [11, 12, 13, 14, 15],
--           [21, 22, 23, 24, 25], 
--           [31, 32, 33, 34, 35] 
--         ],
--         [
--           [41, 42, 43, 44, 45]     ,
--           [51, 52, 53, 54, 55],
--           [61, 62, 63, 64, 65], 
--           [71, 72, 73, 74, 75] 
--         ],
--         [
--           [81, 82, 83, 84, 85]     ,
--           [91, 92, 93, 94, 95],
--           [101, 102, 103, 104, 105], 
--           [111, 112, 113, 114, 115] 
--         ]
--       ],
--       [
--         [
--           [-1, -2, -3, -4, -5]     ,
--           [-11, -12, -13, -14, -15],
--           [-21, -22, -23, -24, -25], 
--           [-31, -32, -33, -34, -35] 
--         ],
--         [
--           [-41, -42, -43, -44, -45]     ,
--           [-51, -52, -53, -54, -55],
--           [-61, -62, -63, -64, -65], 
--           [-71, -72, -73, -74, -75] 
--         ],
--         [
--           [-81, -82, -83, -84, -85]     ,
--           [-91, -92, -93, -94, -95],
--           [-101, -102, -103, -104, -105], 
--           [-111, -112, -113, -114, -115] 
--         ]
--       ]
--     ]
--   )
--   , 4, 2
-- )