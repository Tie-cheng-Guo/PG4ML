-- -- 参考
-- --   https://blog.csdn.net/weixin_44538273/article/details/86671655
-- --   https://www.zhihu.com/question/23765351
-- --   https://zhuanlan.zhihu.com/p/25723112

-- -- 只支持入参为二维单行或单列数组
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_standlize_softmax_dloss_dindepdt(float[], float[], float[]);
create or replace function sm_sc.fv_d_standlize_softmax_dloss_dindepdt
(
  i_depdt                  float[]                 ,                     -- softmax 输出的归一化概率预测值。i_indepdt, i_depdt 可以有一个为 null 值
  i_dloss_ddepdt           float[]                 ,                     -- 此入参传入 dloss/dindepdt, 用于 softmax 直接求取 dloss/ddepdt
  i_indepdt                  float[]  default null                         -- softmax 算子的输入，来自上一层算子的输出
)
returns float[]     -- 输出列序与 i_indepdt 枚举值 one_hot 序一致
as
$$
declare 
  v_y         float[];
  v_dloss_dindepdt  float[][];

begin
  -- 审计维度
  if array_ndims(i_indepdt) <> 2 or array_length(i_indepdt, 1) <> 1 and array_length(i_indepdt, 2) <> 1
    or array_ndims(i_depdt) <> 2 or array_length(i_depdt, 1) <> 1 and array_length(i_depdt, 2) <> 1
    or array_dims(i_dloss_ddepdt) <> array_dims(i_indepdt) and array_dims(i_dloss_ddepdt) <> array_dims(i_depdt)
  then 
    raise exception 'array_ndims and (array_length(, 1) or array_length(, 2)) should be 2 and 1';
  end if;

  if i_depdt is null
  then
    i_depdt := sm_sc.fv_standlize_mx_softmax(i_indepdt);
  end if;

  if array_length(i_depdt, 2) = 1
  then
    v_y := |^~| i_depdt;
  else
    v_y := i_depdt;
    i_depdt := |^~| i_depdt;
  end if;

  -- -- -- i_depdt |**| v_y 是对称矩阵，开销可优化减半
  v_dloss_dindepdt := (sm_sc.fv_eye(0.0 :: float, variadic sm_sc.fv_mx_ele_2d_2_1d(v_y)) -` (i_depdt |**| v_y))  *` i_dloss_ddepdt; -- ~=` 8

  if array_length(i_dloss_ddepdt, 2) = 1
  then
    return |^~| (sm_sc.fv_aggr_slice_sum_py(v_dloss_dindepdt, array[array_length(v_dloss_dindepdt, 1), 1]));
  else
    return |^~| (sm_sc.fv_aggr_slice_sum_py(v_dloss_dindepdt, array[1, array_length(v_dloss_dindepdt, 2)]));
  end if;
  
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_standlize_softmax_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_softmax(array[array[1, 2, 3, 4, 5]]),
--     -` array[array[0.0 :: float, 0.0 :: float, 0.0 :: float, 0.0 :: float, 1.0]] /` sm_sc.fv_standlize_mx_softmax(array[array[1, 2, 3, 4, 5]]),
--     array[array[1, 2, 3, 4, 5]]
--   );

-- select sm_sc.fv_d_standlize_softmax_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_softmax(array[array[1], array[2], array[3], array[4], array[5]]),
--     -` array[array[0.0 :: float], array[0.0 :: float], array[0.0 :: float], array[0.0 :: float], array[1.0 :: float]] /` sm_sc.fv_standlize_mx_softmax(array[array[1], array[2], array[3], array[4], array[5]]),
--     array[array[1], array[2], array[3], array[4], array[5]]
--   );