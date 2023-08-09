-- -- 参考：https://blog.csdn.net/LoseInVain/article/details/98451913

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_avg_dloss_dindepdt(int[2], float[][], int[2], int[2], int[4]);
create or replace function sm_sc.fv_d_pool_avg_dloss_dindepdt
(
  i_x_array_ndims      int[2]                                               ,  -- 原矩阵的高宽大小
  i_dloss_dy           float[][]                                   ,  -- 即已求出的损失函数对 y 的导数矩阵
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]          -- 上下左右补齐行数/列数
)
returns float[][]
as
$$
declare
  v_dloss_dx               float[][]  ;      --   intact 之后的新矩阵
  v_y                      int             :=   coalesce(i_padding[1], 0) + i_x_array_ndims[1] + coalesce(i_padding[2], 0);     --   新矩阵高
  v_x                      int             :=   coalesce(i_padding[3], 0) + i_x_array_ndims[2] + coalesce(i_padding[4], 0);     --   新矩阵宽
  v_cur_y                  int             ;     --   新矩阵高游标
  v_cur_x                  int             ;     --   新矩阵宽游标
  v_windows_cnt_reciproca  float  :=   1.0 :: float/ (array_length(i_dloss_dy, 1) * array_length(i_dloss_dy, 2) * i_window_len[1] * i_window_len[2]);     -- 开窗数量的倒数
begin
  
  if array_length(i_dloss_dy, 1) <> (v_y - i_window_len[1]) / i_stride[1] + 1
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
                v_windows_cnt_reciproca * i_dloss_dy[a_cur_y_dloss_dy][a_cur_x_dloss_dy]     --   dloss_dx 当个元素对应的 dloss_dy 元素                 
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
-- select sm_sc.fv_d_pool_avg_dloss_dindepdt
--   (
--     array[5, 7]
--    , array[array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--          ]
--    , array[3, 3]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt
--   (
--     array[5, 7]
--    , array[array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--          ]
--    , array[3, 3]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );