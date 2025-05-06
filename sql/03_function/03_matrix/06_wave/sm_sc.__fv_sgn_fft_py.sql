-- drop function if exists sm_sc.fv_sgn_fft_py(float[], float[]);
create or replace function sm_sc.__fv_sgn_fft_py
(
  i_real           float[]
, i_imag           float[]
)
returns float[]
as
$$
  import numpy as np
  v_arr = np.float32(i_real) + (np.float32(i_imag) * np.complex64(0+1j))
  v_fft = np.fft.fft(v_arr)
  return np.concatenate((np.array([v_fft.real]), np.array([v_fft.imag])), axis = 0).tolist()
$$
language plpython3u stable
cost 100;

-- select 
--   sm_sc.__fv_sgn_fft_py
--   (
--     array[1,2,3,4]
--   , array[1,2,3,4]
--   )

-- select 
--   sm_sc.__fv_sgn_fft_py
--   (
--     array[[1,2,3,4]]
--   , array[[1,2,3,4]]
--   )