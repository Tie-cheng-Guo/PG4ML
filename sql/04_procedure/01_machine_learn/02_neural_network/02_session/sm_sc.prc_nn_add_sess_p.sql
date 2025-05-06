drop procedure if exists sm_sc.prc_nn_add_sess_p;
create or replace procedure sm_sc.prc_nn_add_sess_p
(
  i_work_no                          bigint            ,                                                                                                -- 训练任务编号
  i_sess_cnt                         int               default    1                                                                                                      -- 最大训练次数，然后未完成中止
)
as
$$
declare -- here
  v_sess_range        int8range       := sm_sc.fv_get_global_seq(i_sess_cnt)    ;
  

begin
  set search_path to public;
  
  -- -- -- 规约: 0 号 session 为每轮训练后，默认部署。
  -- -- if 0 :: bigint <@ i_sess_multirange
  -- -- then 
  -- --   raise exception 'can''t deploy 0 as sess id.  0 is default sess id for train task at pg4ml.  ';
  -- -- end if;
  
  insert into sm_sc.__vt_nn_sess
  (
    work_no
  , sess_id
  , sess_status
  )
  select 
    i_work_no
  , a_sess_no
  , '0'              -- 参看字典表  nn_sess_status。0: 空闲; 1 占用;
  from generate_series(lower(v_sess_range), upper(v_sess_range) - 1) tb_a(a_sess_no)
  ;
  
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
    a_sess_no                    ,
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
    , generate_series(lower(v_sess_range), upper(v_sess_range) - 1) tb_a(a_sess_no)
  where work_no = i_work_no
  ;
    
end
$$
language plpgsql;

-- call sm_sc.prc_nn_add_sess_p
-- (
--   -76543
-- , 3
-- )