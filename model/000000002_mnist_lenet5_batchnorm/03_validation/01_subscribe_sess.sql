do 
$$
declare 
  o_output_sess_id     bigint;
begin 
  call sm_sc.prc_nn_subscribe_sess
  (
    -000000002
  , o_output_sess_id
  )
  ;

  raise notice 'subscribe sess_id: %', o_output_sess_id;  
end
$$
language plpgsql