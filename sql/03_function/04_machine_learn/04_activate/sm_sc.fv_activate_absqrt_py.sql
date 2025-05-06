-- drop function if exists sm_sc.fv_activate_absqrt_py(float[], float[]);
create or replace function sm_sc.fv_activate_absqrt_py
(
  i_array         float[]
, i_asso_value    float[]   default  array[0.5, 0.0]    -- array[v_beta, v_gamma]
                            -- 要求 0 < v_beta < 1, 用于控制正半轴压制程度，
                            --     当 v_beta 靠近 1.0，则压制小；
                            --     当 v_beta 靠近0.0 则压制大；
                            -- 要求 0 < v_gamma <= 1, 在正半轴压制确定的基础上，用于控制负半轴压制程度，
                            --     当 v_gamma = 0.0，则负半轴压制与正半轴一致，此时函数为中心对称；
                            --     当 v_gamma = v_beta，则导数仍保持为正，自变量为负无穷时，因变量趋近于下限为 v_beta ^ (v_beta / (v_beta - 1.0))；
                            --     当 v_gamma = 1.0，则会出现负导数，自变量为负无穷时，因变量趋近于 - 0.0
)
returns float[]
as
$$
  import numpy as np
  v_array = np.float64(i_array)
  if i_asso_value is None :
    v_asso_value = np.float64([0.5, 0.0])
  else :
    v_asso_value = np.float64(i_asso_value)
  
  v_alpha = v_asso_value[0] ** (1.0 / (1.0 - v_asso_value[0]))
  v_sign_flag_val = np.sign(np.sign(v_array) + 0.5)
  v_array_abs = abs(v_array)
  v_a_p_a = v_array_abs + v_alpha
  v_basic = v_sign_flag_val * ((v_a_p_a ** v_asso_value[0]) - (v_alpha ** v_asso_value[0]))
  
  if v_asso_value[1] == 0.0 :
    return v_basic.tolist()
  elif v_asso_value[1] == 1.0 :
    return (v_basic / (1.0 - ((v_array_abs / v_alpha) * ((1.0 - v_sign_flag_val) / 2.0)))).tolist()
  else :
    return (v_basic / ((v_a_p_a / v_alpha) ** (v_asso_value[1] * ((1.0 - v_sign_flag_val) / 2.0)))).tolist()
$$
language plpython3u stable
cost 100;
-- select sm_sc.fv_activate_absqrt_py(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- select sm_sc.fv_activate_absqrt_py(array[[[1.0 :: float, -2.0], [3.0, 4.0]],[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- select sm_sc.fv_activate_absqrt_py(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- select sm_sc.fv_activate_absqrt_py(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_activate_absqrt_py(array[]::float[])
-- select sm_sc.fv_activate_absqrt_py(array[array[], array []]::float[])