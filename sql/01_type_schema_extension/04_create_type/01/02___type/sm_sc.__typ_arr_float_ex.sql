drop type if exists sm_sc.__typ_arr_float_ex;
create type sm_sc.__typ_arr_float_ex as
(
  m_arr_mid      float[],
  m_cnt          int
);