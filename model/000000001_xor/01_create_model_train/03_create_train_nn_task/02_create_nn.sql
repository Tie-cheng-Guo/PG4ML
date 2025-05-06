          delete from sm_sc.tb_nn_node where work_no = -000000001;commit;
          -- 构造 xor 节点
          insert into sm_sc.tb_nn_node
          (
            work_no
          , node_no
          , node_type
          , node_fn_type
          , node_fn_asso_value
          , node_desc
          )
          select 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , 'input_01'                           as node_type      
          , '00_buff_slice_rand_pick'            as node_fn_type
          , null                                 as node_fn_asso_value
          , '1_0'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '00_const'                           as node_fn_type
          , array[1.0]                           as node_fn_asso_value
          , '2_0'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '06_aggr_mx_concat_x'                as node_fn_type
          , array[1, 2]                          as node_fn_asso_value
          , '3_1'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , 'weight'                             as node_type      
          , '00_const'                           as node_fn_type
          , array[3, 2]                          as node_fn_asso_value
          , '3_2'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '01_prod_mx'                         as node_fn_type
          , array[null, 3, 2]                    as node_fn_asso_value
          , '4_1'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '00_const'                           as node_fn_type
          , array[1.0]                           as node_fn_asso_value
          , '5_0'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '03_sigmoid'                         as node_fn_type            -- '03_absqrt'       -- absqrt 和 [0.5, 0.5] 的超参数配置也 ok
          , null                                 as node_fn_asso_value      -- array[0.5, 0.5]
          , '5_1'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '06_aggr_mx_concat_x'                as node_fn_type
          , array[1, 2]                          as node_fn_asso_value
          , '6_1'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , 'weight'                             as node_type      
          , '00_const'                           as node_fn_type
          , array[3, 1]                          as node_fn_asso_value
          , '6_2'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , null                                 as node_type      
          , '01_prod_mx'                         as node_fn_type
          , array[null, 3, 1]                    as node_fn_asso_value
          , '7_1'                                as node_desc
          union all                              
          select                                 
            -000000001                               as work_no        
          , lower(sm_sc.fv_get_global_seq())     as node_no        
          , 'output_01'                          as node_type      
          , '03_sigmoid'                         as node_fn_type            -- '03_absqrt'    
          , null                                 as node_fn_asso_value      -- array[0.5, 0.5]
          , '8_1'                                as node_desc
          ;
          commit;
          
          delete from sm_sc.tb_nn_path where work_no = -000000001;commit;   
          -- 构造 xor 路径
          insert into sm_sc.tb_nn_path
          (
            work_no     
          , fore_node_no
          , path_ord_no 
          , back_node_no
          )
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 1                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '3_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '2_0' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 2                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '3_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '1_0' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 1                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '4_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '3_1' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 2                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '4_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '3_2' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 1                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '5_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '4_1' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 1                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '6_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '5_0' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 2                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '6_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '5_1' and tb_a_back_node.work_no = -000000001
          union all  
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 1                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '7_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '6_1' and tb_a_back_node.work_no = -000000001
          union all  
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 2                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '7_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '6_2' and tb_a_back_node.work_no = -000000001
          union all
          select 
            -000000001                            as work_no          
          , tb_a_fore_node.node_no            as fore_node_no
          , 1                                 as path_ord_no 
          , tb_a_back_node. node_no           as back_node_no
          from sm_sc.tb_nn_node tb_a_fore_node
            , sm_sc.tb_nn_node tb_a_back_node
          where tb_a_fore_node.node_desc = '8_1' and tb_a_fore_node.work_no = -000000001
            and tb_a_back_node.node_desc = '7_1' and tb_a_back_node.work_no = -000000001
          ;
          commit;
          
          -- 非权重参数的 00_const 的初始化
          update sm_sc.tb_nn_node
          set 
            -- node_depdt_vals = array[[1]]
            p_node_depdt = sm_sc.__fv_set_kv(array[[1]])
          -- , node_fn_asso_value = 
          --     array [1]
          where node_fn_type = '00_const' and node_type is distinct from 'weight'
            and node_desc in ('2_0', '5_0')
            and work_no = -000000001  
          ;
          commit;