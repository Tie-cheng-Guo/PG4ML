drop procedure if exists sm_sc.prc_import_pretrain_model_p(bigint, text, text, text, text, text);
create or replace procedure sm_sc.prc_import_pretrain_model_p
(
  i_work_no             bigint
, i_model_work_file     text                  
, i_model_node_file     text                  
, i_model_path_file     text   
, i_model_array_kv_file text               
, i_train_data_file     text default null     
) as 
$$
declare
begin
  delete from sm_sc.tb_classify_task where work_no = i_work_no;
  commit;
  execute 
    '
      copy               
        sm_sc.tb_classify_task 
        (
          work_no     
        , model_code_6
        , learn_cnt   
        , loss_fn_type
        , loss_delta 
        , ret_w
        )
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
      copy               
        sm_sc.tb_nn_node 
        (
          work_no             
        , node_no             
        , node_type           
        , node_fn_type        
        , node_fn_asso_value  
        , nn_depth_no         
        , learn_cnt_fore      
        , learn_cnt_back      
        , is_fore_node        
        , is_back_node      
        , dropout_ratio       
        , dropout_rescale     
        , dropout_depdt_val   
        , is_dropout          
        , node_depdt_len      
        , pick_depdt_idx    
        , p_node_depdt        
        , p_node_dloss_ddepdt 
        , cost_delta_l1       
        , cost_delta_l2       
        , node_grp_no         
        , node_grp_ord_no     
        , node_desc     
        )
      from program       ''gzip -d < ' || i_model_node_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  perform 
    sm_sc.__fv_delete_kv(array_agg(p_node_depdt)) 
  from sm_sc.tb_nn_node 
  where work_no = i_work_no 
    and p_node_depdt is not null
  ;
  
  delete from sm_sc.__vt_tmp_array_kv tb_a_kv
  using sm_sc.tb_nn_node tb_a_node
  where tb_a_node.p_node_depdt = tb_a_kv.arr_key
    and tb_a_node.work_no = i_work_no
    -- and tb_a_node.p_node_depdt is not null
  ;
  commit;
  
  execute 
    '
      copy               
        sm_sc.__vt_tmp_array_kv 
        (
          arr_key
        , arr_val
        )
      from program       ''gzip -d < ' || i_model_array_kv_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  perform
    sm_sc.__fv_set_kv(tb_a_kv.arr_val, tb_a_node.p_node_depdt) 
  from sm_sc.tb_nn_node tb_a_node
  inner join sm_sc.__vt_tmp_array_kv tb_a_kv
    on tb_a_node.p_node_depdt = tb_a_kv.arr_key
  where tb_a_node.work_no = i_work_no
    -- and tb_a_node.p_node_depdt is not null
  ;  
  commit;
  
  delete from sm_sc.__vt_tmp_array_kv tb_a_kv
  using sm_sc.tb_nn_node tb_a_node
  where tb_a_node.p_node_depdt = tb_a_kv.arr_key
    and tb_a_node.work_no = i_work_no
    -- and tb_a_node.p_node_depdt is not null
  ;
  commit;
  
  delete from sm_sc.tb_nn_path where work_no = i_work_no;
  commit;
  execute 
    '
      copy               
        sm_sc.tb_nn_path 
        (
          work_no     
        , fore_node_no
        , path_ord_no 
        , back_node_no 
        , p_ddepdt_dindepdt
        )
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
-- sm_sc.prc_import_pretrain_model_p
-- (
--   -000000002
-- , '/var/lib/pgsql/sm_sc.tb_classify_task_000000002.gz'
-- , '/var/lib/pgsql/sm_sc.tb_nn_node_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_path_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_train_input_buff_000000002.gz'  
-- )