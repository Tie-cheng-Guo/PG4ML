  call sm_sc.prc_nn_release_sess
  (
    -000000002
  , $_sess_id    -- o_output_sess_id       --  这里设置钥匙放的 sess_id 资源
  )
  ;