  call sm_sc.prc_nn_release_sess
  (
    -000000016
  , $_sess_id    -- o_output_sess_id       --  这里设置将要释放的 sess_id 资源
  )
  ;