drop procedure if exists sm_sc.prc_import_infer_model_p(bigint, text, text);
create or replace procedure sm_sc.prc_import_infer_model_p
(
  i_work_no           bigint
, i_model_node_file   text
, i_model_path_file   text
) as 
$$
declare
begin
  delete from sm_sc.__vt_nn_node where work_no = i_work_no;
  commit;
  execute 
    '
      copy               
        sm_sc.__vt_nn_node 
        (
          work_no           
        , node_no           
        , node_type         
        , node_fn_type      
        , node_fn_asso_value
        , nn_depth_no       
        , node_depdt_vals   
        , p_node_depdt      
        )
      from program       ''gzip -d < ' || i_model_node_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  delete from sm_sc.__vt_nn_path where work_no = i_work_no;
  commit;
  execute 
    '
      copy               
        sm_sc.__vt_nn_path 
        (
          work_no     
        , fore_node_no
        , path_ord_no 
        , back_node_no
        )
      from program       ''gzip -d < ' || i_model_path_file || ''' 
      delimiter          ''|'' 
      encoding           ''UTF8'' 
      csv
      header
    '
  ;
  
  perform 
    sm_sc.__fv_delete_kv(array_agg(p_node_depdt)) 
  from sm_sc.__vt_nn_node 
  where work_no = i_work_no 
    and p_node_depdt is not null
  ;
  
  perform 
    sm_sc.__fv_set_kv(node_depdt_vals, p_node_depdt) 
  from sm_sc.__vt_nn_node 
  where work_no = i_work_no 
    and p_node_depdt is not null
  ;
  
  insert into sm_sc.__vt_nn_sess
  (
    work_no
  , sess_id
  , sess_status
  )
  select 
    i_work_no
  , 0
  , '1'              -- 参看字典表  nn_sess_status。0: 空闲; 1 占用;
  on conflict (work_no, sess_id) do nothing
  ;
  
  delete from sm_sc.__vt_tmp_nn_node where work_no = i_work_no and sess_id = 0;
  -- 缺省添加 sess_id = 0 ，用户演示验证
  insert into sm_sc.__vt_tmp_nn_node
  (
    sess_id                        ,
    work_no                        ,
    node_no                        ,
    node_type                      ,
    node_fn_type                   ,
    node_fn_asso_value        ,
    nn_depth_no                    ,
    p_node_depdt             
  )
  select 
    0                               ,
    work_no                         ,
    node_no                         ,
    node_type                       ,
    coalesce(nullif(node_fn_type, '00_buff_slice_rand_pick'), '00_const')  ,
    case node_fn_type when '00_buff_slice_rand_pick' then null else node_fn_asso_value end         ,
    nn_depth_no                     ,
    case 
      -- -- -- when 'prod_input' 
      -- -- --   then i_in
      -- when node_type = 'input_01' 
      --   then i_indepdt_01
      -- when node_type = 'input_02' 
      --   then i_indepdt_02
      -- when node_type = 'input_03' 
      --   then i_indepdt_03
      -- when node_type = 'input_04' 
      --   then i_indepdt_04
      -- -- when 'offset'
      -- --   then array[array[1]]
      when node_type = 'weight' or node_fn_type = '00_const'
        then p_node_depdt
      else null
    end             
  from sm_sc.__vt_nn_node
  where work_no = i_work_no
  ;
end
$$
language plpgsql;

-- call
-- sm_sc.prc_import_infer_model_p
-- (
--   -000000002
-- , '/var/lib/pgsql/sm_sc.__vt_nn_node_000000002.gz'
-- , '/var/lib/pgsql/sm_sc.__vt_nn_path_000000002.gz'

-- )