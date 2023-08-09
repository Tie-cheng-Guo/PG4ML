-- elu: i_y = case when i_x >= 0.0 then i_x else i_a * (exp(i_x) - 1.0 :: float) end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_elu(float, float);
create or replace function sm_sc.fv_elu
(
  i_x                float,
  i_asso_value       float    -- 
)
returns float
as
$$
-- declare
begin
  return case when i_x >= 0.0 then i_x else i_asso_value * (exp(i_x) - 1.0 :: float) end;
end
$$
language plpgsql stable

-- select sm_sc.fv_elu(-2.0 :: float, 0.5 :: float)
-- select sm_sc.fv_elu(-2.0 :: float, 0.3)
-- select sm_sc.fv_elu(-2.0 :: float, 0.2)
-- select sm_sc.fv_elu(-2.0 :: float, 0.1)
-- select sm_sc.fv_elu(0.0 :: float, 0.5 :: float)
-- select sm_sc.fv_elu(1.0 :: float, 0.3)
-- select sm_sc.fv_elu(2.0 :: float, 0.2)
-- select sm_sc.fv_elu(3.0, 0.1)
