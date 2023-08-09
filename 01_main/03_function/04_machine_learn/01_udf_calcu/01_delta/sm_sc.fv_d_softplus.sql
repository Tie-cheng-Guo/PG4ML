-- softplus: i_y = ln(1 + exp(i_x))

-- drop function if exists sm_sc.fv_d_softplus(float);
create or replace function sm_sc.fv_d_softplus
(
  i_x    float
)
returns float
as
$$
-- declare
begin
  return 1.0 :: float/ (1 + exp(-i_x));
end
$$
language plpgsql stable

-- select sm_sc.fv_d_softplus(-2.0 :: float)
-- select sm_sc.fv_d_softplus(0.0 :: float)
-- select sm_sc.fv_d_softplus(1.0 :: float)
-- select sm_sc.fv_d_softplus(2.0 :: float)
-- select sm_sc.fv_d_softplus(3.0)