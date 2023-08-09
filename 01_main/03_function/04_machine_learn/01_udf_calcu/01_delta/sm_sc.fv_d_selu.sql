-- selu: i_y = 1.0507009873554804934193349852946 * case when i_x >= 0.0 then i_x else 1.6732632423543772848170429916717 * (exp(i_x) - 1.0 :: float) end
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_selu(float, float);
create or replace function sm_sc.fv_d_selu
(
  i_x                float,
  i_y                float  default null    -- 可选参数，用于简化复杂度
)
returns float
as
$$
-- declare
begin
  if i_x > 0.0
  then 
    return 1.0507009873554804934193349852946;
  else
    return case when i_y is not null then i_y + 1.75809934084737685994021752081231934206024580891220830977098282 else 1.75809934084737685994021752081231934206024580891220830977098282 * exp(i_x) end;
  end if;
end
$$
language plpgsql stable

-- select sm_sc.fv_d_selu(-2.0 :: float, sm_sc.fv_selu(-2.0 :: float))
-- select sm_sc.fv_d_selu(-2.0 :: float)
-- select sm_sc.fv_d_selu(0.0 :: float)
-- select sm_sc.fv_d_selu(1.0 :: float)
-- select sm_sc.fv_d_selu(2.0 :: float, sm_sc.fv_selu(2.0 :: float))
-- select sm_sc.fv_d_selu(3.0, sm_sc.fv_selu(3.0))
-- select sm_sc.fv_d_selu(2.0 :: float)
-- select sm_sc.fv_d_selu(3.0)