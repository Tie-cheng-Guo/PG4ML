-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_conv_prod_mx(anyarray, anyarray, int, int[2], int[4], anyelement);
create or replace function sm_sc.fv_conv_prod_mx
(
  i_background         anyarray                                             ,
  i_window_ex          anyarray                                             ,  -- 窗口自变量，该窗口自变量高宽与背景矩阵滑动窗口高宽不一致，为矩阵相乘关系
  i_window_len_heigh   int                                                  ,  -- 滑动窗口高宽规格
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      anyelement          default  '0.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_background_len_heigh  int    :=    array_length(i_background, array_ndims(i_background) - 1)  ;
  v_background_len_width  int    :=    array_length(i_background, array_ndims(i_background))  ;
  v_window_len            int[2] :=    array[i_window_len_heigh, array_length(i_window_ex, array_ndims(i_window_ex) - 1)];
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计二维长度
    if array_ndims(i_background) not between 2 and 4
    then 
      raise exception 'no method for such i_background length!  Dims: %; len_1: %; len_2: %;', array_dims(i_background), v_background_len_heigh, v_background_len_width;
    elsif array_ndims(i_window_ex) <> 2 and array_ndims(i_window_ex) <> array_ndims(i_background)
    then 
      raise exception 'no method for such i_window_ex length!  Dims: %; len_1: %; len_2: %;', array_dims(i_window_ex), v_window_len[1], v_window_len[2];
    elsif (coalesce(i_padding[1], 0) + v_background_len_heigh + coalesce(i_padding[2], 0) - v_window_len[1]) % i_stride[1] <> 0
    then 
      raise exception 'imperfect window at 1d.';
    elsif (coalesce(i_padding[3], 0) + v_background_len_width + coalesce(i_padding[4], 0) - v_window_len[2]) % i_stride[2] <> 0
    then 
      raise exception 'imperfect window at 2d.';
    -- elsif v_window_len[2] <> array_length(i_window_ex, 1)
    -- then 
    --   raise exception 'imperfect window at 2d and window_x at 1d.';
    elsif array_ndims(i_window_ex) = 3 and array_length(i_window_ex, 1) <> array_length(i_background, 1)
      or array_ndims(i_window_ex) = 4 and (array_length(i_window_ex, 1) <> array_length(i_background, 1) or array_length(i_window_ex, 2) <> array_length(i_background, 2))
    then 
      raise exception 'unmatch length between i_window_ex and i_background at 3d or 4d.';
    end if;
  end if;
  
  i_background := 
    sm_sc.fv_augmented
    (
      i_background, 
      array[-i_padding[1] + 1, -i_padding[3] + 1], 
      array[v_background_len_heigh + i_padding[2], v_background_len_width + i_padding[4]], 
      i_padding_value
    );
    
  if array_ndims(i_background) = 2
  then 
    return 
    (
      with 
      cte_ret_y as
      (
        select 
          col_a_y,
          sm_sc.fa_mx_concat_x(i_background[col_a_y : col_a_y + v_window_len[1] - 1][col_a_x : col_a_x + v_window_len[2] - 1] |**| i_window_ex order by col_a_x) as a_ret_y
        from generate_series(1, v_background_len_heigh - v_window_len[1] + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
          , generate_series(1, v_background_len_width - v_window_len[2] + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
        group by col_a_y
      )
      select sm_sc.fa_mx_concat_y(a_ret_y order by col_a_y) from cte_ret_y
    );
  elsif array_ndims(i_background) = 3
  then 
    return 
    (
      with 
      cte_ret_x as
      (
        select 
          col_a_x,
          sm_sc.fa_mx_concat_x3
          (
            i_background[ : ][col_a_x : col_a_x + v_window_len[1] - 1][col_a_x3 : col_a_x3 + v_window_len[2] - 1] 
            |**| case 
                   when array_ndims(i_window_ex) = 2 
                     then 
                       sm_sc.fv_new
                       (
                         array[i_window_ex]
                       , array[array_length(i_background, 1), 1, 1]
                       ) 
                   else i_window_ex
                 end
            order by col_a_x3
          ) as a_ret_x
        from generate_series(1, v_background_len_heigh - v_window_len[1] + i_stride[1], i_stride[1]) tb_a_x(col_a_x)
          , generate_series(1, v_background_len_width - v_window_len[2] + i_stride[2], i_stride[2]) tb_a_x3(col_a_x3)
        group by col_a_x
      )
      select sm_sc.fa_mx_concat_x(a_ret_x order by col_a_x) from cte_ret_x
    );
  elsif array_ndims(i_background) = 4
  then 
    return 
    (
      with 
      cte_ret_x as
      (
        select 
          col_a_x3,
          sm_sc.fa_mx_concat_x4
          (
            i_background[ : ][ : ][col_a_x3 : col_a_x3 + v_window_len[1] - 1][col_a_x4 : col_a_x4 + v_window_len[2] - 1] 
            |**| case 
                   when array_ndims(i_window_ex) = 2 
                     then 
                       sm_sc.fv_new
                       (
                         array[array[i_window_ex]]
                       , array[array_length(i_background, 1), array_length(i_background, 2), 1, 1]
                       ) 
                   else i_window_ex
                 end
            order by col_a_x4
          ) as a_ret_x2
        from generate_series(1, v_background_len_heigh - v_window_len[1] + i_stride[1], i_stride[1]) tb_a_x3(col_a_x3)
          , generate_series(1, v_background_len_width - v_window_len[2] + i_stride[2], i_stride[2]) tb_a_x4(col_a_x4)
        group by col_a_x3
      )
      select sm_sc.fa_mx_concat_x3(a_ret_x2 order by col_a_x3) from cte_ret_x
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_conv_prod_mx
--   (
--     array
--         [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--   , array[[1.0, 2.0, -3.0], [-1.0, -3.0, 2.0]]
--   , 2
--   );

-- select sm_sc.fv_conv_prod_mx
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
--           [1.0,2.0,-3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,-70.0]
--         , [100.0,200.0,300.0,-400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,3.0,-4.0,-5.0,-6.0,-7.0]
--         , [10.0,-20.0,-30.0,-40.0,-50.0,-60.0,70.0]
--         ]
--       ]
--   , array[[1.0, 2.0, -3.0], [-1.0, -3.0, 2.0]]
--   , 2
--   );

-- select sm_sc.fv_conv_prod_mx
--   (
--     array
--     [
--       [
--         [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       , [
--           [1.0,2.0,3.0,4.0,5.0,6.0,-7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [-100.0,200.0,300.0,400.0,-500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,5.0,-6.0,-7.0]
--         , [-10.0,-20.0,30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       ]
--     , [
--         [
--           [1.0,-2.0,3.0,-4.0,-5.0,6.0,7.0]
--         , [-10.0,20.0,30.0,40.0,-50.0,60.0,-70.0]
--         , [100.0,200.0,-300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,3.0,-4.0,5.0,-6.0,-7.0]
--         , [-10.0,20.0,-30.0,40.0,-50.0,-60.0,70.0]
--         ]
--       , [
--           [1.0,2.0,-3.0,4.0,5.0,6.0,-7.0]
--         , [-10.0,20.0,30.0,40.0,50.0,60.0,-70.0]
--         , [100.0,200.0,300.0,-400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,4.0,-5.0,-6.0,-7.0]
--         , [10.0,-20.0,-30.0,40.0,50.0,60.0,70.0]
--         ]
--       ]
--     ]
--   , array[[1.0, 2.0, -3.0], [-1.0, -3.0, 2.0]]
--   , 2
--   );

-- select sm_sc.fv_conv_prod_mx
--   (
--     array
--     [
--       [
--         [
--           [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       , [
--           [1.0,2.0,3.0,4.0,5.0,6.0,-7.0]
--         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
--         , [-100.0,200.0,300.0,400.0,-500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,-4.0,5.0,-6.0,-7.0]
--         , [-10.0,-20.0,30.0,-40.0,-50.0,-60.0,-70.0]
--         ]
--       ]
--     , [
--         [
--           [1.0,-2.0,3.0,-4.0,-5.0,6.0,7.0]
--         , [-10.0,20.0,30.0,40.0,-50.0,60.0,-70.0]
--         , [100.0,200.0,-300.0,400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,3.0,-4.0,5.0,-6.0,-7.0]
--         , [-10.0,20.0,-30.0,40.0,-50.0,-60.0,70.0]
--         ]
--       , [
--           [1.0,2.0,-3.0,4.0,5.0,6.0,-7.0]
--         , [-10.0,20.0,30.0,40.0,50.0,60.0,-70.0]
--         , [100.0,200.0,300.0,-400.0,500.0,600.0,700.0]
--         , [-1.0,-2.0,-3.0,4.0,-5.0,-6.0,-7.0]
--         , [10.0,-20.0,-30.0,40.0,50.0,60.0,70.0]
--         ]
--       ]
--     ]
--  ,  array
--     [
--       [
--         [[1.5, 2.0, 3.0], [1.4, 2.0, 3.0]]
--       , [[1.5, 2.0, 3.0], [1.4, 2.0, 3.0]]
--       ]
--     , [
--         [[1.5, 2.0, 3.0], [1.4, 2.0, 3.0]]
--       , [[1.5, 2.0, 3.0], [1.4, 2.0, 3.0]]
--       ]
--     ]
--   , 2
--   );



