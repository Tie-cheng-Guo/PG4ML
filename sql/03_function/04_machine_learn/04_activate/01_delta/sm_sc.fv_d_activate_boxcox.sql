-- drop function if exists sm_sc.fv_d_activate_boxcox(float[], float);
create or replace function sm_sc.fv_d_activate_boxcox
(
  i_indepdt            float[]        ,
  i_lambda           float    -- 
)
returns float[]
as
$$
-- declare -- here
begin
  -- 审计：不支持负值
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if true = any(i_indepdt <=` 0.0 :: float)
    then 
      raise exception 'unsupport negative value in i_indepdt.';
    end if;
  end if;
  
  if array_length(i_indepdt, array_ndims(i_indepdt)) is null
  then 
    return i_indepdt;
  elsif array_ndims(i_indepdt) <= 6
  then 
    if i_lambda = 0
    then 
      return 1.0 :: float /` i_indepdt;
    else 
      return i_indepdt ^` (i_lambda :: float - 1.0);
    end if;
  else
    raise exception 'no method for such length!  Dim: %;', array_dims(i_indepdt);
  end if;
end
$$
language plpgsql stable
cost 100;
-- select sm_sc.fv_d_activate_boxcox(array[[1.0 :: float, 2.0], [3.0, 4.0]], 0.2)
-- select sm_sc.fv_d_activate_boxcox(array[[[1.0 :: float, 2.0], [3.0, 4.0]]], 0.2)
-- select sm_sc.fv_d_activate_boxcox(array[[[[1.0 :: float, 2.0], [3.0, 4.0]]]], 0.2)
-- select sm_sc.fv_d_activate_boxcox(array[1.5, 2.5, 3.5], 0.2)
-- select sm_sc.fv_d_activate_boxcox(array[]::float[], 0.2)
-- select sm_sc.fv_d_activate_boxcox(array[array[], array []]::float[], 0.3)