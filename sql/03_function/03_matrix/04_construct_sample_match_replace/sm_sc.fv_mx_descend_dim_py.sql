-- drop function if exists sm_sc.fv_mx_descend_dim_py(float[], int);
create or replace function sm_sc.fv_mx_descend_dim_py
(
  i_array         float[]  ,
  i_descend_time  int       default   1
)
returns float[]
as
$$
  import numpy as np
  
  if i_descend_time == 1 :
    return np.array(i_array)[0].tolist()
  elif i_descend_time == 2 :
    return np.array(i_array)[0,0].tolist()
  elif i_descend_time == 3 :
    return np.array(i_array)[0,0,0].tolist()
  elif i_descend_time == 4 :
    return np.array(i_array)[0,0,0,0].tolist()
  elif i_descend_time == 5 :
    return np.array(i_array)[0,0,0,0,0].tolist()
$$
language plpython3u stable
parallel safe
;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_descend_dim_py(array[[1, 2]])
-- select sm_sc.fv_mx_descend_dim_py(array[[1, 2]], 1)
-- select sm_sc.fv_mx_descend_dim_py(array[[[1, 2]]], 2)
-- select sm_sc.fv_mx_descend_dim_py(array[[[[1, 2]]]], 3)
-- select sm_sc.fv_mx_descend_dim_py(array[[[1, 2]]])
-- select sm_sc.fv_mx_descend_dim_py(array[[[1, 2]]], 1)
-- select sm_sc.fv_mx_descend_dim_py(array[[[1, 2]]], 2)