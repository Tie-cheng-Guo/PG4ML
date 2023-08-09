-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_pool_ptp(anyarray, int[2], int[2], int[4], anyelement);
create or replace function sm_sc.fv_pool_ptp
(
  i_array              anyarray                                             ,
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value       anyelement          default  '0'                        -- 补齐填充元素值
)
returns float[][]
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) <> 2
  then 
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  elsif (coalesce(i_padding[1], 0) + array_length(i_array, 1) + coalesce(i_padding[2], 0) - i_window_len[1]) % i_stride[1] <> 0
  then 
    raise exception 'imperfect window at 1d.';
  elsif (coalesce(i_padding[3], 0) + array_length(i_array, 2) + coalesce(i_padding[4], 0) - i_window_len[2]) % i_stride[2] <> 0
  then 
    raise exception 'imperfect window at 2d.';
  else
    i_array := 
      sm_sc.fv_augmented
      (
        i_array, 
        array[-i_padding[1] + 1, -i_padding[3] + 1], 
        array[array_length(i_array, 1) + i_padding[2], array_length(i_array, 2) + i_padding[4]], 
        i_padding_value
      );
    return 
    (
      with 
      cte_ret_y as
      (
        select 
          col_a_y,
          array_agg(sm_sc.fv_aggr_slice_ptp(i_array[col_a_y : col_a_y + i_window_len[1] - 1][col_a_x : col_a_x + i_window_len[2] - 1]) order by col_a_x) as ret_y
        from generate_series(1, array_length(i_array, 1) - i_window_len[1] + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
          , generate_series(1, array_length(i_array, 2) - i_window_len[2] + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
        group by col_a_y
      )
      select array_agg(ret_y order by col_a_y) from cte_ret_y
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_pool_ptp
--   (
--     array[array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[-1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , array[-10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0]
--          ]
--    , array[3, 3]
--    , array[2, 2]
--   );

-- select sm_sc.fv_pool_ptp
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--          ]
--    , array[3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );