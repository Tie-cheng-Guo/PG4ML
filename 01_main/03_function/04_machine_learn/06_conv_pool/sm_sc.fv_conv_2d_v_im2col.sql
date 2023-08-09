-- -- 卷积的矩阵乘法实现：
-- --   https://www.cnblogs.com/shine-lee/p/10775831.html
-- --   https://blog.csdn.net/qq_40263477/article/details/104979609
-- -- 卷积的 fft 实现
-- --   https://blog.csdn.net/qq_37527608/article/details/120922348
-- -- 卷积与矩阵乘法算法调优：
-- --  https://blog.csdn.net/lizhengx/article/details/83246833
-- -- 卷积求导
-- --  https://blog.csdn.net/wangjianyu0115/article/details/62222301
-- -- 带偏置的卷积
-- --  https://blog.csdn.net/weixin_40519315/article/details/105115657

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_conv_2d_v_im2col(float[], float[], float, int[2], int[4], float);
create or replace function sm_sc.fv_conv_2d_v_im2col
(
  i_background              float[]                                     ,
  i_window             float[]                                     ,  -- 卷积核窗口矩阵
  i_window_bias        float      default  null                    ,  -- 卷积核的偏移量
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      float      default  0.0                        -- 补齐填充元素值
)
returns float[][]
as
$$
declare 
  v_window_len_y    int   :=    array_length(i_window, 1)  ;
  v_window_len_x    int   :=    array_length(i_window, 2)  ;
  v_return          float[]   ;   
begin
  -- 审计二维长度
  if array_ndims(i_background) <> 2
  then 
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_background), array_length(i_background, 1), array_length(i_background, 2);
  elsif (coalesce(i_padding[1], 0) + array_length(i_background, 1) + coalesce(i_padding[2], 0) - v_window_len_y) % i_stride[1] <> 0
  then 
    raise exception 'imperfect window at 1d.';
  elsif (coalesce(i_padding[3], 0) + array_length(i_background, 2) + coalesce(i_padding[4], 0) - v_window_len_x) % i_stride[2] <> 0
  then 
    raise exception 'imperfect window at 2d.';
  else
    i_background := 
      sm_sc.fv_augmented
      (
        i_background, 
        array[-i_padding[1] + 1, -i_padding[3] + 1], 
        array[array_length(i_background, 1) + i_padding[2], array_length(i_background, 2) + i_padding[4]], 
        i_padding_value
      );
    
    v_return :=    
    (
      -- -- https://blog.csdn.net/qq_40263477/article/details/104979609
      -- -- https://www.cnblogs.com/shine-lee/p/10775831.html
      with 
      cte_im2col as
      (
        select 
          col_a_y,
          array_agg(sm_sc.fv_mx_ele_2d_2_1d(i_background[col_a_y : col_a_y + v_window_len_y - 1][col_a_x : col_a_x + v_window_len_x - 1]) order by col_a_x) as a_im2col
        from generate_series(1, array_length(i_background, 1) - v_window_len_y + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
          , generate_series(1, array_length(i_background, 2) - v_window_len_x + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
        group by col_a_y
      )
      select 
        sm_sc.fv_mx_ele_1d_2_2d
        (
          sm_sc.fv_mx_ele_2d_2_1d
          (
            sm_sc.fa_mx_concat_y(a_im2col order by col_a_y) 
            |**| (|^~| array[sm_sc.fv_mx_ele_2d_2_1d(|~~| i_window)])   -- 卷积核要翻转 180
          )
          ,
          (array_length(i_background, 2) - v_window_len_x + i_stride[2]) / i_stride[2]
        ) 
      from cte_im2col
    )
    ;
    
    if i_window_bias <> 0.0 -- -- and i_window_bias is not null
    then 
      v_return := v_return +` i_window_bias;
    end if;
    
    return v_return;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_conv_2d_v_im2col
--   (
--     array[array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[-1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , array[-10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0]
--          ]
--    , array[array[0, 1, 0], array[1, 1, 1], array[0, 1, 0]]
--    , 0.5
--    , array[2, 2]
--   );

-- select sm_sc.fv_conv_2d_v_im2col
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--          ]
--    , array[array[1.1, 1.1, 1.1], array[1.1, 2.1, 1.1], array[1.1, 1.1, 1.1]]
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );

-- select sm_sc.fv_conv_2d_v_im2col
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--          ]
--    , array[array[1.1, 1.1, 1.1], array[1.1, 2.1, 1.1], array[1.1, 1.1, 1.1]]
--    , 0.0
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0.0
--   );