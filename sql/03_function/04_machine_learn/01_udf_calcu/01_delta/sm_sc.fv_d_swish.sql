-- swish: i_depdt = i_indepdt * sigmoid(i_indepdt)
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_swish(float, float);
create or replace function sm_sc.fv_d_swish
(
  i_indepdt                float,
  i_depdt                float  default null    -- 可选参数，用于简化复杂度
)
returns float
as
$$
declare -- here
  v_sigmoid  float;
begin
  if i_depdt is not null
  then 
    return i_depdt * (1.0 :: float+ i_indepdt - i_depdt) / i_indepdt;
  else
    v_sigmoid := 1.0 :: float/ (1.0 :: float+ exp(-i_indepdt));
    return v_sigmoid * (1.0 :: float+ (i_indepdt * (1 - v_sigmoid)));
  end if;
end
$$
language plpgsql stable;

-- select sm_sc.fv_d_swish(-2.0 :: float, sm_sc.fv_swish(-2.0 :: float))
-- select sm_sc.fv_d_swish(-2.0 :: float)
-- select sm_sc.fv_d_swish(0.0 :: float)
-- select sm_sc.fv_d_swish(1.0 :: float)
-- select sm_sc.fv_d_swish(2.0 :: float, sm_sc.fv_swish(2.0 :: float))
-- select sm_sc.fv_d_swish(3.0, sm_sc.fv_swish(3.0))
-- select sm_sc.fv_d_swish(2.0 :: float)
-- select sm_sc.fv_d_swish(3.0)