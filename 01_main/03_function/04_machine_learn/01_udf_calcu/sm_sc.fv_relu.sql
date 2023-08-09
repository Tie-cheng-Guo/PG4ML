-- relu: i_y = case when i_x >= 0.0 then i_x else 0.0 end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_relu(float);
create or replace function sm_sc.fv_relu
(
  i_x                float
)
returns float
as
$$
-- declare
begin
  return greatest(i_x, 0.0 :: float);
end
$$
language plpgsql stable


-- select sm_sc.fv_relu(-2.0 :: float)
-- select sm_sc.fv_relu(0.0 :: float)
-- select sm_sc.fv_relu(1.0 :: float)
