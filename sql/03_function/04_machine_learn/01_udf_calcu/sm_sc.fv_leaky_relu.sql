-- leaky_relu: i_depdt = case when i_indepdt >= 0.0 then i_indepdt else i_a * i_indepdt end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_leaky_relu(float, float);
create or replace function sm_sc.fv_leaky_relu
(
  i_indepdt                float,
  i_asso_value       float    -- 
)
returns float
as
$$
-- declare
begin
  return case when i_indepdt >= 0.0 then i_indepdt else i_asso_value * i_indepdt end;
end
$$
language plpgsql stable;

-- select sm_sc.fv_leaky_relu(-2.0 :: float, 0.5 :: float)
-- select sm_sc.fv_leaky_relu(-2.0 :: float, 0.3)
-- select sm_sc.fv_leaky_relu(-2.0 :: float, 0.2)
-- select sm_sc.fv_leaky_relu(-2.0 :: float, 0.1)
-- select sm_sc.fv_leaky_relu(0.0 :: float, 0.5 :: float)
-- select sm_sc.fv_leaky_relu(1.0 :: float, 0.3)
-- select sm_sc.fv_leaky_relu(2.0 :: float, 0.2)
-- select sm_sc.fv_leaky_relu(3.0, 0.1)
