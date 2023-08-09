-- -- 参考
-- --   https://blog.csdn.net/weixin_44538273/article/details/86671655
-- --   https://www.zhihu.com/question/23765351
-- --   https://zhuanlan.zhihu.com/p/25723112


-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_standlize_mx_softmax_dloss_dindepdt(float[], float[], float[]);
create or replace function sm_sc.fv_d_standlize_mx_softmax_dloss_dindepdt
(
  i_y                  float[]                  ,                     -- softmax 输出的归一化概率预测值。i_x, i_y 可以有一个为 null 值
  i_dloss_dy           float[]                  ,                     -- 此入参传入 dloss/dindepdt, 用于 softmax 直接求取 dloss/ddepdt
  i_x                  float[]    default null                        -- softmax 算子的输入，来自上一层算子的输出
)
returns float[]     -- 输出列序与 i_x 枚举值 one_hot 序一致
as
$$
declare 
  v_y_length_1d   int   :=  array_length(i_y, 1);
begin
  -- 审计维度
  if array_ndims(i_x) <> 2
    or array_ndims(i_y) <> 2
  then 
    raise exception 'array_ndims should be 2';
  end if;

  if i_y is null
  then
    i_y := sm_sc.fv_standlize_mx_softmax(i_x);
  end if;
  
  return
    sm_sc.fv_mx_ele_1d_2_2d
    (
      sm_sc.fv_d_standlize_softmax_dloss_dindepdt
      (
        array[sm_sc.fv_mx_ele_2d_2_1d(i_y)], 
        array[sm_sc.fv_mx_ele_2d_2_1d(i_dloss_dy)]
      )
      , v_y_length_1d
    ) 
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_standlize_mx_softmax_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_softmax(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]),
--     (-` array[array[0.0 :: float, 1.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[1.0 :: float, 0.0]] /` sm_sc.fv_standlize_mx_softmax(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]])),
--     array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]
--   );