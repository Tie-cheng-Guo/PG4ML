drop procedure if exists sm_sc.prc_nn_release_sess;
create or replace procedure sm_sc.prc_nn_release_sess
(
  i_work_no      bigint
, i_sess_id      bigint
)
as
$$
-- declare -- here  

begin
  -- set search_path to public;
  update sm_sc.__vt_nn_sess
  set sess_status = '0'
  where work_no = i_work_no
    and sess_id = i_sess_id
  ;
end
$$
language plpgsql;

-- do
-- $$
-- declare 
--   v_sess_id  bigint   :=   907;
-- begin
--   call sm_sc.prc_nn_release_sess
--   (
--     -76543
--   , v_sess_id
--   );
--   raise notice 'release sess_id: %', v_sess_id;
-- end
-- $$
-- language plpgsql