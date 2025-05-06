-- leaky_relu: i_depdt = case when i_indepdt >= 0.0 then i_indepdt else i_a * i_indepdt end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_leaky_relu_asso(float, float);
create or replace function sm_sc.fv_d_leaky_relu_asso
(
  i_indepdt                float,
  i_asso_value       float    -- 
)
returns float
as
$$
-- declare
begin
  return case when i_indepdt > 0.0 then 1.0 :: float else i_asso_value end;
end
$$
language plpgsql stable;


-- select sm_sc.fv_d_leaky_relu_asso(-2.0 :: float, 0.1)
-- select sm_sc.fv_d_leaky_relu_asso(0.0 :: float, 0.2)
-- select sm_sc.fv_d_leaky_relu_asso(1.0 :: float, 0.3)