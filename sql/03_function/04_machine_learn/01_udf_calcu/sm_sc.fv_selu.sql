-- selu: i_depdt = 1.0507009873554804934193349852946 * case when i_indepdt >= 0.0 then i_indepdt else 1.6732632423543772848170429916717 * (exp(i_indepdt) - 1.0 :: float) end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_selu(float);
create or replace function sm_sc.fv_selu
(
  i_indepdt                float
)
returns float
as
$$
-- declare
begin
  return 1.0507009873554804934193349852946 * case when i_indepdt >= 0.0 then i_indepdt else 1.6732632423543772848170429916717 * (exp(i_indepdt) - 1.0 :: float) end;
end
$$
language plpgsql stable;

-- select sm_sc.fv_selu(-4.0)
-- select sm_sc.fv_selu(-3.0)
-- select sm_sc.fv_selu(-2.0 :: float)
-- select sm_sc.fv_selu(-1.0 :: float)
-- select sm_sc.fv_selu(0.0 :: float)
-- select sm_sc.fv_selu(1.0 :: float)
-- select sm_sc.fv_selu(2.0 :: float)
-- select sm_sc.fv_selu(3.0)
