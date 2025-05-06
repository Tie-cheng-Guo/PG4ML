-- drop function if exists sm_sc.fv_d_absqrt_asso(float, float[]);
create or replace function sm_sc.fv_d_absqrt_asso
(
  i_indepdt       float
, i_asso_value    float[]   default  array[0.5, 0.0]    -- array[v_beta, v_gamma]
                            -- 要求 0 < v_beta < 1   
                            -- 约束 0 < v_gamma < 1
)
returns float
as
$$
declare
  -- 约束原点导数为 1.0
  v_alpha    float   :=    i_asso_value[1] ^ (1.0 :: float / (1.0 :: float - i_asso_value[1]));
begin
  if i_indepdt >= 0
  then
    return i_asso_value[1] * ((i_indepdt + v_alpha) ^ (i_asso_value[1] - 1.0));
  else 
    return 
      (
        (
          (i_asso_value[1] - i_asso_value[2])
          * 
          (
            (-i_indepdt + v_alpha) 
            ^ 
            (i_asso_value[1] - 1.0 :: float)
          )
        ) 
        +
        (
          (
            i_asso_value[2] 
            * 
            (v_alpha ^ i_asso_value[1])
          )
          /
          (-i_indepdt + v_alpha)
        )
      )
      / 
      (
        (v_alpha ^ (-i_asso_value[2]))
        *
        ((-i_indepdt + v_alpha) ^ i_asso_value[2])
      )
    ;
  end if;

  -- if i_asso_value[2] = 0.5 and i_depdt is not null
  -- then 
  --   return 0.5 / (abs(i_depdt) + (i_asso_value[1] ^ i_asso_value[2]));
  -- else 
  --   return i_asso_value[2] * ((abs(i_indepdt) + i_asso_value[1]) ^ (i_asso_value[2] - 1.0));
  -- end if;
end
$$
language plpgsql stable;


-- select sm_sc.fv_d_absqrt_asso(2.0  :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(2.0  :: float)
-- select sm_sc.fv_d_absqrt_asso(-2.0 :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(-2.0 :: float)
-- select sm_sc.fv_d_absqrt_asso(0.0  :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(0.0  :: float)
-- select sm_sc.fv_d_absqrt_asso(1.0  :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(1.0  :: float)
-- select sm_sc.fv_d_absqrt_asso(-1.0 :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(-1.0 :: float)
-- select sm_sc.fv_d_absqrt_asso(0.5  :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(0.5  :: float)
-- select sm_sc.fv_d_absqrt_asso(-0.5 :: float, array[0.5, 0.0]), sm_sc.fv_d_absqrt_asso(-0.5 :: float)