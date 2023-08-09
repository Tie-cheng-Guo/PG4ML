-- -- -- -- 卷积的矩阵乘法实现：
-- -- -- --   https://www.cnblogs.com/shine-lee/p/10775831.html
-- -- -- --   https://blog.csdn.net/qq_40263477/article/details/104979609
-- -- 卷积的 fft 实现
-- --   https://blog.csdn.net/qq_37527608/article/details/120922348
-- -- 卷积与矩阵乘法算法调优：
-- --      -- --  https://blog.csdn.net/lizhengx/article/details/83246833
-- --      -- -- 卷积求导
-- --      -- --  https://blog.csdn.net/wangjianyu0115/article/details/62222301
-- --      
-- --      -- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_2d_dloss_dindepdt_2(float[], float[], int[2], int[2], int[4], float);
create or replace function sm_sc.fv_d_conv_2d_dloss_dindepdt_2
(
  i_array              float[]                                     ,  -- 原矩阵(卷积第一目参数)
  i_dloss_dy           float[]                                     ,  -- 即已求出的损失函数对 y 的导数矩阵
  i_window_len         int[2]                                               ,  -- 卷积核窗口矩阵高宽
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      float      default  0.0                        -- 补齐填充元素值
)
returns float[][]
as
$$
declare 
  v_y               int   :=   coalesce(i_padding[1], 0) + array_length(i_array, 1) + coalesce(i_padding[2], 0);     --   新矩阵高
  v_x               int   :=   coalesce(i_padding[3], 0) + array_length(i_array, 2) + coalesce(i_padding[4], 0);     --   新矩阵宽
begin
  -- 审计二维长度
  if array_ndims(i_array) <> 2
  then 
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  elsif (v_y - i_window_len[1]) % i_stride[1] <> 0
  then 
    raise exception 'imperfect window at 1d.';
  elsif (v_x - i_window_len[2]) % i_stride[2] <> 0
  then 
    raise exception 'imperfect window at 2d.';
  elsif array_length(i_dloss_dy, 1) <> (v_y - i_window_len[1]) / i_stride[1] + 1
    or array_length(i_dloss_dy, 2) <> (v_x - i_window_len[2]) / i_stride[2] + 1
  then
    raise exception 'unmatch length between y and dloss/dy.';
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
      |~~|
      (
        select 
          sm_sc.fa_mx_sum
          (
            i_array[col_a_y : col_a_y + i_window_len[1] - 1][col_a_x : col_a_x + i_window_len[2] - 1] 
              *` i_dloss_dy[(col_a_y - 1) / i_stride[1] + 1][(col_a_x - 1) / i_stride[2] + 1]
          )
        from generate_series(1, v_y - i_window_len[1] + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
          , generate_series(1, v_x - i_window_len[2] + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
      );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_2d_dloss_dindepdt_2
--   (
--     array[array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[-1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , array[-10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0]
--          ]
--    , array[array[1.1, 1.1, 1.1], array[1.1, 1.1, 1.1]]
--    , array[3, 3]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_conv_2d_dloss_dindepdt_2
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--          ]
--    , array[array[1.1, 1.1, 1.1], array[1.1, 2.1, 1.1], array[1.1, 1.1, 1.1]]
--    , array[3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );