-- drop type if exists sm_sc.__typ_cte_dloss_dx_fore;
create type sm_sc.__typ_cte_dloss_dx_fore as
(
  -- -- m_learn_cnt                       int                 ,
  m_node_no                        bigint                 ,
  m_node_fn_type                   varchar(64)         ,
  m_a_dloss_dx_fore_1st            float[]    ,
  m_a_dloss_dx_fore_2nd            float[]    ,
  m_node_fn_asso_value             float[]    ,
  m_node_o_m_vals                  float[]
);

-- select
--   (
--     -- -- 1                                             ,
--     1                                             ,
--     1                                             ,
--     'aa'                                          ,
--     array[array[12.3, 15.3], array[12.3, 15.3]]   ,
--     array[array[12.3, 15.3], array[12.3, 15.3]]   ,
--     array[12.3, 15.3]                             ,
--     array[array[12.3, 15.3], array[12.3, 15.3]]   
--   ) :: sm_sc.__typ_cte_dloss_dx_fore