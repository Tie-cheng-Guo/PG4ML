-- gelu: i_depdt = i_depdt = 0.5 * i_indepdt * (1.0 :: float+ tanh(power(2.0 / pi(), 0.5 :: float) * (i_indepdt + (0.044715 * power(i_indepdt, 3)))))
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_gelu(float);
create or replace function sm_sc.fv_d_gelu
(
  i_indepdt                float
)
returns float
as
$$
-- declare
begin
  return 0.5 * tanh(0.0356774 * power(i_indepdt, 3) + (0.797885 * i_indepdt)) + ((0.0535161 * power(i_indepdt, 3) + (0.398942 * i_indepdt)) / power(cosh(0.0356774 * power(i_indepdt, 3) + (0.797885 * i_indepdt)), 2)) + 0.5;
end
$$
language plpgsql stable;


-- select sm_sc.fv_d_gelu(-2.0 :: float)
-- select sm_sc.fv_d_gelu(-1.0 :: float)
-- select sm_sc.fv_d_gelu(-0.5 :: float)
-- select sm_sc.fv_d_gelu(0.0 :: float)
-- select sm_sc.fv_d_gelu(0.5 :: float)
-- select sm_sc.fv_d_gelu(1.0 :: float)
-- select sm_sc.fv_d_gelu(2.0 :: float)