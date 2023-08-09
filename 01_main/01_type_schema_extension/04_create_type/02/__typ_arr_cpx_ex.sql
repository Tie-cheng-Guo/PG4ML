drop type if exists sm_sc.__typ_arr_cpx_ex;
create type sm_sc.__typ_arr_cpx_ex as
(
  m_arr_mid      sm_sc.typ_l_complex[],
  m_cnt          int
);