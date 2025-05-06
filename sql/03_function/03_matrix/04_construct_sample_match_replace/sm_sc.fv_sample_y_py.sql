-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_sample_y_py(float[], int, int, int4range, float);
create or replace function sm_sc.fv_sample_y_py   -- 3 个参数
(
  i_array          float[]           
, i_period         int                                               -- 采样周期
, i_window_len     int                                               -- 1d 采样窗口的长度或 2d 采样的窗口宽度。 null 值表示不约束窗口宽度
, i_simp_range     int4range                                         -- 越界填充，类似于升采样，周期横向插入 i_fill_values 元素稀释原矩阵
                                                                     -- 如果下界小于窗口上边界，则每组样本上方填充 i_fill_values; 如果上界也小于窗口上边界，那么该 sim_range 和原矩阵序号上下界无交集，抽样将全部是填充元素
                                                                     -- 如果上界大于窗口下边界，那么下方填充 i_fill_values; 如果下界也大于 窗口下边界，那么该 sim_range 和原矩阵序号上下界无交集，抽样将全部是填充元素
                                                                     -- 其中超出上下界的数值代表 i_fill_values 重复填充次数，例如 -1 代表左侧重复填充 1 - (-1) = 2 次
, i_fill_value     float                                             -- 如果用 default 值，那么参数的伪类型不易支持，那么分为两个入参不同的重载函数
)
returns float[]
as
$$
declare
  v_range        int4range   := int4range(1, i_window_len, '[]') * i_simp_range;
  v_cnt_window   int         := ((array_length(i_array, 1) - upper(i_simp_range) + 1) / i_period)  + 1;  -- array_length(i_array, y)
begin 
  if array_ndims(i_array) = 1
  then 
    return 
      sm_sc.fv_opr_reshape_py
      (
        (sm_sc.fv_concat_x                                                              
        (
          sm_sc.fv_concat_x                                                             
          (
            array_fill
            (
              i_fill_value
            , array[v_cnt_window, least(i_window_len, lower(i_simp_range) - 1)]
            )                                                                           
          , (sm_sc.fv_strided_float_py
            (
              i_array
            , array
              [
                v_cnt_window    --  采样维度下，窗口滑动次数                            
              , upper(i_simp_range) - 1
              ]
            , array
              [
                i_period
              , 1
              ]
            ))[ : ][lower(v_range) : (upper(v_range) - 1)]                              
          )
        , array_fill
          (
            i_fill_value
          , array[v_cnt_window, greatest(0, i_window_len - upper(i_simp_range) + 1)]
          )                                                                             
        ))[ : ][ : i_window_len]
      , array
        [
          v_cnt_window                                                                  
          * 
          i_window_len                                                                  
        ]
      )
    ;
  elsif array_ndims(i_array) = 2
  then 
    return 
      sm_sc.fv_opr_reshape_py
      (
        (sm_sc.fv_concat_x                                                             
        (
          sm_sc.fv_concat_x                                                            
          (
            array_fill
            (
              i_fill_value
            , array[v_cnt_window, least(i_window_len, lower(i_simp_range) - 1), array_length(i_array, 2)]
            )                                 
          , (sm_sc.fv_strided_float_py
            (
              i_array
            , array
              [
                v_cnt_window    --  采样维度下，窗口滑动次数
              , upper(i_simp_range) - 1
              , array_length(i_array, 2)
              ]
            , array
              [
                i_period * array_length(i_array, 2)
              , array_length(i_array, 2)
              , 1
              ]
            ))[ : ][lower(v_range) : (upper(v_range) - 1)][ : ] 
          )
        , array_fill
          (
            i_fill_value
          , array[v_cnt_window, greatest(0, i_window_len - upper(i_simp_range) + 1), array_length(i_array, 2)]
          )                            
        ))[ : ][ : i_window_len][ : ]
      , array
        [
          v_cnt_window
          * 
          i_window_len
        , array_length(i_array, 2)
        ]
      )
    ;
  elsif array_ndims(i_array) = 3
  then 
    return 
      sm_sc.fv_opr_reshape_py
      (
        (sm_sc.fv_concat_x                                                              
        (
          sm_sc.fv_concat_x                                                             
          (
            array_fill
            (
              i_fill_value
            , array[v_cnt_window, least(i_window_len, lower(i_simp_range) - 1), array_length(i_array, 2), array_length(i_array, 3)]
            )                                 
          , (sm_sc.fv_strided_float_py
            (
              i_array
            , array
              [
                v_cnt_window    --  采样维度下，窗口滑动次数
              , upper(i_simp_range) - 1
              , array_length(i_array, 2)
              , array_length(i_array, 3)
              ]
            , array
              [
                i_period * array_length(i_array, 2) * array_length(i_array, 3)
              , array_length(i_array, 2) * array_length(i_array, 3)
              , array_length(i_array, 3)
              , 1
              ]
            ))[ : ][lower(v_range) : (upper(v_range) - 1)][ : ][ : ] 
          )
        , array_fill
          (
            i_fill_value
          , array[v_cnt_window, greatest(0, i_window_len - upper(i_simp_range) + 1), array_length(i_array, 2), array_length(i_array, 3)]
          )                            
        ))[ : ][ : i_window_len][ : ][ : ]
      , array
        [
          v_cnt_window                                                                  -- -- 
          * 
          i_window_len 
        , array_length(i_array, 2)
        , array_length(i_array, 3)
        ]
      )
    ;
  elsif array_ndims(i_array) = 4
  then   
    return 
      sm_sc.fv_opr_reshape_py
      (
        (sm_sc.fv_concat_x                                                    
        (
          sm_sc.fv_concat_x                                                    
          (
            array_fill
            (
              i_fill_value
            , array[v_cnt_window, least(i_window_len, lower(i_simp_range) - 1), array_length(i_array, 2), array_length(i_array, 3), array_length(i_array, 4)]
            )                                 
          , (sm_sc.fv_strided_float_py
            (
              i_array
            , array
              [
                v_cnt_window    --  采样维度下，窗口滑动次数
              , upper(i_simp_range) - 1
              , array_length(i_array, 2)
              , array_length(i_array, 3)
              , array_length(i_array, 4)
              ]
            , array
              [
                i_period * array_length(i_array, 2) * array_length(i_array, 3) * array_length(i_array, 4)
              , array_length(i_array, 2) * array_length(i_array, 3) * array_length(i_array, 4)
              , array_length(i_array, 3) * array_length(i_array, 4)
              , array_length(i_array, 4)
              , 1
              ]
            ))[ : ][lower(v_range) : (upper(v_range) - 1)][ : ][ : ][ : ]
          )
        , array_fill
          (
            i_fill_value
          , array[v_cnt_window, greatest(0, i_window_len - upper(i_simp_range) + 1), array_length(i_array, 2), array_length(i_array, 3), array_length(i_array, 4)]
          )          
        ))[ : ][ : i_window_len][ : ][ : ][ : ]
      , array
        [
          v_cnt_window                                                                  -- -- 
          * 
          i_window_len
        , array_length(i_array, 2)
        , array_length(i_array, 3)
        , array_length(i_array, 4)
        ]
      )
    ;
  end if;
end 
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7], 2, 3, int4range(1, 3, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7], 2, 2, int4range(1, 3, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7], 2, 5, int4range(1, 3, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7,8], 2, 5, int4range(2, 4, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7,8], 2, 4, int4range(2, 4, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7,8], 2, 3, int4range(2, 4, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7,8], 2, 2, int4range(2, 4, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[1,2,3,4,5,6,7,8], 2, 1, int4range(2, 4, '[]'), 0.0)
-- select sm_sc.fv_sample_y_py(array[[1,-1],[2,-2],[3,-3],[4,-4],[5,-5],[6,-6],[7,-7]], 2, int4range(1, 3, '[]'))

-- with cte_arr as 
-- (
--    select sm_sc.fv_new_rand(array[7,2]) as a_arr
-- )
-- select 
--   sm_sc.fv_sample_y_py(a_arr, 2, a_no, int4range(1, 3, '[]'), 0.0)
--   =
--   sm_sc.fv_concat_y(sm_sc.fv_concat_y(a_arr[1: 1 + a_no - 1], a_arr[3:3 + a_no - 1]), a_arr[5:5 + a_no - 1])
-- from cte_arr
--   , generate_series(1, 3) tb_a(a_no)

-- with cte_arr as 
-- (
--    select sm_sc.fv_new_rand(array[7,2,3]) as a_arr
-- )
-- select 
--   sm_sc.fv_sample_y_py(a_arr, 2, a_no, int4range(1, 3, '[]'), 0.0)
--   =
--   sm_sc.fv_concat_y(sm_sc.fv_concat_y(a_arr[1: 1 + a_no - 1], a_arr[3:3 + a_no - 1]), a_arr[5:5 + a_no - 1])
-- from cte_arr
--   , generate_series(1, 3) tb_a(a_no)

-- with cte_arr as 
-- (
--    select sm_sc.fv_new_rand(array[7,2,3,5]) as a_arr
-- )
-- select 
--   sm_sc.fv_sample_y_py(a_arr, 2, a_no, int4range(1, 3, '[]'), 0.0)
--   =
--   sm_sc.fv_concat_y(sm_sc.fv_concat_y(a_arr[1: 1 + a_no - 1], a_arr[3:3 + a_no - 1]), a_arr[5:5 + a_no - 1])
-- from cte_arr
--   , generate_series(1, 3) tb_a(a_no)
