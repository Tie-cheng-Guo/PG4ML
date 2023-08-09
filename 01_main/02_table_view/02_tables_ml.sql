-- 创建全局 sequence 
-- 如果是分布式集群环境和并发访问场景，需对全局 sequence: seq_global 做分段规划、各节点设置独立的 minvalue 和 maxvalue
-- 该 seq 只能通过 sm_sc.fv_get_global_seq 间接获取，不能直接 nextval(), setval() 操作
-- drop sequence if exists sm_sc.__seq_global;
create sequence if not exists sm_sc.__seq_global increment by 1 minvalue 0 no maxvalue start with 1;
select nextval('sm_sc.__seq_global');    -- 如果不初始化 seq，会报错：'currval of sequence "sm_sc.__seq_global" is not yet defined in this session'

-- -------------------------------------------------------------------------------------------
-- drop sequence if exists sm_sc.seq_task;
create sequence if not exists sm_sc.seq_task increment by 1 minvalue 1 no maxvalue start with 1;
drop table if exists sm_sc.tb_classify_task;
create unlogged table sm_sc.tb_classify_task
(
  work_no       bigint    primary key default nextval('sm_sc.seq_task'),
  learn_cnt     int                   default 0                  ,                     
  loss_fn_type  int                                              ,                     
  loss_delta    float                                           ,                             
  ret_w         float[]                                          
);

comment on table  sm_sc.tb_classify_task                         is '分类任务训练任务表，包含信息：任务会话、任务级配置参数';
comment on column sm_sc.tb_classify_task.work_no                 is '训练任务序号  '                                        ;
comment on column sm_sc.tb_classify_task.learn_cnt               is '已完成训练次数'                                              ;
comment on column sm_sc.tb_classify_task.loss_fn_type            is '损失函数选取类型。1: 最小二乘法; 2: 交叉熵'            ;
comment on column sm_sc.tb_classify_task.loss_delta              is '当次训练损失函数值 '                                   ;
comment on column sm_sc.tb_classify_task.ret_w                   is '权重，仅用于线性回归、逻辑回归'                        ;

-- drop sequence if exists sm_sc.seq_learn_work;
create sequence if not exists sm_sc.seq_learn_work increment by 1 minvalue 1 no maxvalue start with 1;

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.tb_cluster_task;
create unlogged table sm_sc.tb_cluster_task
(
  work_no               bigint    primary key default nextval('sm_sc.seq_task'),           
  cluster_cnt           int                                              ,                                
  max_point_distance    float                                           ,                                        
  cluster_type          int                                                          
);

comment on table  sm_sc.tb_cluster_task                           is '聚类任务训练任务表，包含信息：任务会话、任务级配置参数';
comment on column sm_sc.tb_cluster_task.work_no                   is '训练任务序号                                          ';
comment on column sm_sc.tb_cluster_task.cluster_cnt               is '聚类数量，用于硬聚类，如 kmeans++                     ';
comment on column sm_sc.tb_cluster_task.max_point_distance        is '相邻样本空间距离设定阈值最大，用于软聚类，如 dbscan++ ';
comment on column sm_sc.tb_cluster_task.cluster_type              is '聚类方法类型。1: kmeans++; 2: dbscan++                ';

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.tb_nn_train_input_buff;
create unlogged table sm_sc.tb_nn_train_input_buff
(
  work_no    bigint          ,    
  ord_no     int             ,    
  i_y        float[]        ,    
  i_x        float[]        ,    
  primary key (work_no, ord_no)
)
with
(parallel_workers = 64)
;

comment on table  sm_sc.tb_nn_train_input_buff                is '规约: 训练集数据编码规范后，存放这里'     ;
comment on column sm_sc.tb_nn_train_input_buff.work_no        is '训练任务序号'                             ;
comment on column sm_sc.tb_nn_train_input_buff.ord_no         is '训练集记录序号，insert row_number() 即可' ;
comment on column sm_sc.tb_nn_train_input_buff.i_y            is '训练集记录输出(分类结果), 1d'             ;
comment on column sm_sc.tb_nn_train_input_buff.i_x            is '训练集记录输入(属性), 1d'                 ;

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.tb_nn_node;
create unlogged table sm_sc.tb_nn_node
(
  work_no                 bigint                 ,     -- 训练任务序号
  node_no                 bigint                 ,     -- 神经元序号（尽量规划为包含层数信息），前向传播起点， node x值 是 i_x；前向传播终点， node x值 是 i_y
  node_type               varchar(64)            ,     -- 神经元类型      enum_name = 'node_type'   规约：每个 work_no 全局的 input, output 节点各只有一个
  node_fn_type            varchar(64)            ,     -- 神经元运算函数  enum_name = 'node_fn_type'
  node_fn_asso_value      float[]               ,     -- 超参数，不限定一维或二维或高维的 float 数组，配置规约：1. 激活函数的协参；2. 寄存必要的多目汇总信息，如 avg 所需的 count(path)；3. 卷积、池化的窗口宽度
  nn_depth_no             int                    ,     -- 前向传播串行步骤序号
  learn_cnt_fore          int     default 0      ,     -- 前向传播训练次数序号
  learn_cnt_back          int     default 0      ,     -- 反向传播训练次数序号
  is_fore_node            boolean default true   ,     -- 前向传播节点起点。缺省 true. 从神经网络的初始起点（包括）开始审计，至 prod_mx, conv_2d, rand 类算子为止（不包括），沿途皆为 false
  is_back_node            boolean default false  ,     -- 反向传播节点终点。缺省 false. 从 weight 算子（包括）开始传染，至神经网络的终点（包括），沿途皆为 true
  node_o_len              int[2]                 ,     -- node_o 的高宽，用于训练前审计
  pick_y_idx              int4range[]            ,     -- 对算子入参的抽样或切片序号集合，用于 nn 从 i_y 中获得 本次训练的 v_y   -- 务必保证算子数据集数量经过各层 nn fn 的第一目（包括聚合的n目）而不是第二目输入，最终抵达输出
  node_y_vals             float[]               ,     -- 因变量结果
  node_dloss_dy           float[]               ,     -- 损失函数对因变量导数
  cost_delta_l1           float[]               ,     -- Adam 梯度下降 一阶矩
  cost_delta_l2           float[]               ,     -- Adam 梯度下降 二阶矩
  primary key (work_no, node_no)
)
with
(parallel_workers = 64)
;
-- alter table sm_sc.tb_nn_node set (parallel_workers = 64)

comment on table  sm_sc.tb_nn_node                      is '神经网络的各层节点列表，用于训练'     ;
comment on column sm_sc.tb_nn_node.work_no              is '训练任务序号';
comment on column sm_sc.tb_nn_node.node_no              is '神经元序号（尽量规划为包含层数信息），前向传播起点， node x值 是 i_x；前向传播终点， node x值 是 i_y';
comment on column sm_sc.tb_nn_node.node_type            is '神经元类型      enum_name = ''node_type''   规约：每个 work_no 全局的 input, output 节点各只有一个';
comment on column sm_sc.tb_nn_node.node_fn_type         is '神经元运算函数  enum_name = ''node_fn_type''';
comment on column sm_sc.tb_nn_node.node_fn_asso_value   is '超参数，不限定一维或二维或高维的 float 数组，配置规约：1. 激活函数的协参；2. 寄存必要的多目汇总信息，如 avg 所需的 count(path)；3. 卷积、池化的窗口宽度';
comment on column sm_sc.tb_nn_node.nn_depth_no          is '前向传播串行步骤序号';
comment on column sm_sc.tb_nn_node.learn_cnt_fore       is '前向传播训练次数序号';
comment on column sm_sc.tb_nn_node.learn_cnt_back       is '反向传播训练次数序号';
comment on column sm_sc.tb_nn_node.is_fore_node         is '前向传播节点起点。缺省 true. 从神经网络的初始起点（包括）开始审计，至 prod_mx, conv_2d, rand 类算子为止（不包括），沿途皆为 false';
comment on column sm_sc.tb_nn_node.is_back_node         is '反向传播节点终点。缺省 false. 从 weight 算子（包括）开始传染，至神经网络的终点（包括），沿途皆为 true';
comment on column sm_sc.tb_nn_node.node_o_len           is 'node_o 的高宽，用于训练前审计';
comment on column sm_sc.tb_nn_node.pick_y_idx           is '对算子入参的抽样或切片序号集合，用于 nn 从 i_y 中获得 本次训练的 v_y   -- 务必保证算子数据集数量经过各层 nn fn 的第一目（包括聚合的n目）而不是第二目输入，最终抵达输出';
comment on column sm_sc.tb_nn_node.node_y_vals          is '因变量结果';
comment on column sm_sc.tb_nn_node.node_dloss_dy        is '损失函数对因变量导数';
comment on column sm_sc.tb_nn_node.cost_delta_l1        is 'Adam 梯度下降 一阶矩';
comment on column sm_sc.tb_nn_node.cost_delta_l2        is 'Adam 梯度下降 二阶矩';

create index on sm_sc.tb_nn_node(work_no, learn_cnt_fore);
create index on sm_sc.tb_nn_node(work_no, learn_cnt_back);
create index on sm_sc.tb_nn_node(work_no, node_type);
create index on sm_sc.tb_nn_node(work_no, nn_depth_no);
create index on sm_sc.tb_nn_node(work_no, is_fore_node);
create index on sm_sc.tb_nn_node(work_no, is_back_node);

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.__vt_nn_node;
create unlogged table sm_sc.__vt_nn_node
(
  work_no                 bigint       ,         
  node_no                 bigint       ,      
  node_type               varchar(64)  ,  
  node_fn_type            varchar(64)  ,  
  node_fn_asso_value      float[]     ,       
  nn_depth_no             int          ,          
  node_y_vals             float[]     ,      
  primary key (work_no, node_no)
)
with
(parallel_workers = 64)
;

comment on table  sm_sc.__vt_nn_node                       is '神经网络的各层节点列表，用于测试预测'     ;
comment on column sm_sc.__vt_nn_node.work_no               is '训练任务序号';
comment on column sm_sc.__vt_nn_node.node_no               is '神经元（包含层数信息）序号';
comment on column sm_sc.__vt_nn_node.node_type             is '神经元类型      enum_name = ''node_type''。规约：每个 work_no 全局的 input, output 节点各只有一个';
comment on column sm_sc.__vt_nn_node.node_fn_type          is '神经元运算函数  enum_name = ''node_fn_type''';
comment on column sm_sc.__vt_nn_node.node_fn_asso_value    is '配置规约：参看字典表 enum_name = ''node_fn_asso_value''';
comment on column sm_sc.__vt_nn_node.nn_depth_no           is '前向传播串行步骤序号';
comment on column sm_sc.__vt_nn_node.node_y_vals           is '训练权重，只存 node_o.m_vals where node_type = ''weight''';

create index on sm_sc.__vt_nn_node(work_no, node_type);
create index on sm_sc.__vt_nn_node(work_no, nn_depth_no);

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.tb_nn_path;
create unlogged table sm_sc.tb_nn_path
(
  work_no            bigint              ,     -- 训练任务序号
  fore_node_no       bigint              ,     -- 反向传播发起节点(前向传播目标节点)神经元（包含层数信息）序号
  path_ord_no        int                 ,     -- 对应前向目标（也即抵达节点）的传递顺序，从1起始 w0, w1, w2...。
  back_node_no       bigint              ,     -- 前向传播发起节点(反向传播目标节点)神经元（包含层数信息）序号
  dy_dx              float[]             ,     -- 因变量对自变量导数
  primary key (work_no, fore_node_no, path_ord_no)
)
with
(parallel_workers = 64)
;

comment on table  sm_sc.tb_nn_path                        is '神经网络传播路径列表，包含信息：边、数据流图'     ;
comment on column sm_sc.tb_nn_path.work_no                is '训练任务序号';
comment on column sm_sc.tb_nn_path.fore_node_no           is '反向传播发起节点(前向传播目标节点)神经元（包含层数信息）序号';
comment on column sm_sc.tb_nn_path.path_ord_no            is '对应前向目标（也即抵达节点）的传递顺序，从1起始 w0, w1, w2...。';
comment on column sm_sc.tb_nn_path.back_node_no           is '前向传播发起节点(反向传播目标节点)神经元（包含层数信息）序号';
comment on column sm_sc.tb_nn_path.dy_dx                  is '因变量对自变量导数';

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.tb_dic_enum;
create table sm_sc.tb_dic_enum
(
  enum_name      varchar(64)                ,
  enum_key       varchar(32)                ,
  enum_value     varchar(512)               ,
  enum_group     varchar(64)                ,
  enum_order     int                        ,
  enum_range     numrange                   ,
  primary key (enum_name, enum_key)
);
create unique index on sm_sc.tb_dic_enum(enum_name, enum_group, enum_order);

comment on table  sm_sc.tb_dic_enum             is '字典表，where enum_name = ''node_fn_type'', 存放 算子；where enum_name = ''node_fn_type_delta'', 存放 导数算子；where enum_name = ''node_type'', 存放（输入输出位置）节点类型';
comment on column sm_sc.tb_dic_enum.enum_name   is '字典字段项';
comment on column sm_sc.tb_dic_enum.enum_key    is '枚举 key';
comment on column sm_sc.tb_dic_enum.enum_value  is '枚举 value';
comment on column sm_sc.tb_dic_enum.enum_group  is '枚举分组';
comment on column sm_sc.tb_dic_enum.enum_order  is '枚举顺序号，对于 enum_name = ''node_fn_type_delta'', 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 sub, div, pow, log 四种运算操作敏感，其他运算操作缺省 null 或实际位置。';
comment on column sm_sc.tb_dic_enum.enum_range  is '范围枚举的区间';

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.__vt_tmp_nn_node;
create unlogged table if not exists sm_sc.__vt_tmp_nn_node
(
  sess_id                 bigint           ,   -- char(32)  ,
  work_no                 bigint       ,           
  node_no                 bigint       ,           
  node_type               varchar(64)  ,    
  node_fn_type            varchar(64)  ,    
  node_fn_asso_value      float[]     , 
  nn_depth_no             int          ,  
  node_y_vals              float[]     ,
  primary key (sess_id, work_no, node_no)
)
;

comment on table  sm_sc.__vt_tmp_nn_node                        is '用于测试集/验证集的输出寄存，被 sm_sc.fv_nn_in_out 做 dml 操作'     ;
comment on column sm_sc.__vt_tmp_nn_node.sess_id                is '请求会话 id';
comment on column sm_sc.__vt_tmp_nn_node.work_no                is '训练任务序号';
comment on column sm_sc.__vt_tmp_nn_node.node_no                is '神经元序号';
comment on column sm_sc.__vt_tmp_nn_node.node_type              is '神经元类型';
comment on column sm_sc.__vt_tmp_nn_node.node_fn_type           is '神经元运算函数';
comment on column sm_sc.__vt_tmp_nn_node.node_fn_asso_value     is '超参数配置';
comment on column sm_sc.__vt_tmp_nn_node.nn_depth_no            is '前向传播串行步骤序号，前向深度';
comment on column sm_sc.__vt_tmp_nn_node.node_y_vals             is '训练权重，只存 node_o.m_vals where node_type = ''weight''';

-- -------------------------------------------------------------------------------------------
create sequence if not exists huffman_seq start 1000000000;
drop table if exists sm_sc.__vt_tmp_huffman;
create unlogged table if not exists sm_sc.__vt_tmp_huffman
(
  sess_id         bigint           ,   -- char(32)  ,
  node_no         bigint       default nextval('huffman_seq')       ,    
  is_compared     boolean      default false                        ,    
  node_weight     float                                            ,    
  is_org          boolean                                           ,    
  tree_code       varbit                                            ,    
  father_node_no  bigint                                            ,    
  primary key (sess_id, node_no)
)
;

comment on table  sm_sc.__vt_tmp_huffman                     is '用于实现霍夫曼编码，被 sm_sc.fv_huffman 做 dml 操作'     ;
comment on column sm_sc.__vt_tmp_huffman.sess_id             is '会话 id';
comment on column sm_sc.__vt_tmp_huffman.node_no             is '自然序列编号';
comment on column sm_sc.__vt_tmp_huffman.is_compared         is '是否已经比较入树';
comment on column sm_sc.__vt_tmp_huffman.node_weight         is '权值';
comment on column sm_sc.__vt_tmp_huffman.is_org              is '是否是原始 input 的节点';
comment on column sm_sc.__vt_tmp_huffman.tree_code           is '单次比较后入树结果，左子树为0，右子树为1';
comment on column sm_sc.__vt_tmp_huffman.father_node_no      is '父节点';

create index if not exists __idx_huffman_node_weight
  on sm_sc.__vt_tmp_huffman(sess_id, is_compared, node_weight);  
create index if not exists __idx_huffman_father
  on sm_sc.__vt_tmp_huffman(sess_id, father_node_no);
  
  
-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.__vt_kmean_ods_array;
create unlogged table sm_sc.__vt_kmean_ods_array
(
  sess_id                bigint           ,   -- char(32)  ,
  point_id               bigint     ,
  point_arr              float[],
  cluster_point_no       bigint     ,
  primary key(sess_id, point_id)
) with (parallel_workers = 64)
;
create index idx_v_ods_array_kmean on sm_sc.__vt_kmean_ods_array (sess_id, cluster_point_no);

comment on table  sm_sc.__vt_kmean_ods_array                     is '用于 kmean 聚类的数据点信息的临时数据，被 sm_sc.prc_kmeans_pp 做 dml 操作';
comment on column sm_sc.__vt_kmean_ods_array.sess_id             is '会话 id';
comment on column sm_sc.__vt_kmean_ods_array.point_id            is '数据集点 id';
comment on column sm_sc.__vt_kmean_ods_array.point_arr           is '数据集点坐标';
comment on column sm_sc.__vt_kmean_ods_array.cluster_point_no    is '聚类点 id';

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.__vt_kmean_list_cluster;
create unlogged table sm_sc.__vt_kmean_list_cluster
(
  sess_id            bigint           ,   -- char(32)  ,
  cluster_point_no   bigint       ,
  cluster_point_arr  float[]     ,
  is_loop_done       boolean      ,
  loop_cnt           int          ,
  primary key(sess_id, cluster_point_no)
) with (parallel_workers = 64)
;

comment on table  sm_sc.__vt_kmean_list_cluster                     is '用于 kmean 聚类的类别信息的临时数据，被 sm_sc.prc_kmeans_pp 做 dml 操作'     ;
comment on column sm_sc.__vt_kmean_list_cluster.sess_id             is '会话 id';
comment on column sm_sc.__vt_kmean_list_cluster.cluster_point_no    is '聚类点 id';
comment on column sm_sc.__vt_kmean_list_cluster.cluster_point_arr   is '聚类点坐标';
comment on column sm_sc.__vt_kmean_list_cluster.is_loop_done        is '循环完成标记';
comment on column sm_sc.__vt_kmean_list_cluster.loop_cnt            is '循环次数';

-- -------------------------------------------------------------------------------------------
-- 用 dbscan 聚类的临时数据
drop table if exists sm_sc.__vt_dbscan_ods_array;
create unlogged table sm_sc.__vt_dbscan_ods_array
(
  sess_id                bigint           ,   -- char(32)  ,
  point_id               bigint     ,
  point_arr              float[],
  dbscan_grp             int     ,
  primary key(sess_id, point_id)
) with (parallel_workers = 64)
;

comment on table  sm_sc.__vt_dbscan_ods_array                     is '用于 dbscan 聚类的数据点信息的临时数据，被 sm_sc.prc_dbscan_pp 做 dml 操作'     ;
comment on column sm_sc.__vt_dbscan_ods_array.sess_id             is '会话 id';
comment on column sm_sc.__vt_dbscan_ods_array.point_id            is '数据集点 id';
comment on column sm_sc.__vt_dbscan_ods_array.point_arr           is '数据集点坐标';
comment on column sm_sc.__vt_dbscan_ods_array.dbscan_grp          is '聚类类别标记';

create index idx_v_ods_array_dbscan on sm_sc.__vt_dbscan_ods_array (sess_id, dbscan_grp);

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc.__vt_dbscan_nearby_point_idx;
create unlogged table sm_sc.__vt_dbscan_nearby_point_idx
(
  sess_id                bigint           ,   -- char(32)  ,
  point_id               bigint       ,
  dimension_no           int               ,
  point_arr_n            float    ,
  point_arr              float[]  ,
  primary key(sess_id, point_id, dimension_no)
) with (parallel_workers = 64)
;
create index idx_v_nearby_idx_arr on sm_sc.__vt_dbscan_nearby_point_idx (sess_id, dimension_no, point_arr_n);

comment on table  sm_sc.__vt_dbscan_nearby_point_idx                       is '用于 dbscan 聚类的数据点临近信息的临时数据，被 sm_sc.prc_dbscan_pp 做 dml 操作'     ;
comment on column sm_sc.__vt_dbscan_nearby_point_idx.sess_id               is '会话 id';
comment on column sm_sc.__vt_dbscan_nearby_point_idx.point_id              is '数据集点 id';
comment on column sm_sc.__vt_dbscan_nearby_point_idx.dimension_no          is '临近维度';
comment on column sm_sc.__vt_dbscan_nearby_point_idx.point_arr_n           is '临近距离';
comment on column sm_sc.__vt_dbscan_nearby_point_idx.point_arr             is '临近坐标';

-- ----------------------------------------------------------------------------------------------------------------------------------------------
-- 表变量 for sm_sc.ft_computational_graph_deserialize
drop table if exists sm_sc._vt_fn_compu_graph_deseri__graph;
create unlogged table sm_sc._vt_fn_compu_graph_deseri__graph
(
  sess_id              bigint           ,   -- char(32)  ,
  out_param            varchar(64)              ,
  in_param             varchar(64)              ,
  in_value             float            ,
  param_loc            int                      ,
  out_opr              varchar(64)              ,
  create_time          timestamp default now()  ,
  unique (sess_id, out_param, param_loc) 
);

comment on table  sm_sc._vt_fn_compu_graph_deseri__graph                       is '用于计算图反序列化的临时数据，被 sm_sc.ft_computational_graph_deserialize 做 dml 操作'     ;
comment on column sm_sc._vt_fn_compu_graph_deseri__graph.sess_id               is '会话 id';
comment on column sm_sc._vt_fn_compu_graph_deseri__graph.out_param             is '因变量';
comment on column sm_sc._vt_fn_compu_graph_deseri__graph.in_param              is '自变量';
comment on column sm_sc._vt_fn_compu_graph_deseri__graph.in_value              is '入参常量';
comment on column sm_sc._vt_fn_compu_graph_deseri__graph.param_loc             is '入参位置';
comment on column sm_sc._vt_fn_compu_graph_deseri__graph.out_opr               is '运算类型';

-- ----------------------------------------------------------------------------------------------------------------------------------------------
-- 表变量 for sm_sc.ft_gradient
drop table if exists sm_sc._vt_fn_grad__graph;
create unlogged table if not exists sm_sc._vt_fn_grad__graph
(
  sess_id              bigint           ,   -- char(32)  ,
  o_out_param          varchar(64)              ,
  o_in_param           varchar(64)              ,
  o_in_value           varchar(64)              ,
  o_param_loc          int                      ,
  o_out_opr            varchar(64)              ,
  is_decimal           boolean                  ,
  create_time          timestamp default now()  ,
  unique (sess_id, o_out_param, o_param_loc) 
);
  
comment on table  sm_sc._vt_fn_grad__graph                       is '用于求导推导的临时数据，被 sm_sc.ft_gradient 做 dml 操作'     ;
comment on column sm_sc._vt_fn_grad__graph.sess_id               is '会话 id';
comment on column sm_sc._vt_fn_grad__graph.o_out_param           is '因变量';
comment on column sm_sc._vt_fn_grad__graph.o_in_param            is '自变量';
comment on column sm_sc._vt_fn_grad__graph.o_in_value            is '入参常量';
comment on column sm_sc._vt_fn_grad__graph.o_param_loc           is '入参位置';
comment on column sm_sc._vt_fn_grad__graph.o_out_opr             is '运算类型';
comment on column sm_sc._vt_fn_grad__graph.is_decimal            is '是否数字';
  
-- -------------------------------------------------------------------------------------------
  -- 表变量 for sm_sc.ft_gradient
  drop table if exists sm_sc._vt_fn_grad__algebra;
  create unlogged table if not exists sm_sc._vt_fn_grad__algebra
  (
    sess_id              bigint           ,   -- char(32)  ,
    o_out_param          varchar(64)              ,
    o_out_algebra        text                     ,
    is_decimal           boolean                  ,
    unique (sess_id, o_out_param) 
  );

comment on table  sm_sc._vt_fn_grad__algebra                       is '用于求导推导代数信息的临时数据，被 sm_sc.ft_gradient 做 dml 操作'     ;
comment on column sm_sc._vt_fn_grad__algebra.sess_id               is '会话 id';
comment on column sm_sc._vt_fn_grad__algebra.o_out_param           is '因变量';
comment on column sm_sc._vt_fn_grad__algebra.o_out_algebra         is '因变量代数信息';
comment on column sm_sc._vt_fn_grad__algebra.is_decimal            is '是否数字';

-- -------------------------------------------------------------------------------------------
drop table if exists sm_sc._vt_fn_grad__forward;
create unlogged table if not exists sm_sc._vt_fn_grad__forward
(
  sess_id              bigint           ,   -- char(32)  ,
  out_param            varchar(64)              ,
  in_params            varchar(64)[]            ,
  in_values            float[]         ,
  out_opr              varchar(64)              ,
  calcu_val            float           ,
  create_time          timestamp default now()  -- ,
  -- unique (sess_id, out_param)   -- -- 避免锁表，防止并发读写阻塞
);
  
comment on table  sm_sc._vt_fn_grad__forward                   is '用于求导推导分组信息的临时数据，寄存前向传播数据，被 sm_sc.ft_gradient 做 dml 操作'     ;
comment on column sm_sc._vt_fn_grad__forward.sess_id           is '会话 id';
comment on column sm_sc._vt_fn_grad__forward.out_param         is '因变量';
comment on column sm_sc._vt_fn_grad__forward.in_params         is '自变量聚合';
comment on column sm_sc._vt_fn_grad__forward.in_values         is '入参常量集合';
comment on column sm_sc._vt_fn_grad__forward.out_opr           is '运算类型';
comment on column sm_sc._vt_fn_grad__forward.calcu_val         is '计算数值';
  
create index if not exists __idx_grad__forward on sm_sc._vt_fn_grad__forward (sess_id, out_param);
-- -- -- create index if not exists on sm_sc._vt_fn_grad__forward using gist (sess_id, in_params);
  
-- -------------------------------------------------------------------------------------------
-- -- 寄存链式求导数据
drop table if exists sm_sc._vt_fn_grad__chain;
create unlogged table if not exists sm_sc._vt_fn_grad__chain
(
  sess_id              bigint           ,   -- char(32)  ,
  out_param            varchar(64)              ,
  param_loc            int                      ,
  in_param             varchar(64)              ,
  in_value             float           ,
  out_opr              varchar(64)              ,
  calcu_val            float           ,
  grad_val             float           ,
  co_vals              float[]         ,
  create_time          timestamp default now()  ,
  unique (sess_id, out_param, param_loc) 
);

comment on table  sm_sc._vt_fn_grad__chain                   is '用于求导推导的临时数据，寄存链式求导数据，被 sm_sc.ft_gradient 做 dml 操作'     ;
comment on column sm_sc._vt_fn_grad__chain.sess_id           is '会话 id';
comment on column sm_sc._vt_fn_grad__chain.out_param         is '因变量';
comment on column sm_sc._vt_fn_grad__chain.param_loc         is '入参位置';
comment on column sm_sc._vt_fn_grad__chain.in_param          is '自变量';
comment on column sm_sc._vt_fn_grad__chain.in_value          is '入参常量';
comment on column sm_sc._vt_fn_grad__chain.out_opr           is '运算类型';
comment on column sm_sc._vt_fn_grad__chain.calcu_val         is '计算数值';
comment on column sm_sc._vt_fn_grad__chain.grad_val          is '梯度值';
comment on column sm_sc._vt_fn_grad__chain.co_vals           is '协参集合';

create index if not exists _idx_grad__chain on sm_sc._vt_fn_grad__chain (sess_id, in_param);

-- -------------------------------------------------------------------------------------------
-- 用于 sm_sc.fv_mx_determinant
--      sm_sc.fv_mx_inversion
--      sm_sc.fv_mx_rank
--      sm_sc.fv_mx_rows_step_simple
--      sm_sc.fv_mx_row_step
drop table if exists sm_sc.__vt_tmp_matrix;
create unlogged table sm_sc.__vt_tmp_matrix
(
  sess_id             bigint           ,   -- char(32)  ,
  new_row_no          int             ,   
  array_x             float[]    
) with (parallel_workers = 64);

comment on table  sm_sc.__vt_tmp_matrix                   is '用于矩阵运算临时表做 dml 操作'     ;
comment on column sm_sc.__vt_tmp_matrix.sess_id           is '会话 id';
comment on column sm_sc.__vt_tmp_matrix.new_row_no        is '新行号';
comment on column sm_sc.__vt_tmp_matrix.array_x           is '行向量';

create index idx_tmp_matrix on sm_sc.__vt_tmp_matrix (sess_id, new_row_no);
  
-- -------------------------------------------------------------------------------------------
-- 用于 sm_sc.prc_mx_eigen_array_value
drop table if exists sm_sc.__vt_tmp_eigen_arrays;
create unlogged table sm_sc.__vt_tmp_eigen_arrays
(
  sess_id        bigint           ,   -- char(32)  ,
  eigen_value    float     ,
  eigen_array    float[]
) with (parallel_workers = 64);
  
comment on table  sm_sc.__vt_tmp_eigen_arrays                   is '用于特征分解，被 sm_sc.prc_mx_eigen_array_value 做 dml 操作'     ;
comment on column sm_sc.__vt_tmp_eigen_arrays.sess_id           is '会话 id';
comment on column sm_sc.__vt_tmp_eigen_arrays.eigen_value       is '特征值';
comment on column sm_sc.__vt_tmp_eigen_arrays.eigen_array       is '特征向量';

create index idx_tmp_eigen_arrays on sm_sc.__vt_tmp_matrix (sess_id);

-- -------------------------------------------------------------------------------------------
-- 用于 sm_sc.fv_nn_node2node_val
drop table if exists sm_sc.__vt_tmp_node_node2node;
create unlogged table sm_sc.__vt_tmp_node_node2node
(
  sess_id              bigint           ,   -- char(32)  ,
  work_no              bigint           ,
  node_no              bigint           ,
  node_type            varchar(64)      ,
  node_y_vals           float[]
);

create index __idx_tmp_node_node2node on sm_sc.__vt_tmp_node_node2node (sess_id, work_no, node_no);
create index __idx_tmp_node_node2node_type on sm_sc.__vt_tmp_node_node2node (sess_id, work_no, node_type);