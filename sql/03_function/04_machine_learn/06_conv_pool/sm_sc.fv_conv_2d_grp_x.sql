-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_conv_2d_grp_x(float[], int, float[], int, int[2], int[4], float);
create or replace function sm_sc.fv_conv_2d_grp_x
(
  i_array_grp_x            float[]                                     ,  -- i_array_grp_x_grp_x[n:n][:] 是 第 n 个 2d 降维为 1d 样本
  i_1d_2_2d_cnt_per_grp    int                                                  ,  -- 升维的每维组元素个数，通常二维图像的的宽度
  i_window_flat            float[1][]                                  ,  -- 卷积核窗口矩阵的扁平化
  i_window_len_x           int                                                  ,  -- 卷积核窗口的宽度
  i_stride                 int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding                int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value          float      default  0.0                        -- 补齐填充元素值
)
returns float[][]
as
$$
declare
  v_window        float[]    ;
  v_windos_bias   float      ;
begin
  -- 审计二维长度
  if array_ndims(i_array_grp_x) <> 2
  then 
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array_grp_x);
  elsif array_length(i_array_grp_x, 2) % i_1d_2_2d_cnt_per_grp <> 0
  then 
    raise exception 'imperfect window at grp_x_cnt.';
  elsif array_length(i_window_flat, 2) % i_window_len_x > 1
  then 
    raise exception 'len_x of window_flat %% window_len_x should be 0 or 1.';
  else
    if array_length(i_window_flat, 2) % i_window_len_x = 1
    then
      v_window := sm_sc.fv_mx_ele_1d_2_2d(i_window_flat[1 : 1][ : array_length(i_window_flat, 2) - (array_length(i_window_flat, 2) % i_window_len_x)], i_window_len_x);
      v_windos_bias := i_window_flat[1][array_length(i_window_flat, 2)];
    elsif array_length(i_window_flat, 2) % i_window_len_x = 0
    then 
      v_window := sm_sc.fv_mx_ele_1d_2_2d(i_window_flat, i_window_len_x);
      v_windos_bias := null;
    end if;
    
    return 
    (
      select 
        sm_sc.fa_mx_concat_y
        (
          array 
          [
            sm_sc.fv_mx_ele_2d_2_1d
            (
              sm_sc.fv_conv_2d_im2col_py
              (
                sm_sc.fv_mx_ele_1d_2_2d
                (
                  i_array_grp_x[a_cur_y : a_cur_y][ : ]
                  , i_1d_2_2d_cnt_per_grp
                )                                        , 
                v_window                                 , -- -- -- 
                nullif(array[v_windos_bias], array[null::float])    ,
                i_stride                                 ,
                i_padding                                ,
                i_padding_value
              )
            )
          ]
          order by a_cur_y
        )
      from generate_series(1, array_length(i_array_grp_x, 1)) tb_a_cur_y(a_cur_y)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_conv_2d_grp_x
--   (
--     array
--     [
--       array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0
--         , 10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0
--         , 100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0
--         , -1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0
--         , -10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0
--       ],
--       array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0
--         , -1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0
--         , 10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0
--         , 100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0
--         , -10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0
--       ],
--       array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0
--         , -1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0
--         , 10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0
--         , -10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0
--         , 100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0
--       ]
--     ]
--     , 7
--     , array[array[0, 1, 0, 1, 1, 1, 0, 1, 0]]    -- -- array[array[0, 1, 0], array[1, 1, 1], array[0, 1, 0]]
--     -- , array[array[0, 1, 0, 1, 1, 1, 0, 1, 0, 0.5]]   -- 带偏移量
--     , 3
--     , array[2, 2]
--   );

-- select sm_sc.fv_conv_2d_grp_x
--   (
--     array
--     [
--       array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0
--         , 10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0
--         , 100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0
--         , -1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0
--         , -10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0
--       ],
--       array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0
--         , -1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0
--         , 10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0
--         , 100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0
--         , -10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0
--       ],
--       array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0
--         , -1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0
--         , 10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0
--         , -10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0
--         , 100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0
--       ]
--     ]
--     , 6
--     , array[array[1.1, 1.1, 1.1, 1.1, 2.1, 1.1, 1.1, 1.1, 1.1]]     -- -- array[array[1.1, 1.1, 1.1], array[1.1, 2.1, 1.1], array[1.1, 1.1, 1.1]]
--     -- , array[array[1.1, 1.1, 1.1, 1.1, 2.1, 1.1, 1.1, 1.1, 1.1, 0.5]]          -- 带偏移量
--     , 3
--     , array[2, 2]
--     , array[1, 1, 1, 0]
--     , 0
--   );