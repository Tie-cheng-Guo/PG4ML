-- drop function if exists sm_sc.fv_sgn_ifft2_py(float[], float[]);
create or replace function sm_sc.__fv_sgn_ifft2_py
(
  i_real           float[]
, i_imag           float[]
)
returns float[]
as
$$
  import numpy as np
  v_arr = np.float32(i_real) + (np.float32(i_imag) * np.complex64(0+1j))
  v_ifft = np.fft.ifft2(v_arr)
  return np.concatenate((np.array([v_ifft.real]), np.array([v_ifft.imag])), axis = 0).tolist()
$$
language plpython3u stable
cost 100;

-- select 
--   sm_sc.__fv_sgn_ifft2_py
--   (
--     sm_sc.fv_new_rand(array[4, 4])
--   , sm_sc.fv_new_rand(array[4, 4])
--   )

-- select 
--   sm_sc.__fv_sgn_ifft2_py
--   (
--     sm_sc.fv_new_rand(array[3, 4, 4])
--   , sm_sc.fv_new_rand(array[3, 4, 4])
--   )