
-- -- https://blog.csdn.net/weixin_38451800/article/details/86514415
-- -- https://zhuanlan.zhihu.com/p/77327349 代码有误：predict_var += v_std**2 改成 predict_var += v_std
-- -- https://zhuanlan.zhihu.com/p/73236905
-- -- 
-- -- Q，R分别对应过程噪声的协方差和观测误差的协方差，这两个量是估计出来的。
-- -- P应该是初始的状态协方差，表示初值与真值的不确定性，
-- drop function if exists sm_sc.fv_sgn_kalman(float[], float, float, float);
create or replace function sm_sc.fv_sgn_kalman
(
  i_wave                    float[],
  i_process_q_covar         float  ,  
  i_measure_r_covar         float  , 
  i_initial_p_covar         float  default null
)
returns float[]    -- 比 i_wave 尾部多一个元素，做为线性预测值（不适合非线性）
as
$$

-- -- declare 
-- --   v_sum_predict_var   float   :=   0.0                     ;
-- --   v_cur_no            int                                           ;
-- --   v_cur_last_ele      float   :=   i_wave[1]               ;
-- --   v_cur_mid_ele       float   :=   v_cur_last_ele          ;
-- --   v_cur_ele           float                                ;
-- --   v_cur_last_p_covar  float   :=   coalesce(i_initial_p_covar, i_measure_r_covar)       ;
-- --   v_cur_mid_p_covar   float                                ;
-- --   v_cur_p_covar       float                                ;
-- --   v_cur_predict_share float                                ;
-- -- 
-- -- begin
-- --   for v_cur_no in 1 .. array_length(i_wave, 1)
-- --   loop
-- --     v_cur_mid_ele := v_cur_last_ele;
-- --     v_cur_mid_p_covar := v_cur_last_p_covar + i_process_q_covar;
-- --     v_cur_predict_share := v_cur_mid_p_covar / (v_cur_mid_p_covar + i_measure_r_covar);
-- --     v_cur_ele := v_cur_mid_ele + (v_cur_predict_share * (i_wave[v_cur_no] - v_cur_mid_ele));
-- --     v_cur_p_covar := (1.0 :: float- v_cur_predict_share) * v_cur_mid_p_covar;
-- --   
-- --     i_wave[v_cur_no] := v_cur_ele;
-- --   
-- --     v_cur_last_ele := v_cur_ele;
-- --     v_cur_last_p_covar  = v_cur_p_covar;
-- --   end loop;
-- -- 
-- --   return i_wave;
-- -- end;

declare 
  v_predict_var       float  :=   coalesce(i_initial_p_covar, i_measure_r_covar)        ;
  v_cur_no            int                             ;
  v_cur_ele           float  :=   i_wave[1]  ;

begin
  for v_cur_no in 2 .. array_length(i_wave, 1)
  loop
	v_predict_var := v_predict_var + i_process_q_covar;
	v_cur_ele := (v_cur_ele * i_measure_r_covar / (i_measure_r_covar + v_predict_var)) + (i_wave[v_cur_no] * v_predict_var / (i_measure_r_covar + v_predict_var));
	v_predict_var := (v_predict_var * i_measure_r_covar) / (v_predict_var + i_measure_r_covar);
	i_wave[v_cur_no] = v_cur_ele;
  end loop;

  -- 多预测一个轨迹点，假定轨迹在最近几个(7)采样点(要求采样足够密集)局部瞬间趋近于线性移动（不适合非线性），线性回归？
  v_cur_no := array_length(i_wave, 1);
  v_cur_ele := 
  (
    select avg(a_ele)
    from
    (
      select ((2 * i_wave[v_cur_no]) - (1 * i_wave[v_cur_no - 1])) as a_ele
      union all
      select ((3 * i_wave[v_cur_no - 1]) - (2 * i_wave[v_cur_no - 2])) as a_ele
      union all
      select ((4 * i_wave[v_cur_no - 2]) - (3 * i_wave[v_cur_no - 3])) as a_ele
      union all
      select ((5 * i_wave[v_cur_no - 3]) - (4 * i_wave[v_cur_no - 4])) as a_ele
      union all
      select ((6 * i_wave[v_cur_no - 4]) - (5 * i_wave[v_cur_no - 5])) as a_ele
      union all
      select ((7 * i_wave[v_cur_no - 5]) - (6 * i_wave[v_cur_no - 6])) as a_ele
      union all
      select ((8 * i_wave[v_cur_no - 6]) - (7 * i_wave[v_cur_no - 7])) as a_ele
    ) t
  );
  return i_wave || v_cur_ele;
end;

$$
language plpgsql stable
parallel safe;

-- -- create extension tablefunc;
-- with 
-- -- 构造精确序列
-- cte_ods as
-- (
--   select 
--     row_number() over() as row_no,
--     a_x,
--     10 * sin(a_x) :: float as ods_ele
--   from generate_series(0.0, pi() :: decimal, (pi() / 100) :: decimal) tb_a(a_x)
-- )
-- ,
-- -- 构造误差序列
-- cte_test as
-- (
--   select
--     row_no,
--     ods_ele + normal_rand(1, 0.0 :: float, 0.5 :: float) :: float as test_ele   -- 假定观测误差标准差 0.5
--   from cte_ods
-- )
-- ,
-- -- 执行卡尔曼滤波
-- cte_predict as
-- (
--   select 
--     sm_sc.fv_sgn_kalman
--     (
--       array_agg(test_ele order by row_no),              
--       0.4 * 0.4                          ,      -- 假定过程误差标准差 0.4
--       0.5 * 0.5                          ,      -- 假定观测误差标准差 0.5
--       0.5 * 0.5
--     ) as predict_arr
--   from cte_test
-- )
-- -- 对比结果
-- select 
--   a_x, a_ods_ele, a_test_ele, a_predict_ele, abs(a_test_ele - a_ods_ele) - abs(a_predict_ele - a_ods_ele)
--   -- sum(abs(a_test_ele - a_ods_ele) - abs(a_predict_ele - a_ods_ele))
-- from unnest
-- (
--   (select array_agg(a_x) from cte_ods),
--   (select array_agg(ods_ele) from cte_ods),
--   (select array_agg(test_ele) from cte_test),
--   (select predict_arr from cte_predict)
-- ) tb_a(a_x, a_ods_ele, a_test_ele, a_predict_ele)









