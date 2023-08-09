-- sigmoid: i_y = 1.0 :: float/ (1.0 :: float+ exp(-i_x))
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_sigmoid(float);
create or replace function sm_sc.fv_sigmoid
(
  i_x                float
)
returns float
as
$$
-- declare
begin
  return 1.0 :: float/ (1.0 :: float+ exp(-i_x));
end
$$
language plpgsql stable


-- select sm_sc.fv_sigmoid(-2.0 :: float)
-- select sm_sc.fv_sigmoid(0.0 :: float)
-- select sm_sc.fv_sigmoid(1.0 :: float)
