-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1(int, float[], float[], int, int[2], int[4]);
create or replace function sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1
(
  -- -- i_array_grp_x_x_len      int                                                  ,  -- i_array_grp_x[n:n][:] 是 第 n 个 2d 降维为 1d 样本。本参数是 i_array_grp_x 的宽度
  i_1d_2_2d_cnt_per_grp    int                                                  ,  -- 升维的每维组元素个数，通常二维图像的的宽度
  i_dloss_dy_1d_grp        float[]                                     ,  -- 即已求出的损失函数对 y 的导数矩阵 的 降维后样本集合
  i_window_flat            float[1][]                                  ,  -- 卷积核窗口矩阵的扁平化
  i_window_len_x           int                                                  ,  -- 卷积核窗口的宽度
  i_stride                 int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding                int[4]              default  array[0, 0, 0, 0]          -- 上下左右补齐行数/列数
)
returns float[][]
as
$$
declare 
  v_dloss_dy_array_len_2   int              :=  (i_padding[3] + i_1d_2_2d_cnt_per_grp + i_padding[4] - i_window_len_x) / i_stride[2] + 1;
  -- -- v_array_y_len           int              :=  i_array_grp_x_x_len / i_1d_2_2d_cnt_per_grp;
  v_window                 float[] :=  sm_sc.fv_mx_ele_1d_2_2d(i_window_flat[1 : 1][ : array_length(i_window_flat, 2) - (array_length(i_window_flat, 2) % i_window_len_x)], i_window_len_x);
begin
  -- 审计二维长度
  if array_ndims(i_dloss_dy_1d_grp) <> 2
  then 
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_dloss_dy_1d_grp), array_length(i_dloss_dy_1d_grp, 1), array_length(i_dloss_dy_1d_grp, 2);
  -- -- elsif i_array_grp_x_x_len % i_1d_2_2d_cnt_per_grp <> 0
  -- -- then 
  -- --   raise exception 'imperfect window at grp_x_cnt.';
  else
    return 
    (
      select 
        sm_sc.fa_mx_concat_y
        (
          array 
          [
            sm_sc.fv_mx_ele_2d_2_1d
            (
              sm_sc.fv_d_conv_2d_dloss_dindepdt_1_ex    -- -- sm_sc.fv_d_conv_2d_dloss_dindepdt_1
              (         
                -- -- array[v_array_y_len, i_1d_2_2d_cnt_per_grp],
                sm_sc.fv_mx_ele_1d_2_2d
                (
                  i_dloss_dy_1d_grp[a_cur_y : a_cur_y][ : ]
                  , v_dloss_dy_array_len_2
                )                                        , 
                v_window                                 ,
                i_stride                                 ,
                i_padding   
              )
            )
          ]
          order by a_cur_y
        )
      from generate_series(1, array_length(i_dloss_dy_1d_grp, 1)) tb_a_cur_y(a_cur_y)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1
--   (
--     -- -- 5*7,
--     7,
--     array
--     [
--       array[1.1, 1.1, 1.1
--        ,1.1, 1.1, 1.1
--        ],
--       array[2.1, 3.1, 0.1
--        ,1.1, -1.1, -0.1
--        ],
--       array[0.1, -2.1, 1.1
--        ,-1.1, 3.1, 2.1
--        ]
--     ]
--    , array[array[0.5 :: float, 1.1, 0.5], array[1.1, 2.1, 1.1], array[0.5 :: float, 1.1, 0.5]]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_conv_2d_grp_x_dloss_dindepdt_1
--   (
--     -- -- 5*6,
--     6,
--     array
--     [
--       array[1.1, 1.1, 1.1
--        ,1.1, 1.1, 1.1
--        ,1.1, 1.1, 1.1
--        ],
--       array[2.1, 3.1, 0.1
--        ,1.1, -1.1, -0.1
--        ,-1.1, 1.1, -1.1
--        ],
--       array[0.1, -2.1, 1.1
--        ,-1.1, 3.1, 2.1
--        ,1.1, -1.1, 1.1
--        ]
--     ]
--    , array[array[0.5 :: float, 1.1, 0.5], array[1.1, 2.1, 1.1], array[0.5 :: float, 1.1, 0.5]]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );