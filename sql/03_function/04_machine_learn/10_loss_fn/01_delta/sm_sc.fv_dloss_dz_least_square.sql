-- drop function if exists sm_sc.fv_dloss_dz_least_square(float[], float[]);
create or replace function sm_sc.fv_dloss_dz_least_square
(
  i_z               float[]          ,      -- 训练输出预测值
  i_true            float[]                 -- 训练集真实值
)
returns float[]
as
$$
declare 
  v_tmp   float[] ;
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计维度长度约束与对齐
    if  -- --  array_ndims(i_z) > 4 
        -- -- or array_ndims(i_true) > 4 
        -- -- or 
        array_dims(i_z) <> array_dims(i_true)
    then
      raise exception 'no method for such length!  Z_Dims: %; True_Dims: %;', array_dims(i_z), array_dims(i_true);
    end if;
  end if;

  v_tmp := i_z -` i_true;
  return 
    v_tmp *` sqrt(cardinality(i_z) :: float / (|@+| (v_tmp ^` 2.0))) :: float
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_dloss_dz_least_square(array[array[1, 2, 3], array[2, 3, 4]], array[array[1.1, 2.1, 3.2], array[2.2, 3.3, 4.2]])