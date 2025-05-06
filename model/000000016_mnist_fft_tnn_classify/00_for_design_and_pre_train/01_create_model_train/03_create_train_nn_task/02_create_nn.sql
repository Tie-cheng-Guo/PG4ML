do
$$
-- declare
begin
  delete from sm_sc.tb_nn_node where work_no = -000000016;
  delete from sm_sc.tb_nn_path where work_no = -000000016;
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
    -000000016                                               as work_no                
  , -100000000                                               as node_no
  , 'input_01'                                               as node_type                   
  , '00_buff_slice_rand_pick'                                as node_fn_type
  , null :: decimal[]                                        as node_fn_asso_value
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -100000101                                               as node_no
  , null                                                     as node_type                   
  , '04_slice_x'                                         as node_fn_type
  , array[[2], [3]]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc

  -- 第一大层隧道卷乘  增秩-1   2 * 28 * 28 -> 4 * 32 * 36
  union all
  -- 维轴 4
  select 
    -000000016                                               as work_no                
  , -201000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 28, 36] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -201000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 36] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -201100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000016                                               as work_no                
  , -201100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 28, 32, 1] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -201100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 32, 1] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -201200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -201200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 4, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -201200003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 1, 1] :: decimal[]                           as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -201300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all                                                  
  -- 重分布
  select                                                     
    -000000016                                               as work_no                
  , -201400001                                               as node_no
  , null                                                     as node_type                   
  , '03_zscore'                                              as node_fn_type
  , array[1, 4, 32, 36] :: decimal[]                            as node_fn_asso_value
  -- , ''                                                       as node_desc
  union all                                                  
  -- 激活
  select                                                     
    -000000016                                               as work_no                
  , -201500001                                               as node_no
  , null                                                     as node_type                   
  , '03_absqrt'                                              as node_fn_type
  , array[0.5, 0.0]                            as node_fn_asso_value
  -- , ''                                                       as node_desc
  
  -- 第二大层隧道卷乘  增秩-2  4 * 32 * 36 -> 6 * 40 * 48
  union all
  -- 维轴 4
  select 
    -000000016                                               as work_no                
  , -202000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 1, 36, 48] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -202000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 1, 48] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -202100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000016                                               as work_no                
  , -202100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 32, 40, 1] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -202100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 40, 1] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -202200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -202200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 6, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -202200003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 6, 1, 1] :: decimal[]                           as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -202300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
   union all                                                  
   -- 重分布
   select                                                     
     -000000016                                               as work_no                
   , -202400001                                               as node_no
   , null                                                     as node_type                   
   , '03_zscore'                                              as node_fn_type
   , array[1, 6, 40, 48] :: decimal[]                         as node_fn_asso_value
   -- , ''                                                       as node_desc
  union all                                                  
  -- 激活
  select                                                     
    -000000016                                               as work_no                
  , -202500001                                               as node_no
  , null                                                     as node_type                   
  , '03_absqrt'                                              as node_fn_type
  , array[0.5, 0.0]                                          as node_fn_asso_value
  -- , ''                                                       as node_desc
  
  -- 第三大层隧道卷乘  增秩-3  6 * 40 * 48 -> 8 * 48 * 64
  union all
  -- 维轴 4
  select 
    -000000016                                               as work_no                
  , -203000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 6, 1, 48, 64] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -203000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 6, 1, 64] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -203100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000016                                               as work_no                
  , -203100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 6, 40, 48, 1] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -203100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 6, 48, 1] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -203200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -203200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 6, 8, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -203200003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 8, 1, 1] :: decimal[]                           as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -203300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all                                                  
  -- 重分布
  select                                                     
    -000000016                                               as work_no                
  , -203400001                                               as node_no
  , null                                                     as node_type                   
  , '03_zscore'                                              as node_fn_type
  , array[1, 8, 48, 64] :: decimal[]                         as node_fn_asso_value
  -- , ''                                                       as node_desc
  union all                                                  
  -- 激活
  select                                                     
    -000000016                                               as work_no                
  , -203500001                                               as node_no
  , null                                                     as node_type                   
  , '03_absqrt'                                              as node_fn_type
  , array[0.5, 0.0]                                          as node_fn_asso_value
  -- , ''                                                       as node_desc
  
  -- 第四大层隧道卷乘  减秩-51  8 * 48 * 64 -> 4 * 16 * 32
  union all
  -- 维轴 4
  select 
    -000000016                                               as work_no                
  , -251000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 8, 1, 64, 32] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -251000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 8, 1, 32] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -251100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000016                                               as work_no                
  , -251100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 8, 48, 16, 1] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -251100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 8, 16, 1] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -251200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -251200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 8, 4, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -251200003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 1, 1] :: decimal[]                           as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -251300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all                                                  
  -- 重分布
  select                                                     
    -000000016                                               as work_no                
  , -251400001                                               as node_no
  , null                                                     as node_type                   
  , '03_zscore'                                              as node_fn_type
  , array[1, 4, 16, 32] :: decimal[]                         as node_fn_asso_value
  -- , ''                                                       as node_desc
  union all                                                  
  -- 激活
  select                                                     
    -000000016                                               as work_no                
  , -251500001                                               as node_no
  , null                                                     as node_type                   
  , '03_absqrt'                                              as node_fn_type
  , array[0.5, 0.0]                                          as node_fn_asso_value
  -- , ''                                                       as node_desc
  
  -- 第五大层隧道卷乘  减秩-52  4 * 16 * 32 -> 2 * 4 * 20
  union all
  -- 维轴 4
  select 
    -000000016                                               as work_no                
  , -252000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 1, 32, 20] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -252000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 1, 20] :: decimal[]                            as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -252100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000016                                               as work_no                
  , -252100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 16, 4, 1] :: decimal[]                            as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -252100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 4, 1] :: decimal[]                            as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -252200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -252200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 4, 2, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -252200003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 1] :: decimal[]                           as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -252300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all                                                  
  -- 重分布
  select                                                     
    -000000016                                               as work_no                
  , -252400001                                               as node_no
  , null                                                     as node_type                   
  , '03_zscore'                                              as node_fn_type
  , array[1, 2, 4, 20] :: decimal[]                          as node_fn_asso_value
  -- , ''                                                       as node_desc
  union all                                                  
  -- 激活
  select                                                     
    -000000016                                               as work_no                
  , -252500001                                               as node_no
  , null                                                     as node_type                   
  , '03_absqrt'                                              as node_fn_type
  , array[0.5, 0.0]                                          as node_fn_asso_value
  -- , ''                                                       as node_desc
  
  -- 最后大层输出  降秩  2 * 4 * 20 -> 1 * 1 * 10
  union all
  -- 维轴 4
  select 
    -000000016                                               as work_no                
  , -299000002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 20, 10] :: decimal[]                      as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -299000003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 10] :: decimal[]                          as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -299100001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[4]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 3
  select 
    -000000016                                               as work_no                
  , -299100002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 4, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -299100003                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 1] :: decimal[]                           as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -299200001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[3]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  union all
  -- 维轴 2
  select 
    -000000016                                               as work_no                
  , -299200002                                               as node_no
  , 'weight'                                                 as node_type  
  , '00_const'                                               as node_fn_type         
  , array[1, 2, 1, 1, 1] :: decimal[]                        as node_fn_asso_value  
  -- , ''                                                       as node_desc
  -- -- union all
  -- -- -- 维轴 2
  -- -- select 
  -- --   -000000016                                               as work_no                
  -- -- , -299200003                                               as node_no
  -- -- , 'weight'                                                 as node_type  
  -- -- , '00_const'                                               as node_fn_type         
  -- -- , array[1, 1] :: decimal[]                            as node_fn_asso_value  
  -- -- -- , ''                                                       as node_desc
  union all
  select 
    -000000016                                               as work_no                
  , -299300001                                               as node_no
  , null                                                     as node_type                   
  , '05_tunnel_conv'                                         as node_fn_type
  , array[2]                                                 as node_fn_asso_value  
  -- , ''                                                       as node_desc
  -- -- union all                                                  
  -- -- -- 重分布
  -- -- select                                                     
  -- --   -000000016                                               as work_no                
  -- -- , -299400001                                               as node_no
  -- -- , null                                                     as node_type                   
  -- -- , '03_zscore'                                              as node_fn_type
  -- -- , array[1, 1, 1, 10] :: decimal[]                            as node_fn_asso_value
  -- -- -- , ''                                                       as node_desc
  -- -- union all                                                  
  -- -- -- 激活
  -- -- select                                                     
  -- --   -000000016                                               as work_no                
  -- -- , -299500001                                               as node_no
  -- -- , 'output_01'                                                     as node_type                   
  -- -- , '03_absqrt'                                              as node_fn_type
  -- -- , null                            as node_fn_asso_value
  -- -- -- , ''                                                       as node_desc
  
  
  union all                                                  
  select                                                     
    -000000016                                               as work_no              
  , -900000000                                               as node_no
  , 'output_01'                                              as node_type        
  , '03_softmax_ex'                                          as node_fn_type           
  , array[1, 1, 1, 10]                                       as node_fn_asso_value
  -- , ''                                                       as node_desc
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

  -- 第一大层
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -100000101                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -100000000                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -201100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -100000101                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -201000002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -201000003                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -201100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -201100002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -201100003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -201200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -201200002                                                                                 as back_node_no          
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201300001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -201200003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201400001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -201300001                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -201500001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -201400001                                                                                 as back_node_no 
  
  
  -- 第二大层
  union all
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -202100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -201500001                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -202000002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -202000003                                                                                 as back_node_no  
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -202100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -202100002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -202100003                                                                                 as back_node_no     
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -202200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -202200002                                                                                 as back_node_no           
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202300001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -202200003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202400001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -202300001                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -202500001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -202400001                                                                                 as back_node_no 
  
  
  -- 第三大层
  union all
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -203100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -202500001                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -203000002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -203000003                                                                                 as back_node_no     
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -203100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -203100002                                                                                 as back_node_no         
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -203100003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -203200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -203200002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203300001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -203200003                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203400001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -203300001                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -203500001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -203400001                                                                                 as back_node_no  
  
  
  -- 第四大层
  union all
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -251100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -203500001                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -251000002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -251000003                                                                                 as back_node_no     
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -251100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -251100002                                                                                 as back_node_no         
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -251100003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -251200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -251200002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251300001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -251200003                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251400001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -251300001                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -251500001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -251400001                                                                                 as back_node_no   
  
  
  -- 第五大层
  union all
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -252100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -251500001                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -252000002                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -252000003                                                                                 as back_node_no     
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -252100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -252100002                                                                                 as back_node_no         
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -252100003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -252200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -252200002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252300001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -252200003                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252400001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -252300001                                                                                 as back_node_no        
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -252500001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -252400001                                                                                 as back_node_no  
  
  
  -- 最后输出大层
  union all
  select                                                                                       
    -000000016                                                                                 as work_no             
  , -299100001                                                                                 as fore_node_no
  , 1                                                                                          as path_ord_no         
  , -252500001                                                                                 as back_node_no   
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299100001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299000002                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299100001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299000003                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299200001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299100001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299200001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299100002                                                                                 as back_node_no         
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299200001                                                                                 as fore_node_no      
  , 3                                                                                          as path_ord_no 
  , -299100003                                                                                 as back_node_no      
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299300001                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299200001                                                                                 as back_node_no    
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -299300001                                                                                 as fore_node_no      
  , 2                                                                                          as path_ord_no 
  , -299200002                                                                                 as back_node_no        
      
  -- -- union all                                                                                    
  -- -- select                                                                                   
  -- --   -000000016                                                                                 as work_no       
  -- -- , -299300001                                                                                 as fore_node_no      
  -- -- , 3                                                                                          as path_ord_no 
  -- -- , -299200003                                                                                 as back_node_no       
      
  union all                                                                                    
  select                                                                                   
    -000000016                                                                                 as work_no       
  , -900000000                                                                                 as fore_node_no      
  , 1                                                                                          as path_ord_no 
  , -299300001                                                                                 as back_node_no        
      
  -- -- union all                                                                                    
  -- -- select                                                                                   
  -- --   -000000016                                                                                 as work_no       
  -- -- , -299500001                                                                                 as fore_node_no      
  -- -- , 1                                                                                          as path_ord_no 
  -- -- , -299400001                                                                                 as back_node_no  
  ;
  commit;

end
$$
language plpgsql;
