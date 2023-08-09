-- -- 参考：https://blog.csdn.net/LoseInVain/article/details/98451913

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_max_dloss_dindepdt(float[][], float[][], int[2], float[][], int[2], int[4], float);
create or replace function sm_sc.fv_d_pool_max_dloss_dindepdt
(
  i_x                  float[][]                                   ,  -- 原矩阵
  i_dloss_dy           float[][]                                   ,  -- 即已求出的损失函数对 y 的导数矩阵
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_y                  float[][]  default  null                    ,  -- 即已求出的算子结果矩阵
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      float      default  -99999999999999999.9       -- 补齐填充元素值
)
returns float[][]
as
$$
declare
  v_dloss_dx               float[][] ;       --   intact 之后的新矩阵
  v_y                      int             :=   coalesce(i_padding[1], 0) + array_length(i_x, 1) + coalesce(i_padding[2], 0);     --   新矩阵高
  v_x                      int             :=   coalesce(i_padding[3], 0) + array_length(i_x, 2) + coalesce(i_padding[4], 0);     --   新矩阵宽
  v_cur_y                  int             ;     --   新矩阵高游标
  v_cur_x                  int             ;     --   新矩阵宽游标
  v_windows_cnt_reciproca  float  :=   1.0 :: float/ (array_length(i_dloss_dy, 1) * array_length(i_dloss_dy, 2));     -- 开窗数量的倒数
begin
  if i_y is null
  then
    i_y := sm_sc.fv_pool_max(i_x, i_window_len, i_stride, i_padding, i_padding_value);
  end if;
  
  if array_dims(i_dloss_dy) is distinct from array_dims(i_y)
    or array_length(i_dloss_dy, 1) <> (v_y - i_window_len[1]) / i_stride[1] + 1
    or array_length(i_dloss_dy, 2) <> (v_x - i_window_len[2]) / i_stride[2] + 1
  then
    raise exception 'unmatch length between y and dloss/dy.';
  end if;

  v_dloss_dx := sm_sc.fv_new(0.0 :: float, array[v_y, v_x]);

  v_cur_y := v_y;
  while v_cur_y >= 1
  loop 
    v_cur_x := v_x;
    while v_cur_x >= 1
    loop 
      v_dloss_dx[v_cur_y][v_cur_x] := 
        coalesce 
        (
          (
            select
              sum
              (
                case when i_y[a_cur_y_dloss_dy][a_cur_x_dloss_dy] = i_x[v_cur_y][v_cur_x] 
                  then v_windows_cnt_reciproca else 0.0 end                   --  dloss_dx 当个元素是否是当个窗口的最大值      
                         * i_dloss_dy[a_cur_y_dloss_dy][a_cur_x_dloss_dy]     --   dloss_dx 当个元素对应的 dloss_dy 元素                 
              ) 
            from 
              -- 以 y 方向为例推导
              -- 对于 i_x 的第 v_cur_y 个元素，寻找其在 i_dloss_dy 对应的  a_cur_y_dloss_dy 
              -- a_cur_y_dloss_dy 这个滑窗之前存在 (a_cur_y_dloss_dy - 1) 个 i_stride[1]，且 v_cur_y 落入该窗口
              -- 即: (a_cur_y_dloss_dy - 1) * i_stride[1] + 1 <= v_cur_y <= (a_cur_y_dloss_dy - 1) * i_stride[1] + i_window_len
              --   => v_cur_y - i_window_len <= (a_cur_y_dloss_dy - 1) * i_stride[1] <= v_cur_y - 1
              --   => (v_cur_y - i_window_len) / i_stride[1] + 1 <= a_cur_y_dloss_dy <= (v_cur_y - 1) / i_stride[1] + 1
              generate_series(greatest(ceil((v_cur_y :: decimal - i_window_len[1]) / i_stride[1]) + 1, 1), least((v_cur_y - 1) / i_stride[1] + 1, v_y), 1) tb_a_cur_y(a_cur_y_dloss_dy),  
              generate_series(greatest(ceil((v_cur_x :: decimal - i_window_len[2]) / i_stride[2]) + 1, 1), least((v_cur_x - 1) / i_stride[2] + 1, v_x), 1) tb_a_cur_x(a_cur_x_dloss_dy)
          )
          , 0.0
        )
        ;
      v_cur_x := v_cur_x - 1;
    end loop;
    v_cur_y := v_cur_y - 1;
  end loop;

  return -- 还原为排除 intact 的子矩阵
    v_dloss_dx[1 + i_padding[1] : v_y - i_padding[2]][1 + i_padding[3] : v_x - i_padding[4]]
  ;
end
$$
language plpgsql stable
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_pool_max_dloss_dindepdt
--   (
--     array[array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[-1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , array[-10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0]
--          ]
--    , array[array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--          ]
--    , array[3, 3]
--    , null
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_max_dloss_dindepdt
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--          ]::float[][]
--    , array[array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--          ]
--    , array[3, 3]
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );