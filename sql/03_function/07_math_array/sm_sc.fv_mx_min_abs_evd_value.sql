-- -- 幂法/改进幂法/反幂法
-- -- https://wenku.baidu.com/view/c52758e31fb91a37f111f18583d049649b660ea5.html  第九章矩阵特征值与特征向量计算方法

-- drop function if exists sm_sc.fv_mx_min_abs_evd_value(float[][]);
create or replace function sm_sc.fv_mx_min_abs_evd_value
(
  in i_matrix float[][]
)
   returns float
as
$$
-- declare here

begin
  return 1.0 :: float/ sm_sc.fv_mx_max_abs_evd_value(sm_sc.fv_mx_inversion(i_matrix));
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_min_abs_evd_value(array[[1,2],[3,4]])
-- select sm_sc.fv_mx_min_abs_evd_value(array[[1,2,3],[0,8,9],[4,5,6]])
-- select sm_sc.fv_mx_min_abs_evd_value(array[[1,2,3,4],[0,8,9,10],[4,5,6,7],[5,7,2,10]])
-- select sm_sc.fv_mx_min_abs_evd_value(array[[0,1,2],[1,1,4],[2,-1,0]])

-- select sm_sc.fv_mx_min_abs_evd_value(array[[2,3],[1,7]])
-- truncate table t_tmp_debug_info
-- select * from t_tmp_debug_info