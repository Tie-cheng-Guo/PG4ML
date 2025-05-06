1. 导出推理模型:  修改填入模型文件路径 v_model_task, v_model_node, v_model_path, v_model_train_dateset
  do
  $$
    declare 
      v_work_no              int   := -000000016;
      v_model_task           text  := '/var/lib/pgsql/model/000000016_mnist_fft_bcb_absqrt/01_import_pre_train_model/model_back_up/sm_sc.tb_classify_task_000000016.gz';
      v_model_node           text  := '/var/lib/pgsql/model/000000016_mnist_fft_bcb_absqrt/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_node_000000016.gz';
      v_model_path           text  := '/var/lib/pgsql/model/000000016_mnist_fft_bcb_absqrt/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_path_000000016.gz';
      v_model_array_kv_file  text  := '/var/lib/pgsql/model/000000016_mnist_fft_bcb_absqrt/01_import_pre_train_model/model_back_up/sm_sc.__vt_array_kv_000000016.gz';
      v_model_train_dateset  text  := '/var/lib/pgsql/model/000000016_mnist_fft_bcb_absqrt/01_import_pre_train_model/model_back_up/sm_sc.tb_nn_train_input_buff_000000016.gz';
    begin
      call 
      sm_sc.prc_export_pretrain_model_p
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