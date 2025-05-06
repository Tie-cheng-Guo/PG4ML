-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_pool_prod(anyarray, int[2], int[2], int[4], anyelement);
create or replace function sm_sc.fv_pool_prod
(
  i_array              anyarray                                             ,
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      anyelement          default  '1.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_array_len_heigh        int   :=   array_length(i_array, array_ndims(i_array) - 1) ;
  v_array_len_width        int   :=   array_length(i_array, array_ndims(i_array))     ;
  v_array_len_heigh_ex     int   :=   coalesce(i_padding[1], 0) + v_array_len_heigh + coalesce(i_padding[2], 0);     --   新背景矩阵高
  v_array_len_width_ex     int   :=   coalesce(i_padding[3], 0) + v_array_len_width + coalesce(i_padding[4], 0);     --   新背景矩阵宽
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计二维长度
    if array_ndims(i_array) not in (2, 3, 4)
    then 
      raise exception 'unsupport ndims of i_array.';
    elsif (coalesce(i_padding[1], 0) + v_array_len_heigh + coalesce(i_padding[2], 0) - i_window_len[1]) % i_stride[1] <> 0
    then 
      raise exception 'imperfect window at heigh.';
    elsif (coalesce(i_padding[3], 0) + v_array_len_width + coalesce(i_padding[4], 0) - i_window_len[2]) % i_stride[2] <> 0
    then 
      raise exception 'imperfect window at width.';
    end if;
  end if;
  
  if array_ndims(i_array) = 2
  then
    i_array := 
      sm_sc.fv_augmented
      (
        i_array, 
        array[-i_padding[1] + 1, -i_padding[3] + 1], 
        array[v_array_len_heigh + i_padding[2], v_array_len_width + i_padding[4]], 
        i_padding_value
      );
    return 
    (
      with 
      cte_ret_y as
      (
        select 
          col_a_y,
          array_agg(sm_sc.fv_aggr_slice_prod(i_array[col_a_y : col_a_y + i_window_len[1] - 1][col_a_x : col_a_x + i_window_len[2] - 1]) order by col_a_x) as ret_y
        from generate_series(1, v_array_len_heigh_ex - i_window_len[1] + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
          , generate_series(1, v_array_len_width_ex - i_window_len[2] + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
        group by col_a_y
      )
      select array_agg(ret_y order by col_a_y) from cte_ret_y
    );
  
  elsif array_ndims(i_array) = 3
  then 
    return 
    (
      select 
        array_agg 
        (
          sm_sc.fv_pool_prod
          (
            sm_sc.fv_mx_slice_3d_2_2d
            (
              i_array[a_cur_y : a_cur_y]
            , 1
            )
          , i_window_len       
          , i_stride             
          , i_padding          
          , i_padding_value
          )
          order by a_cur_y
        )
      from generate_series(1, array_length(i_array, 1)) tb_a_cur_y(a_cur_y)
    );
  
  elsif array_ndims(i_array) = 4
  then 
    return 
    (
      with 
      cte_agg_x as
      (
        select 
          a_cur_y,
          array_agg 
          (
            sm_sc.fv_pool_prod
            (
              sm_sc.fv_mx_slice_4d_2_2d
              (
                i_array[a_cur_y : a_cur_y][a_cur_x : a_cur_x][ : ][ : ]
              , array[1, 2]
              , array[1, 1]
              )
            , i_window_len       
            , i_stride             
            , i_padding          
            , i_padding_value
            )
            order by a_cur_x
          ) as a_agg_x
        from generate_series(1, array_length(i_array, 1)) tb_a_cur_y(a_cur_y)
          , generate_series(1, array_length(i_array, 2)) tb_a_cur_x(a_cur_x)
        group by a_cur_y
      )
      select 
        array_agg(a_agg_x order by a_cur_y)
      from cte_agg_x
    );
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_pool_prod
--   (
--     array[[1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--          ]
--    , array[3, 3]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_pool_prod
--   (
--     array
--       [
--         [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       , [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       ]
--    , array[3, 3]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_pool_prod
--   (
--    array
--    [
--      [
--        [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      , [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      ]
--    , [
--        [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      , [
--          [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--        , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--        , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--        , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--        , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--        ]
--      ]
--    ]
--    , array[3, 3]
--    , array[2, 2]
--   ) :: decimal[] ~=` 3;


