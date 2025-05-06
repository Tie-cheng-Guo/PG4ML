-- relu: i_depdt = case when i_indepdt >= 0.0 then i_indepdt else 0.0 end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_relu(float);
create or replace function sm_sc.fv_d_relu
(
  i_indepdt                float
)
returns float
as
$$
-- declare
begin
  return case when i_indepdt > 0.0 then 1.0 :: float else 0.0 :: float end;
end
$$
language plpgsql stable;


-- select sm_sc.fv_d_relu(-2.0 :: float)
-- select sm_sc.fv_d_relu(0.0 :: float)
-- select sm_sc.fv_d_relu(1.0 :: float)