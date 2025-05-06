-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt(float[], int, float[], int[2], float[], int[2], int[4], float);
create or replace function sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt
(
  i_indepdt_grp_x                float[]                                     ,  -- i_indepdt_grp_x_grp_x[n:n][:] 是 第 n 个 2d 降维为 1d 样本
  i_1d_2_2d_cnt_per_grp    int                                                  ,  -- 升维的每维组元素个数，通常二维图像的的宽度
  i_dloss_ddepdt_1d_grp        float[]                                     ,  -- 即已求出的损失函数对 y 的导数矩阵 的 降维后样本集合
  i_window_len             int[2]                                               ,  -- 卷积核窗口矩阵高宽
  i_depdt_1d_grp               float[]    default  null                    ,  -- 即已求出的算子结果矩阵
  i_stride                 int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding                int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value          float      default  '-inf'       -- 补齐填充元素值
)
returns float[][]
as
$$
declare 
  v_dloss_ddepdt_array_len_2   int :=  (i_padding[3] + i_1d_2_2d_cnt_per_grp + i_padding[4] - i_window_len[2]) / i_stride[2] + 1;
begin
  -- 审计二维长度
  if array_ndims(i_indepdt_grp_x) <> 2
  then 
    raise exception 'no method for such length!  Dims: %;', array_dims(i_indepdt_grp_x);
  elsif array_length(i_indepdt_grp_x, 2) % i_1d_2_2d_cnt_per_grp <> 0
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
              sm_sc.fv_d_pool_max_dloss_dindepdt
              (
                sm_sc.fv_mx_ele_1d_2_2d
                (
                  i_indepdt_grp_x[a_cur_y : a_cur_y][ : ]
                  , i_1d_2_2d_cnt_per_grp
                )                                        , 
                i_window_len                             ,
                sm_sc.fv_mx_ele_1d_2_2d
                (
                  i_dloss_ddepdt_1d_grp[a_cur_y : a_cur_y][ : ]
                  , v_dloss_ddepdt_array_len_2
                )                                        , 
                sm_sc.fv_mx_ele_1d_2_2d
                (
                  i_depdt_1d_grp[a_cur_y : a_cur_y][ : ]
                  , v_dloss_ddepdt_array_len_2
                )                                        ,
                i_stride                                 ,
                i_padding                                ,
                i_padding_value          
              )
            )
          ]
          order by a_cur_y
        )
      from generate_series(1, array_length(i_indepdt_grp_x, 1)) tb_a_cur_y(a_cur_y)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt
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
--    , null
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_max_grp_x_dloss_dindepdt
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
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );