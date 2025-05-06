drop type if exists sm_sc.__typ_array_ex;
create type sm_sc.__typ_array_ex 
as
(
  m_array    float[]
);

-- drop function if exists sm_sc.fv_cast_array_ex;
create or replace function sm_sc.fv_cast_array_ex 
(
  i_array     float[]    
)
returns sm_sc.__typ_array_ex
as
$$
declare -- here
  v_rtn     sm_sc.__typ_array_ex;
begin
  v_rtn.m_array = i_array;
  return v_rtn;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_cast_array_ex(array[1.2, 2.4])
-- select sm_sc.fv_cast_array_ex(array[array[1.2, 2.4], array[3.6, 4.8]])
-- ---------------------------
drop cast if exists (float[] as sm_sc.__typ_array_ex);
create cast (float[] as sm_sc.__typ_array_ex)   
with function sm_sc.fv_cast_array_ex(float[])
as implicit;