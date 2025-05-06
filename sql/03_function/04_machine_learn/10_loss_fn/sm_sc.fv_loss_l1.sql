-- drop function if exists sm_sc.fv_loss_least_square(float[], float[]);
create or replace function sm_sc.fv_loss_l1
(
  i_z               float[]          ,      -- 训练输出预测值
  i_true            float[]                 -- 训练集真实值
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
    if  -- --  array_ndims(i_z) > 4 
        -- -- or array_ndims(i_true) > 4 
        -- -- or 
      array_dims(i_z, 1) <> array_dims(i_true, 1) 
    then
      raise exception 'no method for such length!  Y_Dims: %; Z_Dims: %;', array_dims(i_z), array_dims(i_true);
    end if;
  end if;
  
  if i_true is null or sm_sc.fv_aggr_slice_max(i_true) is null
  then 
    return 
      (sm_sc.fv_aggr_slice_sum_py(i_z) / array_length(i_z, 1) :: float) :: float
    ;
  else
    return 
      sm_sc.fv_aggr_slice_sum_py(i_z -` i_true) / array_length(i_z, 1)
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_loss_l1(array[[1.0, 2, 3], [2, 3, 4]], array[[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]])
-- select sm_sc.fv_loss_l1(array[[[1.0, 2, 3], [2, 3, 4]], [[1, 2, 3], [2, 3, 4]]], array[[[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]], [[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]]])