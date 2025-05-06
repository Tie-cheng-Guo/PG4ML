-- 参考 https://zhuanlan.zhihu.com/p/35709485

-- drop function if exists sm_sc.fv_lambda_loss(varchar(32), float[], float[], float[], float[], float[], float[], float[], float[]);
create or replace function sm_sc.fv_lambda_loss
(
  i_loss_fn_type    varchar(32)                                       -- 损失函数类型说明，参看字典表 enum_name = 'loss_fn_type'
, i_nn_depdt_01     float[]                                           -- 训练输出预测值 01
, i_true_01         float[]                                           -- 训练集真实值 01
, i_nn_depdt_02     float[]          default null                     -- 训练输出预测值 01
, i_true_02         float[]          default null                     -- 训练集真实值 01
, i_nn_depdt_03     float[]          default null                     -- 训练输出预测值 01
, i_true_03         float[]          default null                     -- 训练集真实值 01
, i_nn_depdt_04     float[]          default null                     -- 训练输出预测值 01
, i_true_04         float[]          default null                     -- 训练集真实值 01
)
returns float
as
$$
-- declare
  
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计维度长度约束与对齐
    if array_ndims(i_nn_depdt_01) > 4 
      or array_ndims(i_true_01) > 4 
      or array_dims(i_nn_depdt_01, 1) <> array_dims(i_true_01, 1) 
    then
      raise exception 'no method for such length!  Y_Dims: %; Z_Dims: %;', array_dims(i_nn_depdt_01), array_dims(i_true_01);
    end if;
  end if;
  
  if i_loss_fn_type = '101'
  then 
    return 
      sm_sc.fv_loss_least_square(i_nn_depdt_01, i_true_01)
    ;
  elsif i_loss_fn_type = '201'
  then 
    return 
      sm_sc.fv_loss_cross_entropy(i_nn_depdt_01, i_true_01)
    ;
  elsif i_loss_fn_type = '202'
  then 
    return 
      sm_sc.fv_loss_cross_entropy(i_nn_depdt_01, i_true_01) / (array_length(i_nn_depdt_01, 2)) :: float
    ;
  elsif i_loss_fn_type = '203'
  then 
    return 
      sm_sc.fv_loss_cross_entropy_true_onehot_idx
      (
        i_nn_depdt_01
      , i_true_01
      -- -- , i_nn_depdt_02
      -- , i_true_02
      )
    ;
  elsif i_loss_fn_type = '301'
  then 
    return 
      sm_sc.fv_loss_l1
      (
        i_nn_depdt_01
      , i_true_01
      -- -- , i_nn_depdt_02
      -- , i_true_02
      )
    ;
  else 
    raise exception 'unsupport loss fn type.';
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_lambda_loss('201', array[[1.0, 2, 3], [2, 3, 4]], array[[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]])
-- select sm_sc.fv_lambda_loss('201', array[[[1.0, 2, 3], [2, 3, 4]], [[1, 2, 3], [2, 3, 4]]], array[[[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]], [[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]]])