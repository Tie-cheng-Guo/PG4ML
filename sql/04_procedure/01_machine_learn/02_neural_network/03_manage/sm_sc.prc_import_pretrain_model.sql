drop procedure if exists sm_sc.prc_import_pretrain_model(bigint, text, text, text, text);
create or replace procedure sm_sc.prc_import_pretrain_model
(
  i_work_no           bigint  ,
  i_model_work_file   text                  
, i_model_node_file   text                  
, i_model_path_file   text                  
, i_train_data_file   text default null     
) as 
$$
declare
begin
  delete from sm_sc.tb_classify_task where work_no = i_work_no;
  commit;
  execute 
    '
      copy               sm_sc.tb_classify_task 
      from program       ''gzip -d < ' || i_model_work_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  delete from sm_sc.tb_nn_node where work_no = i_work_no;
  commit;
  execute 
    '
      copy               sm_sc.tb_nn_node 
      from program       ''gzip -d < ' || i_model_node_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  delete from sm_sc.tb_nn_path where work_no = i_work_no;
  commit;
  execute 
    '
      copy               sm_sc.tb_nn_path 
      from program       ''gzip -d < ' || i_model_path_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  if i_train_data_file is not null 
  then 
    delete from sm_sc.tb_nn_train_input_buff where work_no = i_work_no;
    commit;
    execute 
      '
        copy               sm_sc.tb_nn_train_input_buff 
        from program       ''gzip -d < ' || i_train_data_file || ''' 
        delimiter          ''|'' 
        encoding           ''UTF8'' 
        csv
        header
      '
    ;
  end if;
end
$$
language plpgsql;

-- call
-- sm_sc.prc_import_pretrain_model
-- (
--   -000000002
-- , '/var/lib/pgsql/sm_sc.tb_classify_task_000000002.gz'
-- , '/var/lib/pgsql/sm_sc.tb_nn_node_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_path_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_train_input_buff_000000002.gz'  
-- )