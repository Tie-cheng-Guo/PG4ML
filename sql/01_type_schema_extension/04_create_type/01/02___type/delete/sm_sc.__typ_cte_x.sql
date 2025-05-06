-- -- 用于寄存前向传播临时数据，代替 cte, 扩展并行
-- drop type if exists sm_sc.__typ_cte_x;
create type sm_sc.__typ_cte_x as
(
  -- -- m_work_no                        bigint              ,   -- 训练任务编号
  -- -- m_learn_cnt                       int                 ,   -- 训练次数记录
  m_node_no                        bigint                 ,   -- 该节点编号
  m_node_fn_type                   varchar(64)         ,   -- 该节点函数 lambda 名
  m_pick_depdt_idx                     int4multirange[]        ,   -- y 方向采样到的样本编号
  m_fore_cnt                       int                 ,   -- lambda 目数，自变量参数数量
  m_bi_opr_input_1st               float[]    ,   -- lambda 的第一个参数
  m_bi_opr_input_2nd               float[]    ,   -- lambda 的第二个参数
  m_back_node_os_len               int[]               ,   -- 该节点各个来路的矩阵参数的高宽规格
  m_is_bi_opr_input_1st_back       boolean             ,   -- 该节点第一参数是否有必要求导，反向传播是否要遍历该节点
  m_is_bi_opr_input_2nd_back       boolean             ,   -- 该节点第二参数是否有必要求导，反向传播是否要遍历该节点
  m_heavy_cost_lambda              float[]        -- 开销较大的 lambda 先行计算后，结果存于此结构
);

-- select
--   (
--     -- -- 1                                             ,
--     -- -- 1                                             ,
--     1                                             ,
--     'aa'                                          ,
--     array[int4range(1, 4, '[]')]                  ,
--     6                                             ,
--     array[array[12.3, 15.3], array[12.3, 15.3]]   ,
--     array[array[12.3, 15.3], array[12.3, 15.3]]   ,
--     array[12, 15]                                 ,
--     true                                          ,
--     false                                         ,
--     array[array[12.3, 15.3], array[12.3, 15.3]]   
--   ) :: sm_sc.__typ_cte_x