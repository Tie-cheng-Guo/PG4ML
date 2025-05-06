-- drop function if exists sm_sc.fv_lambda_dloss_dz(varchar(32), float[], float[]);
create or replace function sm_sc.fv_lambda_dloss_dz
(
  i_loss_fn_type    varchar(32)                     -- 损失函数类型说明，参看字典表 enum_name = 'loss_fn_type'
, i_nn_depdt        float[]                         -- 训练输出预测值
, i_true            float[]                         -- 训练集真实值
, i_node_type       varchar(64)                     -- output_01, output_02, output_03, output_04, ...
)
returns float[]
as
$$
-- declare 
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计维度长度约束与对齐
    if array_ndims(i_nn_depdt) > 4 
      or array_ndims(i_true) > 4 
      or array_length(i_nn_depdt, 1) <> array_length(i_true, 1) 
      or array_length(i_nn_depdt, 2) <> array_length(i_true, 2)
      or array_length(i_nn_depdt, 3) <> array_length(i_true, 3)
      or array_length(i_nn_depdt, 4) <> array_length(i_true, 4)
    then
      raise exception 'no method for such length!  Z_Dims: %; True_Dims: %;', array_dims(i_nn_depdt), array_dims(i_true);
    end if;
  end if;

  if i_loss_fn_type = '101'
  then 
    return 
      sm_sc.fv_dloss_dz_least_square(i_nn_depdt, i_true)
    ;
  elsif i_loss_fn_type = '201'
  then 
    return 
      sm_sc.fv_dloss_dz_cross_entropy(i_nn_depdt, i_true)
    ;
  elsif i_loss_fn_type = '202'
  then 
    return 
      sm_sc.fv_dloss_dz_cross_entropy(i_nn_depdt, i_true) /` array_length(i_nn_depdt, 2) :: float
    ;
  elsif i_loss_fn_type = '203'
  then 
    if i_node_type = 'output_01'
    then 
      return 
        sm_sc.fv_dloss_dz_cross_entropy_true_onehot_idx(i_nn_depdt, i_true)
      ;
    else 
      return null; 
    end if;
  elsif i_loss_fn_type = '301'
  then 
    return 
      sm_sc.fv_dloss_dz_l1(i_nn_depdt, i_true)
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_lambda_dloss_dz('101', array[array[1, 2, 3], array[2, 3, 4]], array[array[1.1, 2.1, 3.2], array[2.2, 3.3, 4.2]])