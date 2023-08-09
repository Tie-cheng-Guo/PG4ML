-- drop function if exists sm_sc.fv_d_activate_sigmoid(float[], float[]);
create or replace function sm_sc.fv_d_activate_sigmoid
(
  i_x         float[], 
  i_y         float[]   default null
)
returns float[]
as
$$
declare -- here
  v_tmp   float[];
begin
  -- 审计维度
  if array_length(i_x, array_ndims(i_x)) is null and array_length(i_y, array_ndims(i_y)) is null
  then 
    return null;
  end if;

  if i_y is not null
  then
    return i_y *` (1.0 :: float-` i_y);
  else
    v_tmp := sm_sc.fv_nullif(^` (i_x /` 2.0 :: float), 0.0 :: float);
    return 1.0 :: float/` ((v_tmp +` (1.0 :: float/` v_tmp)) ^` 2.0 :: float);
  end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_d_activate_sigmoid(array[array[1.0 :: float, -2.0], array[3.0, 4.0]])
-- select sm_sc.fv_d_activate_sigmoid(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_d_activate_sigmoid(array[]::float[])
-- select sm_sc.fv_d_activate_sigmoid(array[array[], array []]::float[])