do
$$
declare
  v_cnt_layer_ex   int   := 3;    -- 最后一大层单独计数，不计入 v_cnt_layer_ex，2 + 1 层性价比最高
  v_add_rank_width int   := 21;   -- 高宽尺度的一半左右，性价比最高
begin
  delete from sm_sc.tb_nn_node where work_no = -000000019;
  delete from sm_sc.tb_nn_path where work_no = -000000019;
  commit;
  
  -- 构造节点
  insert into sm_sc.tb_nn_node
  (
    work_no
  , node_no
  , node_type
  , node_fn_type       
  , node_fn_asso_value
  -- , node_desc
  )
  -- rand_pick input
  select 
    -000000019                                               as work_no                
  , -100000000                                               as node_no
  , 'input_01'                                               as node_type                   
  , '00_buff_slice_rand_pick'                                as node_fn_type
  , null                                                     as node_fn_asso_value
  -- , ''                                                       as node_desc

  -- N 大层残差隧道卷乘
  -- 第一小层非线性隧道卷乘
  union all
  -- 维轴 4
  select 
    -000000019                                               as work_no                
  , -200000002 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[2, 42, 42+ v_add_rank_width]                                         as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200000003 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[2, 1, 42+ v_add_rank_width]                                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200100001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  -- 维轴 3
  select 
    -000000019                                               as work_no                
  , -200100002 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 42, 42+ v_add_rank_width]                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200100003 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 1, 42+ v_add_rank_width]                  as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200200001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  -- 维轴 2
  select 
    -000000019                                               as work_no                
  , -200200002 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 2 + 1, 1, 1]                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200200003 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 1, 1]                                    as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200300001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all                                                  
  -- 重分布
  select                                                     
    -000000019                                               as work_no                
  , -200400001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '03_zscore'                                              as node_fn_type
  , array[1, 2 + 1, 42+ v_add_rank_width, 42+ v_add_rank_width]                                      as node_fn_asso_value
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all                                                  
  -- 激活
  select                                                     
    -000000019                                               as work_no                
  , -200500001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '03_absqrt'                                              as node_fn_type
  , array[0.99, 0.99]                                        as node_fn_asso_value
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all 
  -- 残差
  select                                                     
    -000000019                                               as work_no                
  , -200600001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '01_add'                                                 as node_fn_type
  , null                                                     as node_fn_asso_value
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  
  -- 第二小层非线性隧道卷乘
  union all
  -- 维轴 4
  select 
    -000000019                                               as work_no                
  , -200010002 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 1, 42+ v_add_rank_width, 42]             as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200010003 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 1, 1, 42]                                as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200110001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  -- 维轴 3
  select 
    -000000019                                               as work_no                
  , -200110002 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 42+ v_add_rank_width, 42, 1]             as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200110003 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 42, 1]                                   as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200210001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  -- 维轴 2
  select 
    -000000019                                               as work_no                
  , -200210002 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 2, 1, 1]                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200210003 - (a_no * 1000000)                            as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 1]                                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all
  select 
    -000000019                                               as work_no                
  , -200310001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  union all                                                  
  -- 重分布
  select                                                     
    -000000019                                               as work_no                
  , -200410001 - (a_no * 1000000)                            as node_no
  , null                                                     as node_type                   
  , '03_zscore'                                              as node_fn_type
  , array[1, 2, 42, 42]                                      as node_fn_asso_value
  -- , ''                                                       as node_desc
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  -- union all                                                  
  -- -- 激活
  -- select                                                     
  --   -000000019                                               as work_no                
  -- , -200510001 - (a_no * 1000000)                            as node_no
  -- , null                                                     as node_type                   
  -- , '03_absqrt'                                              as node_fn_type
  -- , array[0.99, 0.99]                                        as node_fn_asso_value
  -- -- , ''                                                       as node_desc
  -- from generate_series(1, v_cnt_layer_ex) tb_a(a_no)
  
  
  -- 最后一层隧道卷乘
  -- 第一小层
  union all
  -- 维轴 4
  select 
    -000000019                                               as work_no                
  , -299000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 42, 42+ v_add_rank_width]                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 42+ v_add_rank_width]                     as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000019                                               as work_no                
  , -299100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 42, 42+ v_add_rank_width, 1]                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 42+ v_add_rank_width, 1]                     as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000019                                               as work_no                
  , -299200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 2 + 1, 1, 1]                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000019                                               as work_no                
  , -299200003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 1, 1]                                    as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  
  -- 第二小层
  union all
  -- 维轴 4
  select 
    -000000019                                               as work_no                
  , -299010002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 1, 42+ v_add_rank_width, 42]             as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299010003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 1, 42]                                   as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299110001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000019                                               as work_no                
  , -299110002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 42+ v_add_rank_width, 42, 1]             as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299110003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 42, 1]                                   as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299210001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000019                                               as work_no                
  , -299210002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2 + 1, 2, 1, 1]                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000019                                               as work_no                
  , -299210003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 1]                                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000019                                               as work_no                
  , -299310001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  
  union all 
  -- 最后的残差，以及输出
  select                                                     
    -000000019                                               as work_no                
  , -299400001                                               as node_no
  , 'output_01'                                              as node_type                   
  , '01_add'                                                 as node_fn_type
  , null                                                     as node_fn_asso_value
  -- , ''                                                       as node_desc
  -- -- union all                                                  
  -- -- -- 重分布
  -- -- select                                                     
  -- --   -000000019                                               as work_no                
  -- -- , -299400001                                               as node_no
  -- -- , 'output_01'                                                     as node_type                   
  -- -- , '03_zscore'                                              as node_fn_type
  -- -- , array[1, 2, 28, 28]                                         as node_fn_asso_value
  -- -- -- , ''                                                       as node_desc
  
  -- -- union all                                                  
  -- -- -- 激活
  -- -- select                                                     
  -- --   -000000019                                               as work_no                
  -- -- , -299500001                                               as node_no
  -- -- , 'output_01'                                                     as node_type                   
  -- -- , '03_absqrt'                                              as node_fn_type
  -- -- , null                            as node_fn_asso_value
  -- -- -- , ''                                                       as node_desc
  
  
  -- -- union all                                                  
  -- -- select                                                     
  -- --   -000000019                                               as work_no              
  -- -- , -900000000                                               as node_no
  -- -- , 'output_01'                                              as node_type        
  -- -- , '03_softmax_ex'                                          as node_fn_type           
  -- -- , array[1, 1, 1, 10]                                       as node_fn_asso_value
  -- -- -- , ''                                                       as node_desc
  ;
  commit;
  
  -- 构造路径
  insert into sm_sc.tb_nn_path
  (
    work_no              ,
    fore_node_no         ,
    path_ord_no          ,
    back_node_no
  )

  -- 卷乘大层
  select                                                                                       
    -000000019                                                                                 as work_no             
  , -200100001 - (1 * 1000000)                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -100000000                                                                                 as back_node_no 
  
  union all
  select                                                                                       
    -000000019                                                                                 as work_no             
  , -200600001 - (1 * 1000000)                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -100000000                                                                                 as back_node_no
  
  -- 卷乘大层，第一小层
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200100001 - (a_no * 1000000)                                                              as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -200000002 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)     
  
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200100001 - (a_no * 1000000)                                                              as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -200000003 - (a_no * 1000000)                                                              as back_node_no
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)      
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200200001 - (a_no * 1000000)                                                              as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -200100001 - (a_no * 1000000)                                                              as back_node_no  
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)      
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200200001 - (a_no * 1000000)                                                              as fore_node_no
  , 2                                                                                          as path_ord_no 
  , -200100002 - (a_no * 1000000)                                                              as back_node_no
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)          
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200200001 - (a_no * 1000000)                                                              as fore_node_no
  , 3                                                                                          as path_ord_no 
  , -200100003 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)        
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200300001 - (a_no * 1000000)                                                              as fore_node_no
  , 1                                                                                          as path_ord_no 
  , -200200001 - (a_no * 1000000)                                                              as back_node_no       
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)       
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200300001 - (a_no * 1000000)                                                              as fore_node_no
  , 2                                                                                          as path_ord_no 
  , -200200002 - (a_no * 1000000)                                                              as back_node_no          
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)            
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200300001 - (a_no * 1000000)                                                              as fore_node_no
  , 3                                                                                          as path_ord_no 
  , -200200003 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)        
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200400001 - (a_no * 1000000)                                                              as fore_node_no
  , 1                                                                                          as path_ord_no 
  , -200300001 - (a_no * 1000000)                                                              as back_node_no       
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)            
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200500001 - (a_no * 1000000)                                                              as fore_node_no
  , 1                                                                                          as path_ord_no 
  , -200400001 - (a_no * 1000000)                                                              as back_node_no       
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)            
  
  -- 卷乘大层，第二小层
  union all
  select                                                                                       
    -000000019                                                                                 as work_no             
  , -200110001 - (a_no * 1000000)                                                              as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -200500001 - (a_no * 1000000)                                                              as back_node_no      
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)     
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200110001 - (a_no * 1000000)                                                              as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -200010002 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)     
  
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200110001 - (a_no * 1000000)                                                              as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -200010003 - (a_no * 1000000)                                                              as back_node_no
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)      
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200210001 - (a_no * 1000000)                                                              as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -200110001 - (a_no * 1000000)                                                              as back_node_no  
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)      
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200210001 - (a_no * 1000000)                                                              as fore_node_no
  , 2                                                                                          as path_ord_no 
  , -200110002 - (a_no * 1000000)                                                              as back_node_no
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)          
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200210001 - (a_no * 1000000)                                                              as fore_node_no
  , 3                                                                                          as path_ord_no 
  , -200110003 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)        
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200310001 - (a_no * 1000000)                                                              as fore_node_no
  , 1                                                                                          as path_ord_no 
  , -200210001 - (a_no * 1000000)                                                              as back_node_no       
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)       
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200310001 - (a_no * 1000000)                                                              as fore_node_no
  , 2                                                                                          as path_ord_no 
  , -200210002 - (a_no * 1000000)                                                              as back_node_no          
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)            
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200310001 - (a_no * 1000000)                                                              as fore_node_no
  , 3                                                                                          as path_ord_no 
  , -200210003 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)        
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200410001 - (a_no * 1000000)                                                              as fore_node_no
  , 1                                                                                          as path_ord_no 
  , -200310001 - (a_no * 1000000)                                                              as back_node_no       
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)            
      
  -- union all                                                                                    
  -- select                                                                                   
  --   -000000019                                                                                 as work_no       
  -- , -200510001 - (a_no * 1000000)                                                              as fore_node_no
  -- , 1                                                                                          as path_ord_no 
  -- , -200410001 - (a_no * 1000000)                                                              as back_node_no       
  -- from generate_series(1, v_cnt_layer_ex) tb_a(a_no)          
      
  -- 残差传递成分2，来自第二小层
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200600001 - (a_no * 1000000)                                                              as fore_node_no
  , 2                                                                                          as path_ord_no 
  , -200410001 - (a_no * 1000000)                                                              as back_node_no       
  from generate_series(1, v_cnt_layer_ex) tb_a(a_no)     
  
  -- 残差传递成分1，来自上一大层
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200600001 - ((a_no + 1) * 1000000)                                                        as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -200600001 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex - 1) tb_a(a_no)     
      
  -- 残差传递道下一大层
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -200100001 - ((a_no + 1) * 1000000)                                                        as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -200600001 - (a_no * 1000000)                                                              as back_node_no        
  from generate_series(1, v_cnt_layer_ex - 1) tb_a(a_no)     
  
  -- 最后大层，第一小层
  union all
  select                                                                                       
    -000000019                                                                                 as work_no             
  , -299100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -200600001 - (v_cnt_layer_ex * 1000000)                                                    as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299000002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299000003                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299100002                                                                                 as back_node_no         
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299100003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299200002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299300001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299200003                                                                                 as back_node_no  
  
  -- 最后大层第二小层
  union all
  select                                                                                       
    -000000019                                                                                 as work_no             
  , -299110001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -299300001                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299110001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299010002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299110001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299010003                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299210001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299110001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299210001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299110002                                                                                 as back_node_no         
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299210001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299110003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299310001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299210001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299310001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299210002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299310001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299210003                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000019                                                                                 as work_no       
  , -299400001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299310001                                                                                 as back_node_no    

  union all
  select                                                                                       
    -000000019                                                                                 as work_no             
  , -299400001                                                                                 as fore_node_no
  , 2                                                                                          as path_ord_no         
  , -200600001 - (v_cnt_layer_ex * 1000000)                                                    as back_node_no     
      
  -- -- union all                                                                                    
  -- -- select                                                                                   
  -- --   -000000019                                                                                 as work_no       
  -- -- , -900000000                                                                                 as fore_node_no      
  -- -- , 1                                                                                          as path_ord_no 
  -- -- , -299400001                                                                                 as back_node_no  
  ;
  commit;

end
$$
language plpgsql;
