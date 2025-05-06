drop procedure if exists sm_sc.prc_export_infer_model(bigint, text, text);
create or replace procedure sm_sc.prc_export_infer_model
(
  i_work_no           bigint
-- , i_model_folder_path text        -- etc. /var/lib/pgsql/
, i_model_node_file   text                  
, i_model_path_file   text                  
) as 
$$
declare
begin  
  if exists (select  from sm_sc.__vt_nn_node where work_no = i_work_no)
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
            , node_depdt_vals  
            from sm_sc.__vt_nn_node
            where work_no = ' || i_work_no || '
          )
        to program         ''gzip > ' || i_model_node_file || '''
        delimiter          ''|'' 
        encoding           ''UTF8'' 
        csv
        header
      '
    ;
  else 
    raise exception 'not exists i_work_no from sm_sc.__vt_nn_node.';
  end if;
  
  if exists (select  from sm_sc.__vt_nn_path where work_no = i_work_no)
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
            from sm_sc.__vt_nn_path 
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
    raise exception 'not exists i_work_no from sm_sc.__vt_nn_path.';
  end if;  
end
$$
language plpgsql;

-- call 
-- sm_sc.prc_export_infer_model
-- (
--   -2
-- , '/var/lib/pgsql/sm_sc.tb_nn_node_000000002.gz'  
-- , '/var/lib/pgsql/sm_sc.tb_nn_path_000000002.gz'  
-- )