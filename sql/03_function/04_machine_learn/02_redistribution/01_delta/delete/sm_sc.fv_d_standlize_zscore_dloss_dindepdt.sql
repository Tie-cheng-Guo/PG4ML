
-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_standlize_zscore_dloss_dindepdt(float[], float[]);
create or replace function sm_sc.fv_d_standlize_zscore_dloss_dindepdt
(
  i_depdt                  float[]                 ,                     -- zscore 输出
  i_dloss_ddepdt           float[]                 ,                     -- 此入参传入 dloss/dindepdt, 用于 zscore 直接求取 dloss/ddepdt
  i_indepdt                  float[]                                       -- zscore 算子的输入，来自上一层算子的输出
)
returns float[]     -- 输出列序与 i_indepdt 枚举值 one_hot 序一致
as
$$
declare 
  v_len               int;
  -- v_y                 float[];
  -- -- v_dloss_dindepdt          float[][];
  v_stddev_samp       float;

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
    i_depdt := sm_sc.fv_standlize_mx_zscore(i_indepdt);
  end if;

  -- -- if array_length(i_depdt, 2) = 1
  -- -- then
  -- --   v_y := |^~| i_depdt;
  -- -- else
  -- --   v_y := i_depdt;
  -- --   i_depdt := |^~| i_depdt;
  -- -- end if;
  
  v_stddev_samp := sm_sc.fv_aggr_slice_stddev_samp(i_indepdt);
  v_len := case when array_length(i_depdt, 1) = 1 then array_length(i_depdt, 2) else array_length(i_depdt, 1) end;

  -- -- -- -- -- i_depdt |**| v_y 是对称矩阵
  -- -- v_dloss_dindepdt := ((((- 1.0 :: float/ (v_len * v_stddev_samp)) *` (i_depdt |**| v_y)) -` (1.0 :: float/ (v_stddev_samp * v_len))) +` sm_sc.fv_eye(1.0 :: float/ v_stddev_samp, variadic sm_sc.fv_mx_ele_2d_2_1d(v_y)))  *` i_dloss_ddepdt; -- ~=` 8
  -- -- return ((((- 1.0 :: float/ (v_len * v_stddev_samp)) *` (i_depdt ^` 2.0 :: float)) -` (1.0 :: float/ (v_stddev_samp * v_len))) +` i_depdt)  *` i_dloss_ddepdt; -- ~=` 8   -- 错的，1. 漏了 1.0 :: float/ v_stddev_samp； 2. i_depdt ^` 2.0 相比 i_depdt |**| v_y，有误差
  return ((((- 1.0 :: float/ (v_len * v_stddev_samp)) *` (i_depdt *` (|@+| i_depdt))) -` (1.0 :: float/ (v_stddev_samp * v_len))) +` (i_depdt +` ((v_len - 1.0 :: float) / v_stddev_samp)))  *` i_dloss_ddepdt; -- ~=` 8

  -- if array_length(i_dloss_ddepdt, 2) = 1
  -- then
  --   return |^~| (sm_sc.fv_aggr_slice_sum_py(v_dloss_dindepdt, array[array_length(v_dloss_dindepdt, 1), 1]));
  -- else
  --   return |^~| (sm_sc.fv_aggr_slice_sum_py(v_dloss_dindepdt, array[1, array_length(v_dloss_dindepdt, 2)]));
  -- end if;
  
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_standlize_zscore_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_zscore(array[array[1, 2, 3, 4, 5]]),
--     -` array[array[0.0 :: float, 0.0 :: float, 0.0 :: float, 0.0 :: float, 1.0]] /` sm_sc.fv_standlize_mx_zscore(array[array[1, 2, 3, 4, 5]]),
--     array[array[1, 2, 3, 4, 5]]
--   );

-- select sm_sc.fv_d_standlize_zscore_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_zscore(array[array[1], array[2], array[3], array[4], array[5]]),
--     -` array[array[0.0 :: float], array[0.0 :: float], array[0.0 :: float], array[0.0 :: float], array[1.0 :: float]] /` sm_sc.fv_standlize_mx_zscore(array[array[1], array[2], array[3], array[4], array[5]]),
--     array[array[1], array[2], array[3], array[4], array[5]]
--   );