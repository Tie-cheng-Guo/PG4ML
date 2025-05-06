1. 导出推理模型: 
  do
  $$
    declare 
      v_work_no         int   := -000000002;
      v_model_node      text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/02_import_infer_model/model_back_up/sm_sc.__vt_nn_node_000000002.gz';
      v_model_path      text  := '/var/lib/pgsql/model/000000002_mnist_lenet5_batchnorm/02_import_infer_model/model_back_up/sm_sc.__vt_nn_path_000000002.gz';
    begin
      call 
      sm_sc.prc_export_infer_model_p
      (
        v_work_no
      , v_model_node
      , v_model_path
      )
      ;
    end
  $$
  language plpgsql