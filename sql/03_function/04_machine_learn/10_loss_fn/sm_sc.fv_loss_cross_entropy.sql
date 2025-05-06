-- 参考 https://zhuanlan.zhihu.com/p/35709485

-- drop function if exists sm_sc.fv_loss_cross_entropy(float[], float[]);
create or replace function sm_sc.fv_loss_cross_entropy
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
 
  -- log(0.0)处理参考: https://blog.csdn.net/wekings/article/details/123578464
  return 
    - sm_sc.fv_aggr_slice_sum_py(i_true *` (^!` sm_sc.fv_ele_replace(i_z, array[0.0 :: float], 1.0e-128 :: float))) / array_length(i_z, 1) :: float  -- esp: 1e-323 :: float 此处323刚好不溢出，但进一步运算可能溢出
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_loss_cross_entropy(array[[1.0, 2, 3], [2, 3, 4]], array[[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]])
-- select sm_sc.fv_loss_cross_entropy(array[[[1.0, 2, 3], [2, 3, 4]], [[1, 2, 3], [2, 3, 4]]], array[[[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]], [[1.1, 2.1, 3.2], [2.2, 3.3, 4.2]]])