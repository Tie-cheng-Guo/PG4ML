-- drop function if exists sm_sc.fv_dloss_dz(int, float[], float[]);
create or replace function sm_sc.fv_dloss_dz
(
  i_loss_fn_type    int                       ,      -- 损失函数类型说明，参看字典表 enum_name = 'loss_fn_type'
  i_z               float[]          ,      -- 训练输出预测值
  i_true            float[]                 -- 训练集真实值
)
returns float[]
as
$$
-- declare 
begin
  -- 审计维度长度约束与对齐
  if array_ndims(i_z) <> 2 
    or array_ndims(i_true) <> 2 
    or array_length(i_z, 1) <> array_length(i_true, 1) 
    or array_length(i_z, 2) <> array_length(i_true, 2)
  then
    return null; raise notice 'no method for such length!  Y_Ndim: %; Y_len_1: %; Y_len_2: %; Z_Ndim: %; Z_len_1: %; Z_len_2: %;', array_ndims(i_z), array_length(i_z, 1), array_length(i_z, 2), array_ndims(i_true), array_length(i_true, 1), array_length(i_true, 2);
  end if;

  return 
    case i_loss_fn_type
      when 1
        then (i_z -` i_true) /` sqrt(array_length(i_z, 1) :: float)
      when 2
        then -` i_true /` sm_sc.fv_ele_replace((i_z *` array_length(i_z, 1) :: float) :: float[], array[0.0 :: float], 1e-128 :: float)   -- esp: 1e-128 :: float
    end 
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_dloss_dz(1, array[array[1, 2, 3], array[2, 3, 4]], array[array[1.1, 2.1, 3.2], array[2.2, 3.3, 4.2]])