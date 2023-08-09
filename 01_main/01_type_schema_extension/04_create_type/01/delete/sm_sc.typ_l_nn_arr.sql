-- 使用对象-成员结构，而不是高维 tensor 结构，便于理解与设计
drop type if exists sm_sc.typ_l_nn_arr;
create type sm_sc.typ_l_nn_arr as
(
  m_vals         float[]      ,    -- 算子结果
  m_dy_d1st      float[]      ,    -- 算子结果对入参一的导数
  m_dy_d2nd      float[]      ,    -- 算子结果对入参二的导数
  m_dloss_dy     float[]           -- 损失函数对出参的导数
);