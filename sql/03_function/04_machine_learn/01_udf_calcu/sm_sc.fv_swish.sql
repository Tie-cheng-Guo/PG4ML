-- swish: i_depdt = i_indepdt * sigmoid(i_indepdt)
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_swish(float);
create or replace function sm_sc.fv_swish
(
  i_indepdt                float
)
returns float
as
$$
-- declare
begin
  return i_indepdt / (1.0 :: float+ exp(-i_indepdt));
end
$$
language plpgsql stable;


-- select sm_sc.fv_swish(-2.0 :: float)
-- select sm_sc.fv_swish(0.0 :: float)
-- select sm_sc.fv_swish(1.0 :: float)
