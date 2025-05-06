-- drop function if exists sm_sc.fv_absqrt(float, float[]);
create or replace function sm_sc.fv_absqrt
(
  i_indepdt       float
, i_asso_value    float[]   default  array[0.5, 0.0]   -- array[v_beta, v_gamma]
                            -- 要求 0 < v_beta < 1   v_beta, 用于控制正半轴压制程度，
                            --     当 v_beta 靠近 1.0，则压制小；
                            --     当 v_beta 靠近0.0 则压制大；
                            -- 约束 0 < v_gamma < 1   v_gamma, 在正半轴压制确定的基础上，用于控制负半轴压制程度，
                            --     当 v_gamma = 0.0，则负半轴压制与正半轴一致，此时函数为中心对称；
                            --     当 v_gamma = v_beta，则导数仍保持为正，自变量为负无穷时，因变量趋近于下限为 v_beta ^ (v_beta / (v_beta - 1.0))；
                            --     当 v_gamma = 1.0，则会出现负导数，自变量为负无穷时，因变量趋近于 - 0.0；
)
returns float
as
$$
declare
  -- 约束原点导数为 1.0
  v_alpha    float   :=    i_asso_value[1] ^ (1.0 :: float / (1.0 :: float - i_asso_value[1]));
begin    
  if i_indepdt >= 0.0 
  then 
    return 
      ((i_indepdt + v_alpha) ^ i_asso_value[1]) 
      - 
      (v_alpha ^ i_asso_value[1])
    ;
  elsif i_indepdt < 0.0
  then 
    return 
      -
      (((- i_indepdt + v_alpha) ^ i_asso_value[1]) - (v_alpha ^ i_asso_value[1])) 
      /
      (
        power((-i_indepdt + v_alpha) / v_alpha, i_asso_value[2])
      )
    ;
  end if;
end
$$
language plpgsql stable;

-- select sm_sc.fv_absqrt(-2.0 :: float)
-- select sm_sc.fv_absqrt(0.0 :: float)
-- select sm_sc.fv_absqrt(1.0 :: float)
-- select sm_sc.fv_absqrt(2.0 :: float)
-- select sm_sc.fv_absqrt(3.0)