-- drop function if exists sm_sc.fv_lmask(anyarray, int[], anyelement);
create or replace function sm_sc.fv_lmask
(
  i_array               anyarray    ,
  i_mask_len            int[]       ,     -- 该控制参数的维度与 i_array 相同，背景面的 width 维度(最高维度)长度为 1，其他维度长度与 i_array 对应维度长度也相同。
  i_mask_element        anyelement
)
returns anyarray
as
$$
declare
  v_pos_range_s         int4range[] ;
  v_background_width    int         := array_length(i_array, array_ndims(i_array));
begin
  -- 审计维度数量
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array) not between 2 and 4 
    then 
      raise exception 'unsupport ndims of i_array';
    elsif array_ndims(i_mask_len) <> array_ndims(i_array)
    then 
      raise exception 'array_ndims of i_mask_len should be the same as i_array''s.';
    elsif array_length(i_mask_len, array_ndims(i_mask_len)) <> 1 
    then 
      raise exception 'width of i_mask_len'' background should be 1.';
    elsif array_ndims(i_mask_len) = 2 
        and array_length(i_mask_len, 1) <> array_length(i_array, 1)
      or array_ndims(i_mask_len) = 3 
        and (array_length(i_mask_len, 1) <> array_length(i_array, 1) 
               or array_length(i_mask_len, 2) <> array_length(i_array, 2)
            )
      or array_ndims(i_mask_len) = 4 
        and (array_length(i_mask_len, 1) <> array_length(i_array, 1) 
               or array_length(i_mask_len, 2) <> array_length(i_array, 2) 
               or array_length(i_mask_len, 3) <> array_length(i_array, 3)
            )
    then 
      raise exception 'unmatched length between i_mask_len and i_array';
    elsif v_background_width < any(i_mask_len)
    then
      raise exception 'there should not be any element of i_mask_len > v_background_width.';
    end if;
  end if;
  
  if array_ndims(i_mask_len) = 2
  then 
    v_pos_range_s := 
    (
      select 
        array_agg
        (
          array 
          [
            int4range(a_cur_y, a_cur_y, '[]')
          , nullif(int4range(1, i_mask_len[a_cur_y][1] + 1, '[)'), 'empty' :: int4range)
          ]
        )
      from generate_series(1, array_length(i_mask_len, 1)) tb_a_cur_y(a_cur_y)
    );
    
  elsif array_ndims(i_mask_len) = 3
  then 
    v_pos_range_s := 
    (
      select 
        array_agg
        (
          array 
          [
            int4range(a_cur_y, a_cur_y, '[]')
          , int4range(a_cur_x, a_cur_x, '[]')
          , nullif(int4range(1, i_mask_len[a_cur_y][a_cur_x][1] + 1, '[)'), 'empty' :: int4range)
          ]
        )
      from generate_series(1, array_length(i_mask_len, 1)) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_mask_len, 2)) tb_a_cur_x(a_cur_x)
    );
    
  elsif array_ndims(i_mask_len) = 4 
  then 
    v_pos_range_s := 
    (
      select 
        array_agg
        (
          array 
          [
            int4range(a_cur_y, a_cur_y, '[]')
          , int4range(a_cur_x, a_cur_x, '[]')
          , int4range(a_cur_x3, a_cur_x3, '[]')
          , nullif(int4range(1, i_mask_len[a_cur_y][a_cur_x][a_cur_x3][1] + 1, '[)'), 'empty' :: int4range)
          ]
        )
      from generate_series(1, array_length(i_mask_len, 1)) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_mask_len, 2)) tb_a_cur_x(a_cur_x)
        , generate_series(1, array_length(i_mask_len, 3)) tb_a_cur_x3(a_cur_x3)
    );
      
  end if;
  
  return 
    sm_sc.fv_pos_replaces
    (
      i_array
    , v_pos_range_s
    , i_mask_element
    )
  ;
  
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_lmask
--   (
--     array
--     [
--       [1, 2, 3, 4, 5]
--     , [2, 3, 4, 5, 6]
--     , [3, 4, 5, 6, 7]
--     , [4, 5, 6, 7, 8]
--     ]
--   , array[[3], [0], [2], [1]]
--   , 0
--   )

-- select 
--   sm_sc.fv_lmask
--   (
--     array
--     [
--       [
--         [1, 2, 3, 4, 5]
--       , [2, 3, 4, 5, 6]
--       , [3, 4, 5, 6, 7]
--       , [4, 5, 6, 7, 8]
--       ]
--     , [
--         [-1, -2, -3, -4, -5]
--       , [-2, -3, -4, -5, -6]
--       , [-3, -4, -5, -6, -7]
--       , [-4, -5, -6, -7, -8]
--       ]
--     , [
--         [11, 12, 13, 14, 15]
--       , [12, 13, 14, 15, 16]
--       , [13, 14, 15, 16, 17]
--       , [14, 15, 16, 17, 18]
--       ]
--     ]
--   , array[[[3], [0], [2], [1]], [[1], [1], [4], [2]], [[3], [5], [2], [1]]]
--   , 0
--   )

-- select 
--   sm_sc.fv_lmask
--   (
--     array
--     [
--       [
--         [
--           [1, 2, 3, 4, 5]
--         , [2, 3, 4, 5, 6]
--         , [3, 4, 5, 6, 7]
--         , [4, 5, 6, 7, 8]
--         ]
--       , [
--           [-1, -2, -3, -4, -5]
--         , [-2, -3, -4, -5, -6]
--         , [-3, -4, -5, -6, -7]
--         , [-4, -5, -6, -7, -8]
--         ]
--       , [
--           [11, 12, 13, 14, 15]
--         , [12, 13, 14, 15, 16]
--         , [13, 14, 15, 16, 17]
--         , [14, 15, 16, 17, 18]
--         ]
--       ]
--     , [
--         [
--           [1, 2, 3, 4, 5]
--         , [2, 3, 4, 5, 6]
--         , [3, 4, 5, 6, 7]
--         , [4, 5, 6, 7, 8]
--         ]
--       , [
--           [-1, -2, -3, -4, -5]
--         , [-2, -3, -4, -5, -6]
--         , [-3, -4, -5, -6, -7]
--         , [-4, -5, -6, -7, -8]
--         ]
--       , [
--           [11, 12, 13, 14, 15]
--         , [12, 13, 14, 15, 16]
--         , [13, 14, 15, 16, 17]
--         , [14, 15, 16, 17, 18]
--         ]
--       ]
--     ]
--   , array[[[[3], [0], [2], [1]], [[1], [1], [4], [2]], [[3], [5], [2], [1]]],[[[3], [0], [2], [1]], [[1], [1], [4], [2]], [[3], [5], [2], [1]]]]
--   , 0
--   )