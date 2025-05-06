do
$$
declare
  -- v_batch_amt    int   :=      7;    -- 训练集每个分类的小批量采样数量

begin
  delete from sm_sc.tb_nn_node where work_no = -000000002;
  delete from sm_sc.tb_nn_path where work_no = -000000002;
  commit;
  
  -- 构造 xor 节点
  insert into sm_sc.tb_nn_node
  (
    work_no
  , node_no
  , node_type
  , node_fn_type       
  , node_fn_asso_value
  )
  select 
    -000000002               as work_no                
  , -100000000                as node_no           
  , 'input_01'                  as node_type                   -- 按照分类标记排序，0，1，2，3，4，。。。9，并记录下每个分类的数据集结束位置下标 n0, n1, n2,... n9
  , '00_buff_slice_rand_pick'   as node_fn_type
  , null :: decimal[]      as node_fn_asso_value
  -- -- union all
  -- -- select 
  -- --   -000000002               as work_no                ,
  -- --   -100010000 - a_ord        as node_no            ,
  -- --   null                     as node_type              ,
  -- --   'slice_y'                as node_fn_type                      -- 配置切片编号分别是 1 : n0, n0 + 1 : n1,... n8 + 1 : n9
  -- -- from generate_series(1, 10) tb_a_ord(a_ord)
  -- -- union all
  -- -- select 
  -- --   -000000002               as work_no                ,
  -- --   -100020000 - a_ord        as node_no            ,
  -- --   null                     as node_type              ,
  -- --   'rand_pick_y'            as node_fn_type                      -- 每个分类配置采样为 5 个吧，每次总采样 50 个
  -- -- from generate_series(1, 10) tb_a_ord(a_ord)
  -- -- union all
  -- -- select 
  -- --   -000000002               as work_no                ,
  -- --   -100030001                as node_no            ,
  -- --   null                     as node_type              ,
  -- --   'agg_concat_y'           as node_fn_type
  union all
  select 
    -000000002               as work_no               
  , -100030100 - a_ord        as node_no          
  , 'weight'                 as node_type          -- 卷积核窗口：5*5
  , '00_const'                  as node_fn_type
  , array[1, 25]      as node_fn_asso_value
  from generate_series(1, 6) tb_a_ord(a_ord)    -- weight 此处从序号 2 开始
  union all
  select 
    -000000002               as work_no                
  , -101010000 - a_ord        as node_no           
  , null                     as node_type          
  , '05_conv_2d_grp_x'                as node_fn_type          -- 窗口：5*5
  , array[28, 5, 5, 1, 1, 2, 2, 2, 2, 0]                        as node_fn_asso_value
  from generate_series(1, 6) tb_a_ord(a_ord)         -- 第一层6路卷积
  union all
  select 
    -000000002               as work_no      
  , -101020000 - a_ord        as node_no 
  , null                     as node_type
  , '03_zscore'               as node_fn_type    -- zscore_x
  , array[1, 28 * 28]      as node_fn_asso_value
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002               as work_no          
  , -101030000 - a_ord        as node_no     
  , null                     as node_type    
  , '03_leaky_relu'                   as node_fn_type
  , array[0.01]                        as node_fn_asso_value
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002               as work_no             
  , -102010000 - a_ord        as node_no        
  , null                     as node_type       
  , '05_pool_max_2d_grp_x'               as node_fn_type          -- 窗口：2*2
  , array[28, 2, 2, 2, 2, 0, 0, 0, 0, null, 28 * 28]                        as node_fn_asso_value
  from generate_series(1, 6) tb_a_ord(a_ord)         -- 
  union all
  select 
    -000000002               as work_no          
  , -102010100 - a_ord        as node_no     
  , 'weight'                 as node_type     -- 卷积核窗口：5*5
  , '00_const'                  as node_fn_type          
  , array[1, 25]      as node_fn_asso_value
  from generate_series(1, 60) tb_a_ord(a_ord)         -- 
  union all
  select 
    -000000002               as work_no             
  , -103010000 - a_ord        as node_no        
  , null                     as node_type       
  , '05_conv_2d_grp_x'                as node_fn_type          -- 窗口：5*5
  , array[14, 5, 5, 1, 1, 0, 0, 0, 0, null]                        as node_fn_asso_value
  from generate_series(1, 60) tb_a_ord(a_ord)         -- 第二层60路卷积
  -- https://www.cnblogs.com/hls91/p/10882403.html
  -- https://cuijiahua.com/wp-content/uploads/2018/01/dl_3_5.png
  -- 此处神经元的加权合计计算已经隐含在上一层的 conv_2d 当中，激活则隐含在下一层的 leaky_relu 当中
  union all
  select 
    -000000002               as work_no              
  , -104010000 - a_ord        as node_no         
  , null                     as node_type        
  , '06_aggr_mx_sum'                as node_fn_type   
  , null :: decimal[]      as node_fn_asso_value       
  from generate_series(1, 16) tb_a_ord(a_ord)       
  union all
  select 
    -000000002               as work_no             
  , -104020000 - a_ord        as node_no        
  , null                     as node_type       
  , '03_zscore'               as node_fn_type    -- zscore_x  
  , array[1, 100]      as node_fn_asso_value       
  from generate_series(1, 16) tb_a_ord(a_ord)         
  union all
  select 
    -000000002               as work_no      
  , -104030000 - a_ord        as node_no 
  , null                     as node_type
  , '03_leaky_relu'                   as node_fn_type       
  , array[0.01]                        as node_fn_asso_value 
  from generate_series(1, 16) tb_a_ord(a_ord)    
  union all
  select 
    -000000002               as work_no      
  , -105010000 - a_ord        as node_no 
  , null                     as node_type
  , '05_pool_max_2d_grp_x'               as node_fn_type          -- 窗口：2*2
  , array[10, 2, 2, 2, 2, 0, 0, 0, 0, null, 10 * 10]                        as node_fn_asso_value
  from generate_series(1, 16) tb_a_ord(a_ord)       
  union all
  select 
    -000000002               as work_no      
  , -105020001                as node_no 
  , null                     as node_type
  , '06_aggr_mx_concat_x'           as node_fn_type   
  , null :: decimal[]      as node_fn_asso_value
  union all
  select 
    -000000002               as work_no      
  , -105020101                as node_no 
  , 'weight'                 as node_type -- 矩阵乘法，weight 高宽: 400 * 64
  , '00_const'                  as node_fn_type   
  , array[400, 64]      as node_fn_asso_value
  union all
  select 
    -000000002               as work_no      
  , -106010001                as node_no 
  , null                     as node_type
  , '01_prod_mx'                as node_fn_type   
  , array[null, 16 * 5 * 5, 64]                        as node_fn_asso_value
  union all
  select 
    -000000002               as work_no      
  , -106020001                as node_no 
  , null                     as node_type
  , '03_zscore'               as node_fn_type    -- zscore_x   
  , array[1, 64]      as node_fn_asso_value
  union all
  select 
    -000000002               as work_no      
  , -106030001                as node_no 
  , null                     as node_type
  , '03_leaky_relu'                   as node_fn_type   
  , array[0.01]                        as node_fn_asso_value
  union all
  select 
    -000000002               as work_no            
  , -106030101                as node_no       
  , 'weight'                 as node_type       -- 矩阵乘法，weight 高宽: 64 * 10
  , '00_const'                  as node_fn_type
  , array[64, 10]      as node_fn_asso_value
  union all
  select 
    -000000002               as work_no             
  , -107010001                as node_no        
  , null                     as node_type       
  , '01_prod_mx'                as node_fn_type   
  , array[null, 64, 10]                        as node_fn_asso_value
  union all
  select 
    -000000002               as work_no              
  , -200000000                as node_no         
  , 'output_01'                 as node_type        
  , '03_softmax'              as node_fn_type                   -- softmax_x
  , array[1, 10]      as node_fn_asso_value
  ;
  commit;
  
  -- 构造 lenet-5 路径
  insert into sm_sc.tb_nn_path
  (
    work_no              ,
    fore_node_no      ,
    path_ord_no          ,
    back_node_no
  )
  -- -- select 
  -- --   -000000002          as work_no             ,
  -- --   -100010000 - a_ord   as fore_node_no     ,
  -- --   1                   as path_ord_no         , -- slicy_y
  -- --   -100000000           as back_node_no 
  -- -- from generate_series(1, 10) tb_a_ord(a_ord)
  -- -- union all
  -- -- select 
  -- --   -000000002          as work_no             ,
  -- --   -100020000 - a_ord   as fore_node_no     ,
  -- --   1                   as path_ord_no         , -- rand_pick_y
  -- --   -100010000 - a_ord   as back_node_no 
  -- -- from generate_series(1, 10) tb_a_ord(a_ord)
  -- -- union all
  -- -- select 
  -- --   -000000002          as work_no             ,
  -- --   -100030001           as fore_node_no     ,
  -- --   a_ord               as path_ord_no         , -- agg_concat_y
  -- --   -100020000 - a_ord   as back_node_no 
  -- -- from generate_series(1, 10) tb_a_ord(a_ord)
  -- -- union all
  -- -- select 
  -- --   -000000002          as work_no             ,
  -- --   -101010000 - a_ord   as fore_node_no     ,
  -- --   1                   as path_ord_no         , -- conv_2d   p1
  -- --   -100030001           as back_node_no 
  -- -- from generate_series(1, 6) tb_a_ord(a_ord)
  
  select 
    -000000002          as work_no             ,
    -101010000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- conv_2d   p1
    -100000000           as back_node_no 
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -101010000 - a_ord   as fore_node_no     ,
    2                   as path_ord_no         , -- conv_2d   p2
    -100030100 - a_ord   as back_node_no 
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -101020000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- zscore_x
    -101010000 - a_ord   as back_node_no 
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -101030000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- leaky_relu
    -101020000 - a_ord   as back_node_no 
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -102010000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- pool_max
    -101030000 - a_ord   as back_node_no 
  from generate_series(1, 6) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -103010000 - ((a_ord_1 - 1) * 10) - a_ord_2 
                        as fore_node_no     ,
    1                   as path_ord_no         , -- conv_2d
    -102010000 - a_ord_1 as back_node_no 
  from generate_series(1, 6) tb_a_ord_1(a_ord_1)
    , generate_series(1, 10) tb_a_ord_2(a_ord_2)
  union all
  select 
    -000000002          as work_no             ,
    -103010000 - a_ord   as fore_node_no     ,
    2                   as path_ord_no         , -- conv_2d   p2
    -102010100 - a_ord   as back_node_no 
  from generate_series(1, 60) tb_a_ord(a_ord)
  
  
  
  -- 6 * 10路 back 数据 分组聚合为16路 fore 数据的映射关系如下
  -- |      | 01  02  03  04  05  06 | 07  08  09  10  11  12 | 13  14  15 | 16
  -- |------|------------------------------------------------------------------
  -- |01-10 | 01              02  03 | 04          05  06  07 | 08      09 | 10
  -- |11-20 | 11  12              13 | 14  15          16  17 | 18  19     | 20
  -- |21-30 | 21  22  23             | 24  25  26          27 |     28  29 | 30
  -- |31-40 |     31  32  33         | 34  35  36  37         | 38      39 | 40
  -- |41-50 |         41  42  43     |     44  45  46  47     | 48  49     | 50
  -- |51-60 |             51  52  53 |         54  55  56  57 |     58  59 | 60
  
  union all
  select 
    -000000002          as work_no             ,
    -104010001           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 01
    -103010000 - a_ord   as back_node_no 
  from unnest(array[01, 11, 21]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010002           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 02
    -103010000 - a_ord   as back_node_no 
  from unnest(array[12, 22, 31]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010003           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 03
    -103010000 - a_ord   as back_node_no 
  from unnest(array[23, 32, 41]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010004           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 04
    -103010000 - a_ord   as back_node_no 
  from unnest(array[33, 42, 51]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010005           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 05
    -103010000 - a_ord   as back_node_no 
  from unnest(array[02, 43, 52]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010006           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 06
    -103010000 - a_ord   as back_node_no 
  from unnest(array[03, 13, 53]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010007           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 07
    -103010000 - a_ord   as back_node_no 
  from unnest(array[04, 14, 24, 34]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010008           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 08
    -103010000 - a_ord   as back_node_no 
  from unnest(array[15, 25, 35, 44]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010009           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 09
    -103010000 - a_ord   as back_node_no 
  from unnest(array[26, 36, 45, 54]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010010           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 10
    -103010000 - a_ord   as back_node_no 
  from unnest(array[05, 37, 46, 55]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010011           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 11
    -103010000 - a_ord   as back_node_no 
  from unnest(array[06, 16, 47, 56]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010012           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 12
    -103010000 - a_ord   as back_node_no 
  from unnest(array[07, 17, 27, 57]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010013           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 13
    -103010000 - a_ord   as back_node_no 
  from unnest(array[08, 18, 38, 48]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010014           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 14
    -103010000 - a_ord   as back_node_no 
  from unnest(array[19, 28, 49, 58]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010015           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 15
    -103010000 - a_ord   as back_node_no 
  from unnest(array[09, 29, 39, 59]) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104010016           as fore_node_no     ,
    row_number() over() as path_ord_no         , -- agg_sum, fore 16
    -103010000 - a_ord   as back_node_no 
  from unnest(array[10, 20, 30, 40, 50, 60]) tb_a_ord(a_ord)
  
  union all
  select 
    -000000002          as work_no             ,
    -104020000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- zscore_x
    -104010000 - a_ord   as back_node_no 
  from generate_series(1, 16) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -104030000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- leaky_relu
    -104020000 - a_ord   as back_node_no 
  from generate_series(1, 16) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -105010000 - a_ord   as fore_node_no     ,
    1                   as path_ord_no         , -- pool_max
    -104030000 - a_ord   as back_node_no 
  from generate_series(1, 16) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -105020001           as fore_node_no     ,
    a_ord               as path_ord_no         , -- agg_concat_x
    -105010000 - a_ord   as back_node_no 
  from generate_series(1, 16) tb_a_ord(a_ord)
  union all
  select 
    -000000002          as work_no             ,
    -106010001           as fore_node_no     ,
    1                   as path_ord_no         , -- prod_mx p1
    -105020001           as back_node_no 
  union all
  select 
    -000000002          as work_no             ,
    -106010001           as fore_node_no     ,
    2                   as path_ord_no         , -- prod_mx p2
    -105020101           as back_node_no 
  union all
  select 
    -000000002          as work_no             ,
    -106020001           as fore_node_no     ,
    1                   as path_ord_no         , -- zscore_x
    -106010001           as back_node_no 
  union all
  select 
    -000000002          as work_no             ,
    -106030001           as fore_node_no     ,
    1                   as path_ord_no         , -- leaky_relu
    -106020001           as back_node_no 
  union all
  select 
    -000000002          as work_no             ,
    -107010001           as fore_node_no     ,
    1                   as path_ord_no         , -- prod_mx p1
    -106030001           as back_node_no 
  union all
  select 
    -000000002          as work_no             ,
    -107010001           as fore_node_no     ,
    2                   as path_ord_no         , -- prod_mx p1
    -106030101           as back_node_no 
  union all
  select 
    -000000002          as work_no             ,
    -200000000           as fore_node_no     ,
    1                   as path_ord_no         , -- softmax_x
    -107010001           as back_node_no 
  ;
  commit;
  
  -- -- 配置协参
  
  -- -- 移步至 prepare 脚本之前，配置随机小批量的每个分类样本数量
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set 
  -- --   node_fn_asso_value = 
  -- --     array
  -- --     [
  -- --       array[1    , 5924 , 12666, 18624, 24755, 30597, 36018, 41936, 48201, 54053],
  -- --       -- array[200  , 6124 , 12866, 18824, 24955, 30797, 36218, 42136, 48401, 54253],
  -- --       array[5923 , 12665, 18623, 24754, 30596, 36017, 41935, 48200, 54052, 60001],
  -- --       array_fill(v_batch_amt, array[10])
  -- --     ]
  -- -- where node_fn_type = 'buff_slice_rand_pick'
  -- --   and node_type = 'input'
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  
  
  -- update sm_sc.tb_nn_node tb_node
  -- set node_fn_asso_value = array[, ]
  -- where node_fn_type = 'elu'
  --   and work_no = -000000002
  -- ;
  
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[0.01]
  -- -- where node_fn_type = '03_leaky_relu'
  -- --   and work_no = -000000002
  -- -- ;
  
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[28, 5, 5, 1, 1, 2, 2, 2, 2, 0]   -- -- , 28 * 28
  -- -- where node_fn_type = '05_conv_2d_grp_x'
  -- --   and node_no between -101010006 and -101010001
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[14, 5, 5, 1, 1, 0, 0, 0, 0, null]    -- -- , 14 * 14
  -- -- where node_fn_type = '05_conv_2d_grp_x'
  -- --   and node_no between -103010060 and -103010001
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  
  -- update sm_sc.tb_nn_node tb_node
  -- set node_fn_asso_value = array[, ]
  -- where node_fn_type = 'rand_pick_x'
  --   and work_no = -000000002
  -- ;
  
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[v_batch_amt]  -- 每个分类 v_batch_amt 个样本，单轮训练集合计 v_batch_amt * 10 个样本
  -- -- where node_fn_type = 'rand_pick_y'
  -- --   and node_no between 100020001 and 100020010
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  
  -- update sm_sc.tb_nn_node tb_node
  -- set node_fn_asso_value = array[, ]
  -- where node_fn_type = 'slice_x'
  --   and work_no = -000000002
  -- ;
  
  
  
  
  
  
  
  -- 审计训练集
  -- -- with 
  -- -- cte_row_num as
  -- -- (
  -- --   select 
  -- -- 	num, 
  -- -- 	row_number() over(order by num) as row_no
  -- --   from sm_dat.tb_tmp_mnist_000000002 
  -- -- )
  -- -- select 
  -- --   num,
  -- --   min(row_no) as range_low, 
  -- --   max(row_no) as range_high
  -- -- from cte_row_num
  -- -- group by num
  
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set 
  -- --   node_fn_asso_value = 
  -- --   -- 数据集按照分类排序后，各类别数量位置编号上下界
  -- --     case node_no
  -- --       when 100010001
  -- --         then array[001, 100] -- array[1, 5923]
  -- --       when 100010002
  -- --         then array[101, 200] -- array[5924, 12665]
  -- --       when 100010003
  -- --         then array[201, 300] -- array[12666, 18623]
  -- --       when 100010004
  -- --         then array[301, 400] -- array[18624, 24754]
  -- --       when 100010005
  -- --         then array[401, 500] -- array[24755, 30596]
  -- --       when 100010006
  -- --         then array[501, 600] -- array[30597, 36017]
  -- --       when 100010007
  -- --         then array[601, 700] -- array[36018, 41935]
  -- --       when 100010008
  -- --         then array[701, 800] -- array[41936, 48200]
  -- --       when 100010009
  -- --         then array[801, 900] -- array[48201, 54052]
  -- --       when 100010010
  -- --         then array[901, 1000]-- array[54053, 60001]
  -- --     end
  -- -- where node_fn_type = 'slice_y'
  -- --   and node_no between 100010001 and 100010010
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[28, 2, 2, 2, 2, 0, 0, 0, 0, null, 28 * 28]
  -- -- where node_fn_type = '05_pool_max_2d_grp_x'
  -- --   and node_no between -102010006 and -102010001
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[10, 2, 2, 2, 2, 0, 0, 0, 0, null, 10 * 10]
  -- -- where node_fn_type = '05_pool_max_2d_grp_x'
  -- --   and node_no between -105010016 and -105010001
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  
  -- update sm_sc.tb_nn_node tb_node
  -- set node_fn_asso_value = array[, ]
  -- where node_fn_type = 'pool_avg'
  --   and work_no = -000000002
  -- ;
  
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[null, 16 * 5 * 5, 64]
  -- -- where node_fn_type = '01_prod_mx'
  -- --   and node_no = -106010001
  -- --   and work_no = -000000002
  -- -- ;
  -- -- commit;
  -- -- update sm_sc.tb_nn_node tb_node
  -- -- set node_fn_asso_value = array[null, 64, 10]
  -- -- where node_fn_type = '01_prod_mx'
  -- --   and node_no = -107010001
  -- --   and work_no = -000000002
  -- -- ;
  commit;

end
$$
language plpgsql;