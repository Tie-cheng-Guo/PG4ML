以下是仅用于演示的部署推理和用于开发调用的部署推理步骤：
准备条件: 
  首先安装 pg4ml 深度学习框架。
一、准备预训练模型
  1. 导入预训练模型，有如下两种方式任选其一: 
    a. 第一种方式是: 从预训练模型文件导入: 
      修改填入模型文件路径 v_model_task, v_model_node, v_model_path, v_model_train_dateset
      do
      $$
        declare
          v_work_no              int   := -000000002;
          v_model_task           text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/01_import_pre_train_model/model_back_up/sm_sc.tb_classify_task_000000002.gz';
          v_model_node           text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_node_000000002.gz';
          v_model_path           text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_path_000000002.gz';
          v_model_array_kv_file  text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/01_import_pre_train_model/model_back_up/sm_sc.__vt_array_kv_000000002.gz';
          v_model_train_dateset  text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_train_input_buff_000000002.gz';
        begin
          call
          sm_sc.prc_import_pretrain_model_p
          (
            v_work_no            
          , v_model_task         
          , v_model_node         
          , v_model_path      
          , v_model_array_kv_file        
          , v_model_train_dateset
          )
          ;
        end
      $$
      language plpgsql
      
    b. 第二种方式: 从推理模型生成预训练模型(推理模型的来源，参看 \plpgsql_pg4ml\model\000000002_mnist_lenet5_batchnorm\02_import_infer_model\readme\): 
      call 
        sm_sc.prc_add_pretrain_from_infer_p
        (
          -000000002
        , '201'
        );
        
      -- 准备训练集: 
      delete from sm_sc.tb_nn_train_input_buff where work_no = -000000002; commit;
      copy               
        sm_sc.tb_nn_train_input_buff 
        (
          work_no      
        , ord_no       
        , i_depdt_01   
        , i_depdt_02   
        , i_depdt_03   
        , i_depdt_04   
        , i_indepdt_01 
        , i_indepdt_02 
        , i_indepdt_03 
        , i_indepdt_04 
        , i_dataset_dtl
        )
      from program       'gzip -d < /var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_train_input_buff_000000002.gz' 
      delimiter          '|' 
      encoding           'UTF8' 
      csv
      header
      ;
  
  2. 训练准备: 
    call sm_sc.prc_nn_prepare_p
    (
      i_work_no             =>  -000000002  
    , i_limit_train_times   =>  5              
    , i_batch_amt_per_range =>  array_fill(8, array[10])  
    , i_batch_range         =>  
      array
      [
        int4range(    1,  4000, '[]')
      , int4range( 5924,  9924, '[]')
      , int4range(12666, 16666, '[]')
      , int4range(18624, 22624, '[]')
      , int4range(24755, 28755, '[]')
      , int4range(30597, 34597, '[]')
      , int4range(36018, 40018, '[]')
      , int4range(41936, 45936, '[]')
      , int4range(48201, 52201, '[]')
      , int4range(54053, 58053, '[]')
      --   array[1    , 5924 , 12666, 18624, 24755, 30597, 36018, 41936, 48201, 54053]
      -- , array[4000 , 9924 , 16666, 22624, 28755, 34597, 40018, 45936, 52201, 58053]   -- 每类别 4000 共 40000， 当做训练集
      ]
    );
  
  3. 执行训练: 
    call sm_sc.prc_nn_train_p
    (
      i_work_no                         =>  -000000002
    , i_learn_rate                      =>  0.00084
    , i_loss_delta_least_stop_threshold =>  0.001
    );
    
  4. 调整 i_limit_train_times, i_learn_rate 等训练任务超参数，重复执行步骤 2, 3；
  
二、验证预训练模型方法参考: 
  plpgsql_pg4ml_dev\model\000000002_mnist_lenet5_batchnorm\02_import_infer_model\readme\for_test_infer\readme_for_import_test_infer.txt
  第一章 -> 第 2 节