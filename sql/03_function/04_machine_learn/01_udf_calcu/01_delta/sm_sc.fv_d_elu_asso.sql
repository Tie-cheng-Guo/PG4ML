-- elu: i_depdt = case when i_indepdt >= 0.0 then i_indepdt else i_a * (exp(i_indepdt) - 1.0 :: float) end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_elu_asso(float, float, float);
create or replace function sm_sc.fv_d_elu_asso
(
  i_indepdt                float,
  i_asso_value       float,    -- 
  i_depdt                float  default null    -- 可选参数，用于简化复杂度
)
returns float
as
$$
-- declare
begin
  if i_indepdt > 0.0
  then 
    return 1.0;
  else
    return case when i_depdt is not null then i_depdt + i_asso_value else i_asso_value * exp(i_indepdt) end;
  end if;
end
$$
language plpgsql stable;

-- select sm_sc.fv_d_elu_asso(-2.0 :: float, 0.5 :: float, sm_sc.fv_elu(-2.0 :: float, 0.5 :: float))
-- select sm_sc.fv_d_elu_asso(-2.0 :: float, 0.3, sm_sc.fv_elu(-2.0 :: float, 0.3))
-- select sm_sc.fv_d_elu_asso(-2.0 :: float, 0.2)
-- select sm_sc.fv_d_elu_asso(-2.0 :: float, 0.1)
-- select sm_sc.fv_d_elu_asso(0.0 :: float, 0.5 :: float)
-- select sm_sc.fv_d_elu_asso(1.0 :: float, 0.3)
-- select sm_sc.fv_d_elu_asso(2.0 :: float, 0.2, sm_sc.fv_elu(2.0 :: float, 0.2))
-- select sm_sc.fv_d_elu_asso(3.0, 0.1, sm_sc.fv_elu(3.0, 0.1))
-- select sm_sc.fv_d_elu_asso(2.0 :: float, 0.2)
-- select sm_sc.fv_d_elu_asso(3.0, 0.1)