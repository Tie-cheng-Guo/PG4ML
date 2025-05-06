-- -- 幂法/改进幂法/反幂法
-- -- https://wenku.baidu.com/view/c52758e31fb91a37f111f18583d049649b660ea5.html  第九章矩阵特征值与特征向量计算方法

-- drop function if exists sm_sc.fv_mx_max_abs_evd_value(float[][]);
create or replace function sm_sc.fv_mx_max_abs_evd_value
(
  in i_matrix float[][]
)
   returns float
as
$$
-- declare here
declare 
  v_loop_cnt_01             int                   :=   0;
  v_dims_len                  int                   :=   array_length(i_matrix, 1) ;                 -- 方阵维数
								    
  v_cur_array_x             float[]       :=   array_fill(2.0 :: float, array[v_dims_len]); 
  v_cur_eigenvalue          float;
  v_last_cur_eigenvalue     float;
-- declare v_loop_fasten_factor      float         :=   0.0;  -- -- 迭代加速因子  -- 机制未知，待研究验证
-- declare v_loop_fasten_factor_2nd  float         :=   0.0;  -- -- 迭代加速初始因子

begin


  if v_dims_len = array_length(i_matrix, 2)
    -- and /*待处理欠秩、除数为零*/
  then
    while v_loop_cnt_01 < 100
      and (v_last_cur_eigenvalue is null or abs(v_cur_eigenvalue - v_last_cur_eigenvalue) >= 0.001) or v_loop_cnt_01 < 10
    loop 
      v_loop_cnt_01 = v_loop_cnt_01 + 1;
      v_last_cur_eigenvalue = v_cur_eigenvalue;
      -- if v_loop_cnt_01 = 2                                 -- --
      -- then                                                   -- --
      --   v_loop_fasten_factor_2nd = v_cur_eigenvalue;     -- --
      -- end if;                                                -- --


      -- v_cur_eigenvalue = (select max(v_cur_array_x[cur]) + v_loop_fasten_factor from generate_series(1, v_dims_len) cur);  -- --
      v_cur_eigenvalue = (select v_cur_array_x[cur] from generate_series(1, v_dims_len) cur order by abs(v_cur_array_x[cur]) limit 1);
      if abs(v_cur_eigenvalue) <= 0.0001
      then
        exit;
      end if;

      -- v_loop_fasten_factor = (v_cur_eigenvalue + v_loop_fasten_factor_2nd) / 2.0; -- --       
      v_cur_array_x = sm_sc.fv_mx_ele_2d_2_1d(|^~| (i_matrix |**| (|^~| (array[v_cur_array_x] /` v_cur_eigenvalue))));
      -- v_cur_array_x = sm_sc.fv_mx_ele_2d_2_1d(|^~| ((i_matrix -` sm_sc.fv_eye_unit(v_dims_len, v_loop_fasten_factor)) |**| (|^~| (v_cur_array_x /` v_cur_eigenvalue))));  -- --
    end loop;

    -- return case when abs(v_cur_eigenvalue - v_last_cur_eigenvalue) >= 0.001 then null else v_cur_eigenvalue + v_loop_fasten_factor end;  -- --
    return case when abs(v_cur_eigenvalue - v_last_cur_eigenvalue) >= 0.001 then null else v_cur_eigenvalue end;

  else
    return null;
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_max_abs_evd_value(array[[1,2],[3,4]])
-- select sm_sc.fv_mx_max_abs_evd_value(array[[1,2,3],[0,8,9],[4,5,6]])
-- select sm_sc.fv_mx_max_abs_evd_value(array[[1,2,3,4],[0,8,9,10],[4,5,6,7],[5,7,2,10]])
-- select sm_sc.fv_mx_max_abs_evd_value(array[[0,1,2],[1,1,4],[2,-1,0]])

-- select sm_sc.fv_mx_max_abs_evd_value(array[[2,3],[1,7]])
-- select sm_sc.fv_mx_max_abs_evd_value(array[[-2.0000,1.0000],[1.5000,-0.5000]])
-- truncate table t_tmp_debug_info
-- select * from t_tmp_debug_info