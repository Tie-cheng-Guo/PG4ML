drop procedure if exists sm_sc.prc_export_pretrain_model_p(bigint, text, text, text, text, text);
create or replace procedure sm_sc.prc_export_pretrain_model_p
(
  i_work_no             bigint
-- , i_model_folder_path   text
-- , i_if_train_dateset    boolean
, i_model_work_file     text                  
, i_model_node_file     text                  
, i_model_path_file     text    
, i_model_array_kv_file text                  
, i_train_data_file     text default null     
) as 
$$
declare
begin
  if exists (select  from sm_sc.tb_classify_task where work_no = i_work_no)
  then 
    execute 
      '
        copy               
          (
            select 
              work_no
            , model_code_6
            , learn_cnt
            , loss_fn_type
            , loss_delta
            , null as ret_w
            from sm_sc.tb_classify_task 
            where work_no = ' || i_work_no || '
          )
        to program         ''gzip > ' || i_model_work_file || ''' 
        delimiter          ''|'' 
        encoding           ''UTF8'' 
        csv
        header
      '
    ;
  else 
    raise exception 'not exists i_work_no from sm_sc.tb_classify_task.';
  end if;
  
  if exists (select  from sm_sc.tb_nn_node where work_no = i_work_no)
  then 
    execute 
      '
        copy               
          (
            select 
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
            , null as pick_depdt_idx  
            , case when node_type = ''weight'' or node_fn_type = ''00_const'' then p_node_depdt end as p_node_depdt 
            , null as p_node_dloss_ddepdt 
            , null as cost_delta_l1     
            , null as cost_delta_l2     
            , node_grp_no       
            , node_grp_ord_no   
            , node_desc         
            from sm_sc.tb_nn_node
            where work_no = ' || i_work_no || '
          )
        to program         ''gzip > ' || i_model_node_file || '''
        delimiter          ''|'' 
        encoding           ''UTF8'' 
        csv
        header
      '
    ;
    
    execute 
      '
        copy
          (
            select 
              p_node_depdt
            , sm_sc.__fv_get_kv(p_node_depdt) as node_depdt_vals
            from sm_sc.tb_nn_node
            where work_no = ' || i_work_no || '
              and p_node_depdt is not null
              and node_type = ''weight'' or node_fn_type = ''00_const''
          )
        to program         ''gzip > ' || i_model_array_kv_file || '''
        delimiter          ''|'' 
        encoding           ''UTF8'' 
        csv
        header
      '
    ;
  else 
    raise exception 'not exists i_work_no from sm_sc.tb_nn_node.';
  end if;
  
  if exists (select  from sm_sc.tb_nn_path where work_no = i_work_no)
  then 
    execute 
      '
        copy               
          (
            select 
              work_no
            , fore_node_no
            , path_ord_no
            , back_node_no
            , null as p_ddepdt_dindepdt
            from sm_sc.tb_nn_path 
            where work_no = ' || i_work_no || '
          )
        to program         ''gzip > ' || i_model_path_file || '''
        delimiter          ''|'' 
        encoding           ''UTF8'' 
        csv
        header
      '
    ;
  else 
    raise exception 'not exists i_work_no from sm_sc.tb_nn_path.';
  end if;
  if i_train_data_file is not null
  then 
    if exists (select  from sm_sc.tb_nn_train_input_buff where work_no = i_work_no)
    then 
      execute 
        '
          copy               
            (
              select 
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
              from sm_sc.tb_nn_train_input_buff 
              where work_no = ' || i_work_no || '
            )
          to program         ''gzip > ' || i_train_data_file || '''
          delimiter          ''|'' 
          encoding           ''UTF8'' 
          csv
          header
        '
      ;
    else 
      raise exception 'not exists i_work_no from sm_sc.tb_nn_train_input_buff.';
    end if;
  end if;
  
end
$$
language plpgsql;

-- call 
-- sm_sc.prc_export_pretrain_model_p
-- (
--   -2
-- , '/var/lib/pgsql/sm_sc.tb_classify_task_000000002.gz'
-- , '/var/lib/pgsql/sm_sc.tb_nn_node_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_path_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_train_input_buff_000000002.gz'  
-- )