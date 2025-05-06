-- -- 参考：https://blog.csdn.net/LoseInVain/article/details/98451913

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_avg_dloss_dindepdt(int[2], float[], int[2], int[4]);
create or replace function sm_sc.fv_d_pool_avg_dloss_dindepdt
(
  -- -- i_background_len     int[]                                               ,  -- 背景二维平面的高宽大小
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_dloss_ddepdt       float[]                                              ,  -- 即已求出的损失函数对 y 的导数矩阵
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]          -- 上下左右补齐行数/列数
)
returns float[][]
as
$$
declare
  v_dloss_dindepdt         float[][]       ;    --   intact 之后的新矩阵
  v_dloss_ddepdt_len_heigh int             :=   array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) ;
  v_dloss_ddepdt_len_width int             :=   array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) ;
  -- -- v_background_len         -- int[2]       :=   array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
  -- --                          int[2]          :=   i_background_len[array_length(i_background_len, 1) - 1 : array_length(i_background_len, 1)];
  v_y                      int             :=   (v_dloss_ddepdt_len_heigh - 1) * i_stride[1] + i_window_len[1];  -- --  coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0);     --   新矩阵高
  v_x                      int             :=   (v_dloss_ddepdt_len_width - 1) * i_stride[2] + i_window_len[2];  -- --  coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0);     --   新矩阵宽
  v_cur_y                  int             ;     --   新矩阵高游标
  v_cur_x                  int             ;     --   新矩阵宽游标
  -- -- v_windows_cnt_reciproca  float           :=   1.0 :: float/ (v_dloss_ddepdt_len_heigh * v_dloss_ddepdt_len_width * i_window_len[1] * i_window_len[2]);     -- 开窗数量的倒数
begin

  -- -- -- 审计
  -- -- if current_setting('pg4ml._v_is_debug_check', true) = '1'
  -- -- then
  -- --   if v_dloss_ddepdt_len_heigh <> (v_y - i_window_len[1]) / i_stride[1] + 1
  -- --     or v_dloss_ddepdt_len_width <> (v_x - i_window_len[2]) / i_stride[2] + 1
  -- --   then
  -- --     raise exception 'unmatch length between y and dloss/dy.';
  -- --   end if;
  -- -- end if;
  
  i_dloss_ddepdt := i_dloss_ddepdt /` (i_window_len[1] * i_window_len[2]);

  if array_ndims(i_dloss_ddepdt) = 2
  then 
    v_dloss_dindepdt := sm_sc.fv_new(0.0 :: float, array[v_y, v_x]);
    
    v_cur_y := v_y;
    while v_cur_y >= 1
    loop 
      v_cur_x := v_x;
      while v_cur_x >= 1
      loop 
        v_dloss_dindepdt[v_cur_y][v_cur_x] := 
          coalesce 
          (
            (
              select
                sum
                (    
                  -- -- v_windows_cnt_reciproca * 
                  i_dloss_ddepdt[a_cur_y_dloss_ddepdt][a_cur_x_dloss_ddepdt]     --   dloss_dindepdt 当个元素对应的 dloss_ddepdt 元素                 
                ) 
              from 
                -- 以 y 方向为例推导
                -- 对于 i_indepdt 的第 v_cur_y 个元素，寻找其在 i_dloss_ddepdt 对应的  a_cur_y_dloss_ddepdt 
                -- a_cur_y_dloss_ddepdt 这个滑窗之前存在 (a_cur_y_dloss_ddepdt - 1) 个 i_stride[1]，且 v_cur_y 落入该窗口
                -- 即: (a_cur_y_dloss_ddepdt - 1) * i_stride[1] + 1 <= v_cur_y <= (a_cur_y_dloss_ddepdt - 1) * i_stride[1] + i_window_len
                --   => v_cur_y - i_window_len <= (a_cur_y_dloss_ddepdt - 1) * i_stride[1] <= v_cur_y - 1
                --   => (v_cur_y - i_window_len) / i_stride[1] + 1 <= a_cur_y_dloss_ddepdt <= (v_cur_y - 1) / i_stride[1] + 1
                generate_series(greatest(ceil((v_cur_y :: decimal - i_window_len[1]) / i_stride[1]) + 1, 1), least((v_cur_y - 1) / i_stride[1] + 1, v_y), 1) tb_a_cur_y(a_cur_y_dloss_ddepdt),  
                generate_series(greatest(ceil((v_cur_x :: decimal - i_window_len[2]) / i_stride[2]) + 1, 1), least((v_cur_x - 1) / i_stride[2] + 1, v_x), 1) tb_a_cur_x(a_cur_x_dloss_ddepdt)
            )
            , 0.0
          )
          ;
        v_cur_x := v_cur_x - 1;
      end loop;
      v_cur_y := v_cur_y - 1;
    end loop;
    
    return -- 还原为排除 intact 的子矩阵
      v_dloss_dindepdt[1 + i_padding[1] : v_y - i_padding[2]][1 + i_padding[3] : v_x - i_padding[4]]
    ;
    
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    return 
    (
      select 
        array_agg 
        (
          sm_sc.fv_d_pool_avg_dloss_dindepdt
          (
            -- --   i_background_len,
            i_window_len 
          , sm_sc.fv_mx_slice_3d_2_2d
            (
              i_dloss_ddepdt[a_cur_y : a_cur_y]
            , 1
            )    
          , i_stride       
          , i_padding    
          )
          order by a_cur_y
        )
      from generate_series(1, array_length(i_dloss_ddepdt, 1)) tb_a_cur_y(a_cur_y)
    );
    
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    return 
    (
      with 
      cte_agg_x as
      (
        select 
          a_cur_y,
          array_agg 
          (
            sm_sc.fv_d_pool_avg_dloss_dindepdt
            (
              -- --   i_background_len,
              i_window_len  
            , sm_sc.fv_mx_slice_4d_2_2d
              (
                i_dloss_ddepdt[a_cur_y : a_cur_y][a_cur_x : a_cur_x][ : ][ : ]
              , array[1, 2]
              , array[1, 1]
              )   
            , i_stride       
            , i_padding    
            )
            order by a_cur_x
          ) as a_agg_x
        from generate_series(1, array_length(i_dloss_ddepdt, 1)) tb_a_cur_y(a_cur_y)
          , generate_series(1, array_length(i_dloss_ddepdt, 2)) tb_a_cur_x(a_cur_x)
        group by a_cur_y
      )
      select 
        array_agg(a_agg_x order by a_cur_y)
      from cte_agg_x
    );
    
  end if;
end
$$
language plpgsql stable
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_pool_avg_dloss_dindepdt
--   (
--      -- -- array[5, 7],
--      array[3, 3]
--    , array[[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt
--   (
--      -- -- array[5, 6],
--      array[3, 3]
--    , array[[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt
--   (
--      -- -- array[5, 6]
--      array[3, 3]
--    , array
--       [
--         [[1.1, 1.1, 1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--       , [[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[-1.1, 1.1, -1.1]
--          ]
--       ]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );

-- select sm_sc.fv_d_pool_avg_dloss_dindepdt
--   (
--     -- array[5, 6],
--     array[3, 3]
--   , array
--     [
--       [
--         [[1.1, 1.1, 1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--          ]
--       , [[1.1, -1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[-1.1, 1.1, -1.1]
--          ]
--       ]
--     , [
--         [[1.1, 1.1, -1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[-1.1, 1.1, 1.1]
--          ]
--       , [[-1.1, -1.1, 1.1]
--         ,[1.1, -1.1, 1.1]
--         ,[-1.1, 1.1, -1.1]
--          ]
--       ]
--     ]
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--   );