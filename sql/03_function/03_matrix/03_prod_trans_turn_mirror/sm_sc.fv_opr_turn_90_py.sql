-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_turn_90_py(float[], int[2]);
create or replace function sm_sc.fv_opr_turn_90_py
(
  i_arr            float[],
  i_dims_from_to    int[2]
)
returns float[]
as
$$
  import numpy as np
  # if i_dims_from_to[1] == 1 :
  #   return np.array(i_arr).swapaxes(i_dims_from_to[0] - 1, i_dims_from_to[1] - 1)[::-1].tolist()
  # elif i_dims_from_to[1] == 2 :
  #   return np.array(i_arr).swapaxes(i_dims_from_to[0] - 1, i_dims_from_to[1] - 1)[::, ::-1].tolist()
  # elif i_dims_from_to[1] == 3 :
  #   return np.array(i_arr).swapaxes(i_dims_from_to[0] - 1, i_dims_from_to[1] - 1)[::, ::, ::-1].tolist()
  # elif i_dims_from_to[1] == 4 :
  #   return np.array(i_arr).swapaxes(i_dims_from_to[0] - 1, i_dims_from_to[1] - 1)[::, ::, ::, ::-1].tolist()
  
  return np.rot90(np.array(i_arr), k = 1, axes = (i_dims_from_to[1] - 1, i_dims_from_to[0] - 1)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_opr_turn_90_py
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[3, 4]
--   );