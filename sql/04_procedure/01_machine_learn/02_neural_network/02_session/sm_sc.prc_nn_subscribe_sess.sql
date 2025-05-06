drop procedure if exists sm_sc.prc_nn_subscribe_sess;
create or replace procedure sm_sc.prc_nn_subscribe_sess
(
     in i_work_no      bigint
, inout o_sess_id      bigint
)
as
$$
-- declare -- here  

begin
  -- set search_path to public;
  select  
    sess_id into o_sess_id
  from sm_sc.__vt_nn_sess 
  where work_no = i_work_no
    and sess_status = '0'
  limit 1 
  for update
  ;
  
  if o_sess_id is null
  then   
    raise exception 'sess id are all in use.  ';
  else
    update sm_sc.__vt_nn_sess
    set sess_status = '1'
    where work_no = i_work_no
      and sess_id = o_sess_id
    ;
  end if;
end
$$
language plpgsql;

-- do
-- $$
-- declare 
--   v_sess_id  bigint;
-- begin
--   call sm_sc.prc_nn_subscribe_sess
--   (
--     -76543
--   , v_sess_id
--   );
--   raise notice 'subscribe sess_id: %', v_sess_id;
-- end
-- $$
-- language plpgsql