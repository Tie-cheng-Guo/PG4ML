-- drop function if exists sm_sc.fv_d_activate_absqrt_py(float[], float[]);
create or replace function sm_sc.fv_d_activate_absqrt_py
(
  i_indepdt       float[]
, i_asso_value    float[]   default  array[0.5, 0.0]
                            -- 要求 0 < v_beta < 1
                            -- 要求 0 < v_gamma < 1
)
returns float[]
as
$$
  import numpy as np
  v_indepdt = np.float64(i_indepdt)
  if i_asso_value is None :
    v_asso_value = np.float64([0.5, 0.0])
  else :
    v_asso_value = np.float64(i_asso_value)
  v_alpha = v_asso_value[0] ** (1.0 / (1.0 - v_asso_value[0]))
  v_a_p_a = abs(v_indepdt) + v_alpha
  
  if v_asso_value[0] == 0.5 and v_asso_value[1] == 0.0 :
    return (0.5 * (v_a_p_a ** (-0.5))).tolist()
  else :
    v_sign_flag_gamma = v_asso_value[1] * ((1.0 - np.sign(np.sign(v_indepdt) + 0.5)) / 2.0)
    return \
      ( \
        ( \
          ( \
            ((v_alpha ** v_sign_flag_gamma) * (v_asso_value[0] - v_sign_flag_gamma)) \
            * \
            (v_a_p_a ** v_asso_value[0]) \
          ) \
          + \
          (v_sign_flag_gamma * (v_alpha ** (v_asso_value[0] + v_asso_value[1]))) \
        ) \
        / \
        ( \
          v_a_p_a \
          ** \
          (v_sign_flag_gamma + 1.0) \
        ) \
      ).tolist()
$$
language plpython3u stable
cost 100;
-- select sm_sc.fv_d_activate_absqrt_py(array[[1.0 :: float, -2.0], [3.0, 4.0]])
-- select sm_sc.fv_d_activate_absqrt_py(array[[[1.0 :: float, -2.0], [3.0, 4.0]],[[1.0 :: float, -2.0], [3.0, 4.0]]])
-- select sm_sc.fv_d_activate_absqrt_py(array[[[[1.0 :: float, -2.0], [3.0, 4.0]]]])
-- select sm_sc.fv_d_activate_absqrt_py(array[1.5, -2.5, 3.5])
-- select sm_sc.fv_d_activate_absqrt_py(array[]::float[])
-- select sm_sc.fv_d_activate_absqrt_py(array[array[], array []]::float[])