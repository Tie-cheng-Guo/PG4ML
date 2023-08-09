-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt(int, int, float[], int[2], int[2], int[4]);
create or replace function sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt
(
  i_x_grp_x_x_len          int                                                  ,  -- i_x_1d_grp_x[n:n][:] 是 第 n 个 2d 降维为 1d 样本，本参数为 i_x_grp_x 的宽度
  i_1d_2_2d_cnt_per_grp    int                                                  ,  -- 升维的每维组元素个数，通常二维图像的的宽度
  i_dloss_dy_1d_grp        float[]                                     ,  -- 即已求出的损失函数对 y 的导数矩阵 的 降维后样本集合
  i_window_len             int[2]                                               ,  -- 卷积核窗口矩阵高宽
  i_stride                 int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding                int[4]              default  array[0, 0, 0, 0]          -- 上下左右补齐行数/列数
)
returns float[][]
as
$$
declare 
  v_dloss_dy_array_len_2   int :=  (i_padding[3] + i_1d_2_2d_cnt_per_grp + i_padding[4] - i_window_len[2]) / i_stride[2] + 1;
  v_array_y_len            int :=  i_x_grp_x_x_len / i_1d_2_2d_cnt_per_grp;
begin
  -- 审计二维长度
  if array_ndims(i_dloss_dy_1d_grp) <> 2
  then 
    raise exception 'no method for such length, i_dloss_dy_1d_grp!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_dloss_dy_1d_grp), array_length(i_dloss_dy_1d_grp, 1), array_length(i_dloss_dy_1d_grp, 2);
  elsif i_x_grp_x_x_len % i_1d_2_2d_cnt_per_grp <> 0
  then
    raise exception 'imperfect window at grp_x_cnt.';
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
              sm_sc.fv_d_pool_avg_dloss_dindepdt
              (
                array[v_array_y_len, i_1d_2_2d_cnt_per_grp]   , 
                sm_sc.fv_mx_ele_1d_2_2d
                (
                  i_dloss_dy_1d_grp[a_cur_y : a_cur_y][ : ]
                  , v_dloss_dy_array_len_2
                )                                             , 
                i_window_len                                  ,
                i_stride                                      ,
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
-- select sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt
--   (
--     5*7
--     , 7,
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
--    , array[3, 3]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_avg_grp_x_dloss_dindepdt
--   (
--     5*6
--     , 6,
--    array
--    [
--      array[1.1, 1.1, 1.1
--       ,1.1, 1.1, 1.1
--       ,1.1, 1.1, 1.1
--       ],
--      array[2.1, 3.1, 0.1
--       ,1.1, -1.1, -0.1
--       ,0.1, 2.1, -0.1
--       ],
--      array[0.1, -2.1, 1.1
--       ,-1.1, 3.1, 2.1
--       ,-1.1, -1.1, 0.1
--       ]
--    ]
--    , array[3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );