-- drop function if exists sm_sc.fv_d_activate_sigmoid(float[], float[]);
create or replace function sm_sc.fv_d_activate_sigmoid
(
  i_indepdt         float[], 
  i_depdt         float[]   default null
)
returns float[]
as
$$
declare -- here
  v_tmp   float[];
begin
  -- 审计维度
  if array_length(i_indepdt, array_ndims(i_indepdt)) is null and array_length(i_depdt, array_ndims(i_depdt)) is null
  then 
    return null;
  end if;
  
  if i_depdt is null
  then 
    i_depdt := sm_sc.fv_activate_sigmoid(i_indepdt);
  end if;
  
  return i_depdt *` (1.0 :: float-` i_depdt);

  -- -- -- 以下虽然算法复杂度较优，但不方便处理溢出
  -- -- if i_depdt is not null
  -- -- then
  -- --   return i_depdt *` (1.0 :: float-` i_depdt);
  -- -- else
  -- --   -- -- -- -- -- 截断处理溢出更不合理
  -- --   -- -- -- -- v_tmp := sm_sc.fv_nullif(^` ((((-` i_indepdt) +` sm_sc.fv_ele_replace(((-` i_indepdt) <` -1.49e3 :: float) :: int[] :: float[], array[1.0 :: float], '-inf' :: float))) /` 2.0 :: float), 0.0 :: float);
  -- --   v_tmp := sm_sc.fv_nullif(^` (i_indepdt /` 2.0 :: float), 0.0 :: float);
  -- --   return 1.0 :: float /` ((v_tmp +` (1.0 :: float /` v_tmp)) ^` 2.0 :: float);
  -- -- end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_d_activate_sigmoid(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- select sm_sc.fv_d_activate_sigmoid(array[[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- select sm_sc.fv_d_activate_sigmoid(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- select sm_sc.fv_d_activate_sigmoid(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_d_activate_sigmoid(array[]::float[])
-- select sm_sc.fv_d_activate_sigmoid(array[array[], array []]::float[])