-- -- -- 卷积的矩阵乘法实现：
-- -- --   https://www.cnblogs.com/shine-lee/p/10775831.html
-- -- --   https://blog.csdn.net/qq_40263477/article/details/104979609
-- -- -- 卷积的 fft 实现
-- -- --   https://blog.csdn.net/qq_37527608/article/details/120922348
-- -- -- 卷积与矩阵乘法算法调优：
-- -- --  https://blog.csdn.net/lizhengx/article/details/83246833
-- -- -- 卷积求导
-- -- --  https://blog.csdn.net/wangjianyu0115/article/details/62222301
-- -- -- 带偏置的卷积
-- -- --  https://blog.csdn.net/weixin_40519315/article/details/105115657
--   
-- -- -- winograd 卷积算法
-- -- --  https://zhuanlan.zhihu.com/p/74567600
-- -- --  https://baike.baidu.com/item/%E5%A8%81%E8%AF%BA%E6%A0%BC%E6%8B%89%E5%BE%B7%E5%BF%AB%E9%80%9F%E5%82%85%E9%87%8C%E5%8F%B6%E5%8F%98%E6%8D%A2/22800076?fr=ge_ala
-- 
-- -- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_conv_2d_v_im2col_ex(float[], float[], float[], int[2], int[4], float);
-- create or replace function sm_sc.fv_conv_2d_v_im2col_ex
-- (
--   i_background         float[]                                     ,  -- 背景矩阵，可以为三维四维，背景以最高两个维度当作滑动高宽
--   i_window             float[]                                     ,  -- 卷积核窗口矩阵
--   i_window_bias        float[]    default  null                    ,  -- 卷积核的偏移量。限定与 i_window 的维数一致，且窗口高宽以外的维度长度与 i_background, i_window 一致，窗口高宽的维度长度都是1
--   i_stride             int[2]     default  array[1, 1]             ,  -- 纵向与横向步长
--   i_padding            int[4]     default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
--   i_padding_value      float      default  0.0                        -- 补齐填充元素值
-- )
-- returns float[]
-- as
-- $$
-- declare 
--   v_window_len_heigh      int    :=    array_length(i_window, array_ndims(i_window) - 1)  ;
--   v_window_len_width      int    :=    array_length(i_window, array_ndims(i_window))  ;
--   v_background_len_heigh  int    :=    array_length(i_background, array_ndims(i_background) - 1)  ;
--   v_background_len_width  int    :=    array_length(i_background, array_ndims(i_background))      ;
--   v_background_im2col     float[];
--   v_cur_heigh             int    ;
--   v_cur_width             int    ;
--   v_cur_window_heigh      int    ;
--   v_cnt_window_heigh      int    ;
--   v_cnt_window_width      int    ;
--   v_return                float[]   ;   
-- begin
--   -- 审计
--   if current_setting('pg4ml._v_is_debug_check', true) = '1'
--   then
--     -- 审计二维长度
--     if array_ndims(i_window) <> 2 
--       and array_ndims(i_window) <> array_ndims(i_background)
--     then 
--       raise exception 'no method for such i_window ndims match such i_background!';
--     elsif array_ndims(i_background) > 4
--     then 
--       raise exception 'no method for such i_background ndims!  Dims: %; len_1: %; len_2: %;', array_dims(i_background), v_background_len_heigh, v_background_len_width;
--     elsif (coalesce(i_padding[1], 0) + v_background_len_heigh + coalesce(i_padding[2], 0) - v_window_len_heigh) % i_stride[1] <> 0
--     then 
--       raise exception 'imperfect window at 1d.';
--     elsif (coalesce(i_padding[3], 0) + v_background_len_width + coalesce(i_padding[4], 0) - v_window_len_width) % i_stride[2] <> 0
--     then 
--       raise exception 'imperfect window at 2d.';
--     elsif array_ndims(i_window) = 3 and array_length(i_window, 1) <> array_length(i_background, 1)
--       or array_ndims(i_window) = 4 and (array_length(i_window, 1) <> array_length(i_background, 1) or array_length(i_window, 2) <> array_length(i_background, 2))
--     then 
--       raise exception 'unmatch length between i_window and i_background at 3d or 4d.';
--     elsif array_ndims(i_window_bias) <> array_ndims(i_window)
--       or array_length(i_window_bias, array_ndims(i_window_bias) - 1) <> 1
--       or array_length(i_window_bias, array_ndims(i_window_bias)) <> 1
--       or array_ndims(i_window_bias) = 3 and array_length(i_window, 1) <> array_length(i_window_bias, 1)
--       or array_ndims(i_window_bias) = 4 and (array_length(i_window, 1) <> array_length(i_window_bias, 1) or array_length(i_window, 2) <> array_length(i_window_bias, 2))
--     then 
--       raise exception 'unmatch ndims or length for such i_window_bias';
--     end if;
--   end if;
-- 
--   -- 准备: padding, 尺寸预算
--   if 0 <> any(i_padding)
--   then 
--     i_background := 
--       sm_sc.fv_augmented
--       (
--         i_background, 
--         array[-i_padding[1] + 1, -i_padding[3] + 1], 
--         array[v_background_len_heigh + i_padding[2], v_background_len_width + i_padding[4]], 
--         i_padding_value
--       );
--   end if;
--   
--   v_background_len_heigh :=    array_length(i_background, array_ndims(i_background) - 1)  ;
--   v_background_len_width :=    array_length(i_background, array_ndims(i_background))      ;
--     
--   v_cnt_window_heigh := (v_background_len_heigh - v_window_len_heigh + i_stride[1]) / i_stride[1];
--   v_cnt_window_width := (v_background_len_width - v_window_len_width + i_stride[2]) / i_stride[2];
-- 
--   -- 对齐维度
--   -- -- if array_ndims(i_background) - array_ndims(i_window) = 3
--   -- -- then 
--   -- --   i_window := array[[[i_window]]];
--   if array_ndims(i_background) - array_ndims(i_window) = 2
--   then 
--     i_window := array[[i_window]];
--   elsif array_ndims(i_background) - array_ndims(i_window) = 1
--   then 
--     i_window := array[i_window];
--   end if;
-- 
--   -- 对齐维度
--   -- -- if array_ndims(i_background) - array_ndims(i_window_bias) = 3
--   -- -- then 
--   -- --   i_window_bias := array[[[i_window_bias]]];
--   if array_ndims(i_background) - array_ndims(i_window_bias) = 2
--   then 
--     i_window_bias := array[[i_window_bias]];
--   elsif array_ndims(i_background) - array_ndims(i_window_bias) = 1
--   then 
--     i_window_bias := array[i_window_bias];
--   end if;
--     
--   -- 计算
--   if array_ndims(i_background) = 2
--   then 
--     -- v_return :=    
--     -- (
--     --   with 
--     --   cte_im2col as
--     --   (
--     --     select 
--     --       col_a_y,
--     --       array_agg(sm_sc.fv_mx_ele_2d_2_1d(i_background[col_a_y : col_a_y + v_window_len_heigh - 1][col_a_x : col_a_x + v_window_len_width - 1]) order by col_a_x) as a_im2col
--     --     from generate_series(1, v_background_len_heigh - v_window_len_heigh + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
--     --       , generate_series(1, v_background_len_width - v_window_len_width + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
--     --     group by col_a_y
--     --   )
--     --   select 
--     --     sm_sc.fv_mx_ele_1d_2_2d
--     --     (
--     --       sm_sc.fv_mx_ele_2d_2_1d
--     --       (
--     --         sm_sc.fa_mx_concat_y(a_im2col order by col_a_y) 
--     --         |**| (|^~| array[sm_sc.fv_mx_ele_2d_2_1d(|~~| i_window)])   -- 卷积核要翻转 180
--     --       )
--     --       ,
--     --       (v_background_len_width - v_window_len_width + i_stride[2]) / i_stride[2]
--     --     ) 
--     --   from cte_im2col
--     -- )
--     -- ;  
-- 
--     v_background_im2col := 
--       array_fill
--       (
--         null :: float
--       , array
--         [
--           v_cnt_window_heigh * v_cnt_window_width
--         , v_window_len_heigh * v_window_len_width
--         ]
--       );
--       
--     for v_cur_heigh in 1 .. v_cnt_window_heigh    -- 高方向窗口滑动个数
--     loop 
--       for v_cur_width in 1 .. v_cnt_window_width  -- 宽方向窗口滑动个数
--       loop 
--         for v_cur_window_heigh in 1 .. v_window_len_heigh                                                -- 窗口高度
--         loop 
--           v_background_im2col
--             [(v_cur_heigh - 1) * v_cnt_window_width + v_cur_width    :   (v_cur_heigh - 1) * v_cnt_window_width + v_cur_width]
--             [(v_cur_window_heigh - 1) * v_window_len_width + 1       :   v_cur_window_heigh * v_window_len_width             ]
--           := 
--           i_background
--             [(v_cur_heigh - 1) * i_stride[1] + v_cur_window_heigh    :   (v_cur_heigh - 1) * i_stride[1] + v_cur_window_heigh]
--             [(v_cur_width - 1) * i_stride[2] + 1                     :   (v_cur_width - 1) * i_stride[2] + v_window_len_width] 
--           ; 
--         end loop;
--       end loop;
--     end loop;
--     v_return :=  
--       sm_sc.fv_mx_ele_1d_2_2d
--       (
--         sm_sc.fv_mx_ele_2d_2_1d
--         (
--           v_background_im2col
--           |**| (|^~| array[sm_sc.fv_mx_ele_2d_2_1d(|~~| i_window)])   -- 卷积核要翻转 180
--         )
--         ,
--         v_cnt_window_width
--       ) 
--     ;
--   
--   elsif array_ndims(i_background) = 3
--   then 
--     v_background_im2col := 
--       array_fill
--       (
--         null :: float
--       , array
--         [
--           array_length(i_background, 1)
--         , v_cnt_window_heigh * v_cnt_window_width
--         , v_window_len_heigh * v_window_len_width
--         ]
--       );
--       
--     for v_cur_heigh in 1 .. v_cnt_window_heigh    -- 高方向窗口滑动个数
--     loop 
--       for v_cur_width in 1 .. v_cnt_window_width  -- 宽方向窗口滑动个数
--       loop 
--         for v_cur_window_heigh in 1 .. v_window_len_heigh                                                -- 窗口高度
--         loop 
--           v_background_im2col
--             [ : ]
--             [(v_cur_heigh - 1) * v_cnt_window_width + v_cur_width    :   (v_cur_heigh - 1) * v_cnt_window_width + v_cur_width]
--             [(v_cur_window_heigh - 1) * v_window_len_width + 1       :   v_cur_window_heigh * v_window_len_width             ]
--           := 
--           i_background
--             [ : ]
--             [(v_cur_heigh - 1) * i_stride[1] + v_cur_window_heigh    :   (v_cur_heigh - 1) * i_stride[1] + v_cur_window_heigh]
--             [(v_cur_width - 1) * i_stride[2] + 1                     :   (v_cur_width - 1) * i_stride[2] + v_window_len_width] 
--           ; 
--         end loop;
--       end loop;
--     end loop;
--     
--     v_return :=  
--       sm_sc.fv_mx_ele_2d_2_3d
--       (
--         sm_sc.fv_mx_ele_3d_2_2d
--         (
--           v_background_im2col
--           |**| 
--           (
--             sm_sc.fv_mx_ele_2d_2_3d
--             (
--               sm_sc.fv_mx_ele_3d_2_2d(|~~| i_window, array[2, 3], 3)   -- 卷积核要翻转 180
--             , 1
--             , 2
--             , 3
--             , false
--             )
--           )
--         , array[2, 3]
--         , 2
--         )
--       , v_cnt_window_width
--       , 2
--       , 3
--       , false
--       ) 
--     ;
--   
--   elsif array_ndims(i_background) = 4
--   then 
--     v_background_im2col := 
--       array_fill
--       (
--         null :: float
--       , array
--         [
--           array_length(i_background, 1)
--         , array_length(i_background, 2)
--         , v_cnt_window_heigh * v_cnt_window_width
--         , v_window_len_heigh * v_window_len_width
--         ]
--       );
--       
--     for v_cur_heigh in 1 .. v_cnt_window_heigh    -- 高方向窗口滑动个数
--     loop 
--       for v_cur_width in 1 .. v_cnt_window_width  -- 宽方向窗口滑动个数
--       loop 
--         for v_cur_window_heigh in 1 .. v_window_len_heigh                                                -- 窗口高度
--         loop 
--           v_background_im2col
--             [ : ]
--             [ : ]
--             [(v_cur_heigh - 1) * v_cnt_window_width + v_cur_width    :   (v_cur_heigh - 1) * v_cnt_window_width + v_cur_width]
--             [(v_cur_window_heigh - 1) * v_window_len_width + 1       :   v_cur_window_heigh * v_window_len_width             ]
--           := 
--           i_background
--             [ : ]
--             [ : ]
--             [(v_cur_heigh - 1) * i_stride[1] + v_cur_window_heigh    :   (v_cur_heigh - 1) * i_stride[1] + v_cur_window_heigh]
--             [(v_cur_width - 1) * i_stride[2] + 1                     :   (v_cur_width - 1) * i_stride[2] + v_window_len_width] 
--           ; 
--         end loop;
--       end loop;
--     end loop;
--   
--     v_return :=  
--       sm_sc.fv_mx_ele_3d_2_4d
--       (
--         sm_sc.fv_mx_ele_4d_2_3d
--         (
--           v_background_im2col
--           |**|
--           (
--             sm_sc.fv_mx_ele_3d_2_4d
--             (
--               sm_sc.fv_mx_ele_4d_2_3d(|~~| i_window, array[3, 4], 4)   -- 卷积核要翻转 180
--             , 1
--             , 3
--             , 4
--             , false
--             )
--           )
--         , array[3, 4]
--         , 4
--         )
--       , v_cnt_window_width
--       , 3
--       , 4
--       , false
--       ) 
--     ;
--   
--   end if;
-- 
--   if i_window_bias is not null
--   then 
--     return v_return +` i_window_bias;
--   else 
--     return v_return;
--   end if;
-- end
-- $$
-- language plpgsql stable
-- parallel safe
-- cost 100;
-- -- -- set search_path to sm_sc;
-- -- select sm_sc.fv_conv_2d_v_im2col_ex
-- --   (
-- --     array[[1.0,2.0,3.0,4.0,5.0,6.0,7.0]
-- --         , [10.0,20.0,30.0,40.0,50.0,60.0,70.0]
-- --         , [100.0,200.0,300.0,400.0,500.0,600.0,700.0]
-- --         , [-1.0,-2.0,-3.0,-4.0,-5.0,-6.0,-7.0]
-- --         , [-10.0,-20.0,-30.0,-40.0,-50.0,-60.0,-70.0]
-- --          ] :: float[]
-- --    , array[[0, 1, 0], [1, 1, 1], [0, 1, 0]]
-- --    , array[[0.5]]
-- --    , array[2, 2]
-- --   ) :: decimal[] ~=` 3;
-- 
-- -- select sm_sc.fv_conv_2d_v_im2col_ex
-- --   (
-- --     array[[1,2,3,4,5,6]
-- --         , [10,20,30,40,50,60]
-- --         , [100,200,300,400,500,600]
-- --         , [-1,-2,-3,-4,-5,-6]
-- --         , [-10,-20,-30,-40,-50,-60]
-- --          ]
-- --    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
-- --    , null
-- --    , array[2, 2]
-- --    , array[1, 1, 1, 0]
-- --    , 0
-- --   ) :: decimal[] ~=` 3;
-- 
-- -- select sm_sc.fv_conv_2d_v_im2col_ex
-- --   (
-- --     array[[1,2,3,4,5,6]
-- --         , [10,20,30,40,50,60]
-- --         , [100,200,300,400,500,600]
-- --         , [-1,-2,-3,-4,-5,-6]
-- --         , [-10,-20,-30,-40,-50,-60]
-- --          ]
-- --    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
-- --    , array[[0.0]]
-- --    , array[2, 2]
-- --    , array[1, 1, 1, 0]
-- --    , 0.0
-- --   ) :: decimal[] ~=` 3;
-- 
-- -- select sm_sc.fv_conv_2d_v_im2col_ex
-- --   (
-- --     array
-- --     [
-- --      [[1,2,3,4,5,6]
-- --      ,[10,20,30,40,50,60]
-- --      ,[100,200,300,400,500,600]
-- --      ,[-1,-2,-3,-4,-5,-6]
-- --      ,[-10,-20,-30,-40,-50,-60]
-- --      ]
-- --     ,[[1,2,3,4,5,6]
-- --      ,[100,200,300,400,500,600]
-- --      ,[10,20,30,40,50,60]
-- --      ,[-10,-20,-30,-40,-50,-60]
-- --      ,[-1,-2,-3,-4,-5,-6]
-- --      ]
-- --     ]
-- --    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
-- --    , array[[0.5]]
-- --    , array[2, 2]
-- --    , array[1, 1, 1, 0]
-- --    , 0.0
-- --   ) :: decimal[] ~=` 3;
-- 
-- -- select sm_sc.fv_conv_2d_v_im2col_ex
-- --   (
-- --     array
-- --     [
-- --      [
-- --       [[1,2,3,4,5,6]
-- --       ,[10,20,30,40,50,60]
-- --       ,[100,200,300,400,500,600]
-- --       ,[-1,-2,-3,-4,-5,-6]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ]
-- --      ,[[1,2,3,4,5,6]
-- --       ,[100,200,300,400,500,600]
-- --       ,[10,20,30,40,50,60]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ,[-1,-2,-3,-4,-5,-6]
-- --       ]
-- --      ],
-- --      [
-- --       [[10,20,30,40,50,60]
-- --       ,[1,2,3,4,5,6]
-- --       ,[-1,-2,-3,-4,-5,-6]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ,[100,200,300,400,500,600]
-- --       ]
-- --      ,[[-1,-2,-3,-4,-5,-6]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ,[10,20,30,40,50,60]
-- --       ,[100,200,300,400,500,600]
-- --       ,[1,2,3,4,5,6]
-- --       ]
-- --      ]
-- --     ]
-- --    , array[[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
-- --    , array[[0.5]]
-- --    , array[2, 2]
-- --    , array[1, 1, 1, 0]
-- --    , 0.0
-- --   ) :: decimal[] ~=` 3;
-- 
-- -- select sm_sc.fv_conv_2d_v_im2col_ex
-- --   (
-- --     array
-- --     [
-- --      [
-- --       [[1,2,3,4,5,6]
-- --       ,[10,20,30,40,50,60]
-- --       ,[100,200,300,400,500,600]
-- --       ,[-1,-2,-3,-4,-5,-6]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ]
-- --      ,[[1,2,3,4,5,6]
-- --       ,[100,200,300,400,500,600]
-- --       ,[10,20,30,40,50,60]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ,[-1,-2,-3,-4,-5,-6]
-- --       ]
-- --      ],
-- --      [
-- --       [[10,20,30,40,50,60]
-- --       ,[1,2,3,4,5,6]
-- --       ,[-1,-2,-3,-4,-5,-6]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ,[100,200,300,400,500,600]
-- --       ]
-- --      ,[[-1,-2,-3,-4,-5,-6]
-- --       ,[-10,-20,-30,-40,-50,-60]
-- --       ,[10,20,30,40,50,60]
-- --       ,[100,200,300,400,500,600]
-- --       ,[1,2,3,4,5,6]
-- --       ]
-- --      ]
-- --     ]
-- --    , array
-- --     [
-- --      [
-- --       [[1.1, 1.1, 1.1], [1.1, 2.1, 1.1], [1.1, 1.1, 1.1]]
-- --      ,[[1.1, 1.1, 1.1], [1.1, 3.1, 1.1], [1.1, 1.1, 1.1]]
-- --      ],
-- --      [
-- --       [[1.1, 1.1, 1.1], [1.1, 2.5, 1.1], [1.1, 1.1, 1.1]]
-- --      ,[[1.1, 1.1, 1.1], [1.1, 0.1, 1.1], [1.1, 1.1, 1.1]]
-- --      ]
-- --     ]
-- --    , array[[[[0.5]],[[1.0]]],[[[-1.0]],[[0.9]]]]
-- --    , array[2, 2]
-- --    , array[1, 1, 1, 0]
-- --    , 0.0
-- --   ) :: decimal[] ~=` 3;