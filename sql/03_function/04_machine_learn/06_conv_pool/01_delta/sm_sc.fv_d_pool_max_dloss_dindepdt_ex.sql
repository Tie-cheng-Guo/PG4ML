-- -- 参考：https://blog.csdn.net/LoseInVain/article/details/98451913

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_pool_max_dloss_dindepdt_ex(float[], int[2], float[], float[], int[2], int[4], float);
create or replace function sm_sc.fv_d_pool_max_dloss_dindepdt_ex
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
  v_indepdt                                float[]   ;
  v_strided_dloss_ddepdt                   float[]   ;     --   intact 之后的新矩阵
  v_strided_dloss_ddepdt_width_destrided   float[]   ;
  v_strided_dloss_ddepdt_heigh_destrided   float[]   ;
  v_indepdt_len_heigh                      int       :=   coalesce(i_padding[1], 0) + array_length(i_indepdt, array_ndims(i_indepdt) - 1) + coalesce(i_padding[2], 0);     --   新矩阵高
  v_indepdt_len_width                      int       :=   coalesce(i_padding[3], 0) + array_length(i_indepdt, array_ndims(i_indepdt)) + coalesce(i_padding[4], 0);     --   新矩阵宽
  v_dloss_ddepdt_len_heigh                 int       :=   array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) ;
  v_dloss_ddepdt_len_width                 int       :=   array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) ;
  -- -- v_windows_cnt_reciproca  float  :=   1.0 :: float/ (v_dloss_ddepdt_len_heigh * v_dloss_ddepdt_len_width);     -- 开窗数量的倒数
  v_cnt_overlap_width                      int       ;
  v_cnt_overlap_heigh                      int       ;
  v_ret                                    float[]   ;
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_ddepdt) <> array_ndims(i_indepdt)
    then 
      raise exception 'unmatch ndims between i_dloss_ddepdt and i_indepdt';
    elsif array_dims(i_dloss_ddepdt) <> array_dims(i_depdt)
      or v_dloss_ddepdt_len_heigh <> (v_y - i_window_len[1]) / i_stride[1] + 1
      or v_dloss_ddepdt_len_width <> (v_x - i_window_len[2]) / i_stride[2] + 1
    then
      raise exception 'unmatch length between y and dloss/dy.';
    end if;
  end if;

  if i_depdt is null
  then
    i_depdt := sm_sc.fv_pool_max_py(i_indepdt, i_window_len, i_stride, i_padding, i_padding_value);
  end if;
  
  -- 对于窗口长度大于步长的场景，将相邻窗口以错位分层的方式分组，再对分组做矩阵颗粒度合计聚合。如下是一维长度为 13、窗口宽度为 5、步长为 2 的错位分层分组示意图:
  -- 
  -- 以 pool_none 算子操作为例: 
  -- 假定:
  --   i_indepdt = array[1,2,3,4,5,6,7,8,9,10,11,12,13];
  --   i_dloss_ddepdt = array[-1,-2,-3,-4,-5]
  -- 
  -- 采样，得到各窗口轨迹:
  --   i_indepdt_window = 
  --     array
  --     [
  --       [ 1, 2, 3, 4, 5], [ 7, 8, 9,10,11]
  --     ,       [ 3, 4, 5, 6, 7], [ 9,10,11,12,13]
  --     ,             [ 5, 6, 7, 8, 9]
  --     ];
  -- 
  -- 窗口导数值映射至窗口内每个元素位置，按照窗口轨迹，将重叠窗口排版至不同分组
  --   i_dloss_ddepdt_repeat = 
  --     array 
  --     [
  --     , -1, -1, -1, -1, -1    , -4, -4, -4, -4, -4
  --             , -2, -2, -2, -2, -2    , -5, -5, -5, -5, -5
  --                     , -3, -3, -3, -3, -3
  --     ];
  -- 
  -- 不同分组矩阵粒度聚合合计，便能合计出某个元素被多个窗口划过重叠部分的每个导数分量
  --   i_dloss_dindepdt = 
  --     array 
  --     [ -1, -1, -3, -3, -6, -5, -9, -7, -12,-9, -9, -5, -5];
  -- 

  if i_window_len = i_stride
  then 
    if i_padding = array[0, 0, 0, 0]
    then 
      return sm_sc.fv_d_aggr_slice_max_dloss_dindepdt_py(i_indepdt, i_depdt, i_dloss_ddepdt);
    else 
      v_indepdt :=
        sm_sc.fv_augmented
        (
          i_indepdt, 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[array_length(i_indepdt, array_ndims(i_indepdt) - 1) + i_padding[2], array_length(i_indepdt, array_ndims(i_indepdt)) + i_padding[4]], 
          i_padding_value
        )
      ;
      v_ret := sm_sc.fv_d_aggr_slice_max_dloss_dindepdt_py(v_indepdt, i_depdt, i_dloss_ddepdt);
      if array_ndims(v_indepdt) = 2
      then 
        return 
          v_ret
            [i_padding[1] + 1 : array_length(v_indepdt, array_ndims(v_indepdt) - 1) - i_padding[2]]
            [i_padding[3] + 1 : array_length(v_indepdt, array_ndims(v_indepdt)) - i_padding[4]]
        ;
      elsif array_ndims(v_indepdt) = 3
      then 
        return 
          v_ret
            [ : ]
            [i_padding[1] + 1 : array_length(v_indepdt, array_ndims(v_indepdt) - 1) - i_padding[2]]
            [i_padding[3] + 1 : array_length(v_indepdt, array_ndims(v_indepdt)) - i_padding[4]]
        ;
      elsif array_ndims(v_indepdt) = 4
      then 
        return 
          v_ret
            [ : ]
            [ : ]
            [i_padding[1] + 1 : array_length(v_indepdt, array_ndims(v_indepdt) - 1) - i_padding[2]]
            [i_padding[3] + 1 : array_length(v_indepdt, array_ndims(v_indepdt)) - i_padding[4]]
        ;
      end if;
    end if;
  else
    v_strided_dloss_ddepdt :=
      sm_sc.fv_repeat_axis_py
      (
        sm_sc.fv_repeat_axis_py
        (
          i_dloss_ddepdt -- -- *` v_windows_cnt_reciproca
        , -1
        , i_window_len[2]
        )
      , -2
      , i_window_len[1]
      )
      *`
      ( -- 寻找到各个滑动区域的 max 位置，置 1
        (
          sm_sc.fv_pool_none_py
          (
            i_indepdt
          , i_window_len
          , i_stride
          , i_padding
          , i_padding_value
          ) 
          ==` 
          sm_sc.fv_repeat_axis_py
          (
            sm_sc.fv_repeat_axis_py
            (
              i_depdt
            , -1
            , i_window_len[2]
            )
          , -2
          , i_window_len[1]
          )          
        )
        :: int[] :: float[]
      )
    ;
    
    if array_ndims(i_dloss_ddepdt) = 2
    then     
      -- -1 维度
      if i_window_len[2] <= i_stride[2]                                                                  
      then                                                                                                
        v_strided_dloss_ddepdt_width_destrided :=
          sm_sc.fv_sample_x_py    -- fv_sample_-1  
          (
            v_strided_dloss_ddepdt
          , i_stride[2]                              -- i_window_len
          , i_stride[2]                              -- i_period
          , int4range(1, i_window_len[2], '[]')      -- i_simp_range
          , 0.0 :: float
          )   -- )[ : ][ : v_indepdt_len_width + i_padding[3] + i_padding[4] - (i_stride[2] - i_window_len[2])]
        ;
      else  -- i_window_len[2] > i_stride[2]
        v_cnt_overlap_width := (i_window_len[2] - 1) / i_stride[2] + 1;
        v_strided_dloss_ddepdt_width_destrided := 
          (
            with 
            cte_slice_sample as 
            (
              select 
                a_no
              , sm_sc.fv_lpad    -- sm_sc.fv_apad
                (
                  sm_sc.fv_sample_x_py   -- fv_sample_-1
                  (
                    sm_sc.fv_concat_x      -- fv_concat_y
                    (
                      v_strided_dloss_ddepdt
                        [ : ]
                        [i_window_len[2] * (a_no - 1) + 1 : ]    -- array_length(v_strided_dloss_ddepdt, -1)
                    , array_fill
                      (
                        0.0 :: float
                      , array
                        [
                          array_length(v_strided_dloss_ddepdt, 1)
                        , (v_cnt_overlap_width - a_no) * i_window_len[2]   -- v_cnt_overlap_heigh
                        ]
                      )
                    )
                  , v_cnt_overlap_width * i_window_len[2]
                  , i_stride[2] * v_cnt_overlap_width -- i_window_len[2]
                  , int4range(1, i_window_len[2], '[]')
                  , 0.0 :: float
                  )
                , array[[0.0]] :: float[]
                , (a_no - 1) * i_stride[2]
                ) 
                as a_slice_sample
              from generate_series(1, v_cnt_overlap_width) tb_a(a_no)
            ),
            cte_slice_max_len as 
            (
              select 
                max(array_length(a_slice_sample, 2)) as a_slice_max_len   -- array_length(a_slice_sample, -1)
              from cte_slice_sample
            )
            select 
              (sm_sc.fa_mx_sum
              (
                sm_sc.fv_rpad     -- sm_sc.fv_bpad
                (
                  a_slice_sample
                , array[[0.0]] :: float[]
                , a_slice_max_len - array_length(a_slice_sample, 2)     -- array_length(a_slice_sample, -1)
                )
              ))[ : ][ : v_indepdt_len_width]   -- -1 切片
            from cte_slice_sample, cte_slice_max_len
          );
      end if;
      
      -- -2 维度 
      if i_window_len[1] <= i_stride[1]
      then 
        v_strided_dloss_ddepdt_heigh_destrided :=
          sm_sc.fv_sample_y_py    -- fv_sample_-2  
          (
            v_strided_dloss_ddepdt_width_destrided
          , i_stride[1]                              -- i_window_len
          , i_stride[1]                              -- i_period
          , int4range(1, i_window_len[1], '[]')      -- i_simp_range
          , 0.0 :: float
          )    -- )[ : v_indepdt_len_heigh + i_padding[1] + i_padding[2] - (i_stride[1] - i_window_len[1])][ : ]
        ;
      else  -- i_window_len[1] > i_stride[1]
        v_cnt_overlap_heigh := (i_window_len[1] - 1) / i_stride[1] + 1;
        v_strided_dloss_ddepdt_heigh_destrided := 
          (
            with 
            cte_slice_sample as 
            (
              select 
                a_no
              , sm_sc.fv_apad    -- sm_sc.fv_lpad
                (
                  sm_sc.fv_sample_y_py   -- fv_sample_-2
                  (
                    sm_sc.fv_concat_y   -- -- -- fv_concat_x
                    (
                      v_strided_dloss_ddepdt_width_destrided
                        [i_window_len[1] * (a_no - 1) + 1 : ]
                        [ : ]    -- array_length(v_strided_dloss_ddepdt_width_destrided, -2)
                    , array_fill
                      (
                        0.0 :: float
                      , array
                        [
                          (v_cnt_overlap_heigh - a_no) * i_window_len[1]  -- -- -- v_cnt_overlap_width
                        , array_length(v_strided_dloss_ddepdt_width_destrided, 2)
                        ]
                      )
                    )
                  , v_cnt_overlap_heigh * i_window_len[1]
                  , i_stride[1] * v_cnt_overlap_heigh -- i_window_len[1]
                  , int4range(1, i_window_len[1], '[]')
                  , 0.0 :: float
                  )                
                , array[[0.0]] :: float[]
                , (a_no - 1) * i_stride[1]
                ) 
                as a_slice_sample
              from generate_series(1, v_cnt_overlap_heigh) tb_a(a_no)
            ),
            cte_slice_max_len as 
            (
              select 
                max(array_length(a_slice_sample, 1)) as a_slice_max_len   -- array_length(a_slice_sample, -2)
              from cte_slice_sample
            )
            select 
              (sm_sc.fa_mx_sum
              (
                sm_sc.fv_bpad     -- sm_sc.fv_rpad
                (
                  a_slice_sample
                , array[[0.0]] :: float[]
                , a_slice_max_len - array_length(a_slice_sample, 1)     -- array_length(a_slice_sample, -2)
                )
              ))[ : v_indepdt_len_heigh][ : ]   -- -2 切片
            from cte_slice_sample, cte_slice_max_len
          );
      end if;
    
      return 
        v_strided_dloss_ddepdt_heigh_destrided    -- 去除 pad
          [i_padding[1] + 1 : i_padding[1] + array_length(i_indepdt, 1)]         -- array_length(i_indepdt, -2)
          [i_padding[3] + 1 : i_padding[3] + array_length(i_indepdt, 2)]         -- array_length(i_indepdt, -1)
      ;
      
    elsif array_ndims(i_dloss_ddepdt) = 3
    then    
      -- -1 维度
      if i_window_len[2] <= i_stride[2]                                                                  
      then                                                                                                
        v_strided_dloss_ddepdt_width_destrided := 
          sm_sc.fv_sample_x3_py     -- fv_sample_-1 
          (
            v_strided_dloss_ddepdt
          , i_stride[2]                              -- i_window_len
          , i_stride[2]                              -- i_period
          , int4range(1, i_window_len[2], '[]')      -- i_simp_range
          , 0.0 :: float
          );  
      else  -- i_window_len[2] > i_stride[2]
        v_cnt_overlap_width := (i_window_len[2] - 1) / i_stride[2] + 1;
        v_strided_dloss_ddepdt_width_destrided := 
          (
            with 
            cte_slice_sample as 
            (
              select 
                a_no
              , sm_sc.fv_lpad    -- sm_sc.fv_apad
                (
                  sm_sc.fv_sample_x3_py   -- fv_sample_-1
                  (
                    sm_sc.fv_concat_x3      -- fv_concat_y
                    (
                      v_strided_dloss_ddepdt
                        [ : ]
                        [ : ]
                        [i_window_len[2] * (a_no - 1) + 1 : ]    -- array_length(v_strided_dloss_ddepdt, -1)
                    , array_fill
                      (
                        0.0 :: float
                      , array
                        [
                          array_length(v_strided_dloss_ddepdt, 1)
                        , array_length(v_strided_dloss_ddepdt, 2)
                        , (v_cnt_overlap_width - a_no) * i_window_len[2]   -- v_cnt_overlap_heigh
                        ]
                      )
                    )
                  , v_cnt_overlap_width * i_window_len[2]
                  , i_stride[2] * v_cnt_overlap_width -- i_window_len[2]
                  , int4range(1, i_window_len[2], '[]')
                  , 0.0 :: float
                  )
                , array[[[0.0]]] :: float[]
                , (a_no - 1) * i_stride[2]
                ) 
                as a_slice_sample
              from generate_series(1, v_cnt_overlap_width) tb_a(a_no)
            ),
            cte_slice_max_len as 
            (
              select 
                max(array_length(a_slice_sample, 3)) as a_slice_max_len   -- array_length(a_slice_sample, -1)
              from cte_slice_sample
            )
            select 
              (sm_sc.fa_mx_sum
              (
                sm_sc.fv_rpad     -- sm_sc.fv_bpad
                (
                  a_slice_sample
                , array[[[0.0]]] :: float[]
                , a_slice_max_len - array_length(a_slice_sample, 3)     -- array_length(a_slice_sample, -1)
                )
              ))[ : ][ : ][ : v_indepdt_len_width]   -- -1 切片
            from cte_slice_sample, cte_slice_max_len
          );
      end if;
      
      -- -2 维度 
      if i_window_len[1] <= i_stride[1]
      then 
        v_strided_dloss_ddepdt_heigh_destrided :=
          sm_sc.fv_sample_x_py   -- fv_sample_-2  
          (
            v_strided_dloss_ddepdt_width_destrided
          , i_stride[1]                              -- i_window_len
          , i_stride[1]                              -- i_period
          , int4range(1, i_window_len[1], '[]')      -- i_simp_range
          , 0.0 :: float
          ); 
      else  -- i_window_len[1] > i_stride[1]
        v_cnt_overlap_heigh := (i_window_len[1] - 1) / i_stride[1] + 1;
        v_strided_dloss_ddepdt_heigh_destrided := 
          (
            with 
            cte_slice_sample as 
            (
              select 
                a_no
              , sm_sc.fv_apad    -- sm_sc.fv_lpad
                (
                  sm_sc.fv_sample_x_py   -- fv_sample_-2
                  (
                    sm_sc.fv_concat_x   -- -- -- fv_concat_x
                    (
                      v_strided_dloss_ddepdt_width_destrided
                        [ : ]
                        [i_window_len[1] * (a_no - 1) + 1 : ]
                        [ : ]    -- array_length(v_strided_dloss_ddepdt_width_destrided, -2)
                    , array_fill
                      (
                        0.0 :: float
                      , array
                        [
                          array_length(v_strided_dloss_ddepdt_width_destrided, 1)
                        , (v_cnt_overlap_heigh - a_no) * i_window_len[1]  -- -- -- v_cnt_overlap_width
                        , array_length(v_strided_dloss_ddepdt_width_destrided, 3)
                        ]
                      )
                    )
                  , v_cnt_overlap_heigh * i_window_len[1]
                  , i_stride[1] * v_cnt_overlap_heigh -- i_window_len[1]
                  , int4range(1, i_window_len[1], '[]')
                  , 0.0 :: float
                  )                
                , array[[[0.0]]] :: float[]
                , (a_no - 1) * i_stride[1]
                ) 
                as a_slice_sample
              from generate_series(1, v_cnt_overlap_heigh) tb_a(a_no)
            ),
            cte_slice_max_len as 
            (
              select 
                max(array_length(a_slice_sample, 2)) as a_slice_max_len   -- array_length(a_slice_sample, -2)
              from cte_slice_sample
            )
            select 
              (sm_sc.fa_mx_sum
              (
                sm_sc.fv_bpad     -- sm_sc.fv_rpad
                (
                  a_slice_sample
                , array[[[0.0]]] :: float[]
                , a_slice_max_len - array_length(a_slice_sample, 2)     -- array_length(a_slice_sample, -2)
                )
              ))[ : ][ : v_indepdt_len_heigh][ : ]   -- -2 切片
            from cte_slice_sample, cte_slice_max_len
          );
      end if;
    
      return 
        v_strided_dloss_ddepdt_heigh_destrided    -- 去除 pad
          [ : ]
          [i_padding[1] + 1 : i_padding[1] + array_length(i_indepdt, 2)]         -- array_length(i_indepdt, -2)
          [i_padding[3] + 1 : i_padding[3] + array_length(i_indepdt, 3)]         -- array_length(i_indepdt, -1)
      ;
      
    elsif array_ndims(i_dloss_ddepdt) = 4
    then    
      -- -1 维度
      if i_window_len[2] <= i_stride[2]                                                                  
      then                                                                                                
        v_strided_dloss_ddepdt_width_destrided := 
          sm_sc.fv_sample_x4_py     -- fv_sample_-1 
          (
            v_strided_dloss_ddepdt
          , i_stride[2]                              -- i_window_len
          , i_stride[2]                              -- i_period
          , int4range(1, i_window_len[2], '[]')      -- i_simp_range
          , 0.0 :: float
          );  
      else  -- i_window_len[2] > i_stride[2]
        v_cnt_overlap_width := (i_window_len[2] - 1) / i_stride[2] + 1;
        v_strided_dloss_ddepdt_width_destrided := 
          (
            with 
            cte_slice_sample as 
            (
              select 
                a_no
              , sm_sc.fv_lpad    -- sm_sc.fv_apad
                (
                  sm_sc.fv_sample_x4_py   -- fv_sample_-1
                  (
                    sm_sc.fv_concat_x4      -- fv_concat_y
                    (
                      v_strided_dloss_ddepdt
                        [ : ]
                        [ : ]
                        [ : ]
                        [i_window_len[2] * (a_no - 1) + 1 : ]    -- array_length(v_strided_dloss_ddepdt, -1)
                    , array_fill
                      (
                        0.0 :: float
                      , array
                        [
                          array_length(v_strided_dloss_ddepdt, 1)
                        , array_length(v_strided_dloss_ddepdt, 2)
                        , array_length(v_strided_dloss_ddepdt, 3)
                        , (v_cnt_overlap_width - a_no) * i_window_len[2]   -- v_cnt_overlap_heigh
                        ]
                      )
                    )
                  , v_cnt_overlap_width * i_window_len[2]
                  , i_stride[2] * v_cnt_overlap_width -- i_window_len[2]
                  , int4range(1, i_window_len[2], '[]')
                  , 0.0 :: float
                  )
                , array[[[[0.0]]]] :: float[]
                , (a_no - 1) * i_stride[2]
                ) 
                as a_slice_sample
              from generate_series(1, v_cnt_overlap_width) tb_a(a_no)
            ),
            cte_slice_max_len as 
            (
              select 
                max(array_length(a_slice_sample, 4)) as a_slice_max_len   -- array_length(a_slice_sample, -1)
              from cte_slice_sample
            )
            select 
              (sm_sc.fa_mx_sum
              (
                sm_sc.fv_rpad     -- sm_sc.fv_bpad
                (
                  a_slice_sample
                , array[[[[0.0]]]] :: float[]
                , a_slice_max_len - array_length(a_slice_sample, 4)     -- array_length(a_slice_sample, -1)
                )
              ))[ : ][ : ][ : ][ : v_indepdt_len_width]   -- -1 切片
            from cte_slice_sample, cte_slice_max_len
          );
      end if;
      
      -- -2 维度 
      if i_window_len[1] <= i_stride[1]
      then 
        v_strided_dloss_ddepdt_heigh_destrided :=
          sm_sc.fv_sample_x3_py   -- fv_sample_-2  
          (
            v_strided_dloss_ddepdt_width_destrided
          , i_stride[1]                              -- i_window_len
          , i_stride[1]                              -- i_period
          , int4range(1, i_window_len[1], '[]')      -- i_simp_range
          , 0.0 :: float
          ); 
      else  -- i_window_len[1] > i_stride[1]
        v_cnt_overlap_heigh := (i_window_len[1] - 1) / i_stride[1] + 1;
        v_strided_dloss_ddepdt_heigh_destrided := 
          (
            with 
            cte_slice_sample as 
            (
              select 
                a_no
              , sm_sc.fv_apad    -- sm_sc.fv_lpad
                (
                  sm_sc.fv_sample_x3_py   -- fv_sample_-2
                  (
                    sm_sc.fv_concat_x3   -- -- -- fv_concat_x
                    (
                      v_strided_dloss_ddepdt_width_destrided
                        [ : ]
                        [ : ]
                        [i_window_len[1] * (a_no - 1) + 1 : ]
                        [ : ]    -- array_length(v_strided_dloss_ddepdt_width_destrided, -2)
                    , array_fill
                      (
                        0.0 :: float
                      , array
                        [
                          array_length(v_strided_dloss_ddepdt_width_destrided, 1)
                        , array_length(v_strided_dloss_ddepdt_width_destrided, 2)
                        , (v_cnt_overlap_heigh - a_no) * i_window_len[1]  -- -- -- v_cnt_overlap_width
                        , array_length(v_strided_dloss_ddepdt_width_destrided, 4)
                        ]
                      )
                    )
                  , v_cnt_overlap_heigh * i_window_len[1]
                  , i_stride[1] * v_cnt_overlap_heigh -- i_window_len[1]
                  , int4range(1, i_window_len[1], '[]')
                  , 0.0 :: float
                  )                
                , array[[[[0.0]]]] :: float[]
                , (a_no - 1) * i_stride[1]
                ) 
                as a_slice_sample
              from generate_series(1, v_cnt_overlap_heigh) tb_a(a_no)
            ),
            cte_slice_max_len as 
            (
              select 
                max(array_length(a_slice_sample, 3)) as a_slice_max_len   -- array_length(a_slice_sample, -2)
              from cte_slice_sample
            )
            select 
              (sm_sc.fa_mx_sum
              (
                sm_sc.fv_bpad     -- sm_sc.fv_rpad
                (
                  a_slice_sample
                , array[[[[0.0]]]] :: float[]
                , a_slice_max_len - array_length(a_slice_sample, 3)     -- array_length(a_slice_sample, -2)
                )
              ))[ : ][ : ][ : v_indepdt_len_heigh][ : ]   -- -2 切片
            from cte_slice_sample, cte_slice_max_len
          );
      end if;
    
      return 
        v_strided_dloss_ddepdt_heigh_destrided    -- 去除 pad
          [ : ]
          [ : ]
          [i_padding[1] + 1 : i_padding[1] + array_length(i_indepdt, 3)]         -- array_length(i_indepdt, -2)
          [i_padding[3] + 1 : i_padding[3] + array_length(i_indepdt, 4)]         -- array_length(i_indepdt, -1)
      ;
    
    end if;
  end if;
end
$$
language plpgsql stable
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_pool_max_dloss_dindepdt_ex
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

-- select sm_sc.fv_d_pool_max_dloss_dindepdt_ex
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

-- select sm_sc.fv_d_pool_max_dloss_dindepdt_ex
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

-- select sm_sc.fv_d_pool_max_dloss_dindepdt_ex
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