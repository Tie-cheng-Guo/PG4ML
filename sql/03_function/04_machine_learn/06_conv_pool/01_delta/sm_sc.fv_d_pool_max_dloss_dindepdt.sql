-- -- 参考：https://blog.csdn.net/LoseInVain/article/details/98451913

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_max_dloss_dindepdt(float[], int[2], float[], float[], int[2], int[4], float);
create or replace function sm_sc.fv_d_pool_max_dloss_dindepdt
(
  i_indepdt                  float[]                                   ,  -- 原矩阵
  i_window_len         int[2]                                               ,  -- 池化窗口高宽大小
  i_dloss_ddepdt       float[]                                   ,  -- 即已求出的损失函数对 y 的导数矩阵
  i_depdt                  float[][]  default  null                    ,  -- 即已求出的算子结果矩阵
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      float      default  '-inf'       -- 补齐填充元素值
)
returns float[][]
as
$$
declare
  v_dloss_dindepdt               float[][] ;       --   intact 之后的新矩阵
  v_indepdt                      float[][] ;
  v_y                      int             :=   coalesce(i_padding[1], 0) + array_length(i_indepdt, 1) + coalesce(i_padding[2], 0);     --   新矩阵高
  v_x                      int             :=   coalesce(i_padding[3], 0) + array_length(i_indepdt, 2) + coalesce(i_padding[4], 0);     --   新矩阵宽
  v_cur_y                  int             ;     --   新矩阵高游标
  v_cur_x                  int             ;     --   新矩阵宽游标
  v_dloss_ddepdt_len_heigh     int    :=   array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) ;
  v_dloss_ddepdt_len_width     int    :=   array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) ;
  -- -- v_windows_cnt_reciproca  float  :=   1.0 :: float/ (v_dloss_ddepdt_len_heigh * v_dloss_ddepdt_len_width);     -- 开窗数量的倒数
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(v_dloss_dindepdt) <> array_ndims(i_indepdt)
    then 
      raise exception 'unmatch ndims between v_dloss_dindepdt and i_indepdt';
    elsif array_ndims(v_dloss_dindepdt) = 3 and v_dloss_ddepdt_len_heigh <> array_length(i_indepdt, 1)
      or array_ndims(v_dloss_dindepdt) = 4 and (v_dloss_ddepdt_len_heigh <> array_length(i_indepdt, 1) or v_dloss_ddepdt_len_width <> array_length(i_indepdt, 2))
    then 
      raise exception 'unmatch length at 1d of 3d or 1d / 2d of 4d';
    elsif array_dims(i_dloss_ddepdt) <> array_dims(i_depdt)
      or v_dloss_ddepdt_len_heigh <> (v_y - i_window_len[1]) / i_stride[1] + 1
      or v_dloss_ddepdt_len_width <> (v_x - i_window_len[2]) / i_stride[2] + 1
    then
      raise exception 'unmatch length between y and dloss/dy.';
    end if;
  end if;

  if array_ndims(i_dloss_ddepdt) = 2
  then 
    v_indepdt := 
      sm_sc.fv_augmented
      (
        i_indepdt, 
        array[-i_padding[1] + 1, -i_padding[3] + 1], 
        array[array_length(i_indepdt, 1) + i_padding[2], array_length(i_indepdt, 2) + i_padding[4]], 
        i_padding_value
      );
  
    if i_depdt is null
    then
      i_depdt := sm_sc.fv_pool_max(i_indepdt, i_window_len, i_stride, i_padding, i_padding_value);
    end if;
    
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
                  -- -- case when i_depdt[a_cur_y_dloss_ddepdt][a_cur_x_dloss_ddepdt] = v_indepdt[v_cur_y][v_cur_x] 
                  -- --   then v_windows_cnt_reciproca else 0.0 end                   --  dloss_dindepdt 当个元素是否是当个窗口的最大值      
                  -- --          * i_dloss_ddepdt[a_cur_y_dloss_ddepdt][a_cur_x_dloss_ddepdt]     --   dloss_dindepdt 当个元素对应的 dloss_ddepdt 元素       
                  case when i_depdt[a_cur_y_dloss_ddepdt][a_cur_x_dloss_ddepdt] = v_indepdt[v_cur_y][v_cur_x] 
                    then i_dloss_ddepdt[a_cur_y_dloss_ddepdt][a_cur_x_dloss_ddepdt] else 0.0 end                   --  dloss_dindepdt 当个元素是否是当个窗口的最大值                  
                ) 
              from 
                -- 以 y 方向为例推导
                -- 对于 v_indepdt 的第 v_cur_y 个元素，寻找其在 i_dloss_ddepdt 对应的  a_cur_y_dloss_ddepdt 
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
          sm_sc.fv_d_pool_max_dloss_dindepdt
          (
            sm_sc.fv_mx_slice_3d_2_2d
            (
              i_indepdt[a_cur_y : a_cur_y]
            , 1
            )
          , i_window_len  
          , sm_sc.fv_mx_slice_3d_2_2d
            (
              i_dloss_ddepdt[a_cur_y : a_cur_y]
            , 1
            )
          , sm_sc.fv_mx_slice_3d_2_2d
            (
              i_depdt[a_cur_y : a_cur_y]
            , 1
            )
          , i_stride       
          , i_padding  
          , i_padding_value  
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
            sm_sc.fv_d_pool_max_dloss_dindepdt
            (
              sm_sc.fv_mx_slice_4d_2_2d
              (
                i_indepdt[a_cur_y : a_cur_y][a_cur_x : a_cur_x][ : ][ : ]
              , array[1, 2]
              , array[1, 1]
              )
            , i_window_len 
            , sm_sc.fv_mx_slice_4d_2_2d
              (
                i_dloss_ddepdt[a_cur_y : a_cur_y][a_cur_x : a_cur_x][ : ][ : ]
              , array[1, 2]
              , array[1, 1]
              )
            , sm_sc.fv_mx_slice_4d_2_2d
              (
                i_depdt[a_cur_y : a_cur_y][a_cur_x : a_cur_x][ : ][ : ]
              , array[1, 2]
              , array[1, 1]
              )
            , i_stride       
            , i_padding  
            , i_padding_value 
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
-- select sm_sc.fv_d_pool_max_dloss_dindepdt
--   (
--     array[array[1.0 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[-1.0 :: float,-2.0 :: float,-3.0,-4.0,-5.0,-6.0,-7.0]
--         , array[-10.0 :: float,-20.0 :: float,-30.0 :: float,-40.0 :: float,-50.0 :: float,-60.0 :: float,-70.0]
--          ]
--    , array[3, 3]
--    , array[array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--          ]
--    , null
--    , array[2, 2]
--   );

-- select sm_sc.fv_d_pool_max_dloss_dindepdt
--   (
--     array[[1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--          ]::float[][]
--    , array[3, 3]
--    , array[array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--         ,array[1.1, 1.1, 1.1]
--          ]
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );

-- select sm_sc.fv_d_pool_max_dloss_dindepdt
--   (
--     array
--       [
--         [
--           [1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--         ]
--       , [
--           [1,2,3,-4,-5,6]
--         , [10,20,30,40,-50,60]
--         , [100,200,-300,400,500,600]
--         , [-1,2,-3,-4,-5,6]
--         , [10,20,-30,40,-50,-60]
--         ]
--       ]
--    , array[3, 3]
--    , array
--       [
--         [
--          [1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ,[1.1, 1.1, 1.1]
--         ]
--       , [
--          [1.1, -1.1, 1.1]
--         ,[1.1, 1.1, -1.1]
--         ,[-1.1, 1.1, 1.1]
--         ]
--       ]
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );

-- select sm_sc.fv_d_pool_max_dloss_dindepdt
--   (
--     array
--     [
--       [
--         [
--           [1,2,3,4,5,6]
--         , [10,20,30,40,50,60]
--         , [100,200,300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--         ]
--       , [
--           [1,2,3,-4,-5,6]
--         , [10,20,30,40,-50,60]
--         , [100,200,-300,400,500,600]
--         , [-1,2,-3,-4,-5,6]
--         , [10,20,-30,40,-50,-60]
--         ]
--       ]
--     , [
--         [
--           [-1,2,-3,4,5,6]
--         , [10,20,-30,40,-50,60]
--         , [100,-200,-300,400,500,600]
--         , [-1,-2,-3,-4,-5,-6]
--         , [-10,-20,-30,-40,-50,-60]
--         ]
--       , [
--           [1,-2,3,4,-5,6]
--         , [10,20,30,40,-50,60]
--         , [100,-200,-300,400,-500,-600]
--         , [-1,2,-3,-4,-5,6]
--         , [10,20,30,40,-50,-60]
--         ]
--       ]
--     ]
--    , array[3, 3]
--    , array
--      [
--        [
--          [
--           [1.1, 1.1, 1.1]
--          ,[1.1, 1.1, 1.1]
--          ,[1.1, 1.1, 1.1]
--          ]
--        , [
--           [1.1, -1.1, 1.1]
--          ,[1.1, 1.1, -1.1]
--          ,[-1.1, 1.1, 1.1]
--          ]
--        ]
--      , [
--          [
--           [1.1, -1.1, 1.1]
--          ,[1.1, -1.1, 1.1]
--          ,[1.1, -1.1, 1.1]
--          ]
--        , [
--           [1.1, 1.1, 1.1]
--          ,[-1.1, -1.1, -1.1]
--          ,[-1.1, 1.1, 1.1]
--          ]
--        ]
--      ]
--    , null
--    , array[2, 2]
--    , array[1, 1, 1, 0]
--    , 0
--   );