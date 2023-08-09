-- sigmoid: i_y = 1.0 :: float/ (1.0 :: float+ exp(-i_x))
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_d_sigmoid(float, float);
create or replace function sm_sc.fv_d_sigmoid
(
  i_x                float  ,
  i_y                float  default null    -- 可选参数，用于简化复杂度
)
returns float
as
$$
declare -- here
  v_tmp   float;
begin
  if i_y is not null
  then
    return i_y * (1.0 :: float- i_y);
  else
    v_tmp := nullif(exp(i_x / 2), 0.0 :: float);
    return 1.0 :: float/ power(v_tmp + (1 / v_tmp), 2.0 :: float);
  end if;
end
$$
language plpgsql stable


-- select sm_sc.fv_d_sigmoid(-2.0 :: float)
-- select sm_sc.fv_d_sigmoid(0.0 :: float)
-- select sm_sc.fv_d_sigmoid(1.0 :: float)
-- select sm_sc.fv_d_sigmoid(-2.0 :: float, sm_sc.fv_sigmoid(-2.0 :: float))
-- select sm_sc.fv_d_sigmoid(0.0 :: float, sm_sc.fv_sigmoid(0.0 :: float))
-- select sm_sc.fv_d_sigmoid(1.0 :: float, sm_sc.fv_sigmoid(1.0 :: float))