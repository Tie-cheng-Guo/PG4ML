-- drop function if exists sm_sc.fv_softplus(float);
create or replace function sm_sc.fv_softplus
(
  i_indepdt    float
)
returns float
as
$$
-- declare
begin
  return ln(1 + exp(i_indepdt));
end
$$
language plpgsql stable;

-- select sm_sc.fv_softplus(-2.0 :: float)
-- select sm_sc.fv_softplus(0.0 :: float)
-- select sm_sc.fv_softplus(1.0 :: float)
-- select sm_sc.fv_softplus(2.0 :: float)
-- select sm_sc.fv_softplus(3.0)