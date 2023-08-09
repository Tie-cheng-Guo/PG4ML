drop type if exists sm_sc.__typ_l_complex_ex;
create type sm_sc.__typ_l_complex_ex as
(
  m_arr_mid      sm_sc.typ_l_complex,
  m_cnt          int
);