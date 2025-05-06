-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_turn_180_dloss_dindepdt_py(float[], int[2]);
create or replace function sm_sc.fv_d_turn_180_dloss_dindepdt_py
(
  i_dloss_ddepdt            float[],
  i_dims    int[2]
)
returns float[]
as
$$
  import numpy as np
  if i_dims[0] == 1 and i_dims[1] == 2 or i_dims[0] == 2 and i_dims[1] == 1:
    return np.array(i_dloss_ddepdt)[::-1, ::-1].tolist()
  elif i_dims[0] == 1 and i_dims[1] == 3 or i_dims[0] == 3 and i_dims[1] == 1:
    return np.array(i_dloss_ddepdt)[::-1, ::, ::-1].tolist()
  elif i_dims[0] == 1 and i_dims[1] == 4 or i_dims[0] == 4 and i_dims[1] == 1:
    return np.array(i_dloss_ddepdt)[::-1, ::, ::, ::-1].tolist()
  elif i_dims[0] == 2 and i_dims[1] == 3 or i_dims[0] == 3 and i_dims[1] == 2:
    return np.array(i_dloss_ddepdt)[::, ::-1, ::-1].tolist()
  elif i_dims[0] == 2 and i_dims[1] == 4 or i_dims[0] == 4 and i_dims[1] == 2:
    return np.array(i_dloss_ddepdt)[::, ::-1, ::, ::-1].tolist()
  elif i_dims[0] == 3 and i_dims[1] == 4 or i_dims[0] == 4 and i_dims[1] == 3:
    return np.array(i_dloss_ddepdt)[::, ::, ::-1, ::-1].tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_d_turn_180_dloss_dindepdt_py
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[3, 4]
--   );