-- step 3. 从 tb_tmp_mnist_000000002 加工至本框架公共的 buff 表 sm_sc.tb_nn_train_input_buff，生成 onehot 编码，作为 i_y
do 
$$
declare 
  v_work_no       float   :=  -000000019;
  -- v_avg           float   ;
  -- v_std_dev       float   ;
  v_depdt_hw      float   :=  42.0 * 42.0;
  v_indepdt_hw    float   :=  42.0 * 42.0;
begin 
  delete from sm_sc.tb_nn_train_input_buff
  where work_no = v_work_no;
  commit;

  -- select 
  --   avg(a_avg)   
  -- , avg(a_stddev)
  -- into 
  --   v_avg
  -- , v_std_dev
  -- from 
  -- (
  --   select -- * 
  --     |@/| (num_arr :: float[]) as a_avg
  --   , |@%`| (num_arr :: float[]) as a_stddev
  --   from sm_dat.tb_tmp_mnist_000000002 
  --   limit 500
  -- ) tb_a
  -- ;

  insert into sm_sc.tb_nn_train_input_buff
  (
    work_no
  , ord_no
  , i_depdt_01
  , i_indepdt_01
  , i_dataset_dtl
  )
  with 
  cte_test_dataset as 
  (
    select 
      num 
    , num_arr
    , row_number() over(partition by num) as a_no_in_grp
    from sm_dat.tb_tmp_mnist_000000002
  ),
  cte_padding as 
  (
    select 
      num
    , a_no_in_grp
    , case (a_no_in_grp - 1) / 50
        when 0
          then ((num_arr :: float[] |><| array[28, 28]) |-|| sm_sc.fv_new(0.0 :: float, array[14, 28])) |||| sm_sc.fv_new(0.0 :: float, array[42, 14])
        when 1
          then (sm_sc.fv_new(0.0 :: float, array[14, 28]) |-|| (num_arr :: float[] |><| array[28, 28])) |||| sm_sc.fv_new(0.0 :: float, array[42, 14])
        when 2
          then sm_sc.fv_new(0.0 :: float, array[42, 14]) |||| ((num_arr :: float[] |><| array[28, 28]) |-|| sm_sc.fv_new(0.0 :: float, array[14, 28]))
        when 3
          then sm_sc.fv_new(0.0 :: float, array[42, 14]) |||| (sm_sc.fv_new(0.0 :: float, array[14, 28]) |-|| (num_arr :: float[] |><| array[28, 28]))
      end 
        as num_arr_padding
    from cte_test_dataset
    where a_no_in_grp <= 200
  )
  select 
    v_work_no as work_no
  , row_number() over(order by num) as ord_no
  , (
      (
        num_arr_padding :: float[]
        |><|
        array[42,42]
      )
    )
  , (
      (
        (
          (
            (( -` (<>` num_arr_padding :: float[])) :: float[] +` 1.0) 
            *` 
            -- (sm_sc.fv_activate_sigmoid(sm_sc.fv_new_randn(0.0, 1.0, array[42, 42])) *` 4.0)
            (
              (
                (sm_sc.fv_new_randn(32.0, 1.0, array[21, 21]) *` 2.0)
              ||||
                (sm_sc.fv_new_randn(94.0, 1.0, array[21, 21]) *` 3.0)
              )
              |-||
              (
                (sm_sc.fv_new_randn(160.0, 1.0, array[21, 21]) *` 4.0)
              ||||
                (sm_sc.fv_new_randn(224.0, 1.0, array[21, 21]) *` 1.0)
              )
            )
          )
          +`
          num_arr_padding
        )
        |><|
        array[42,42]     
      ) 
    )
  , num
  from cte_padding
  ;
  
  -- select
  --   array_length(i_depdt_01, 2) * array_length(i_depdt_01, 3)
  -- , array_length(i_indepdt_01, 2) * array_length(i_indepdt_01, 3)
  -- into 
  --   v_depdt_hw  
  --   v_indepdt_hw
  -- from sm_sc.tb_nn_train_input_buff
  -- where work_no = v_work_no
  -- limit 1
  -- ;
  
  with 
  cte_fft as 
  (
    select 
      ord_no
    -- , sm_sc.fv_sgn_fft2(i_depdt_01 :: sm_sc.typ_l_complex[] +` (i_depdt_01 :: sm_sc.typ_l_complex[] *` ((0,1) :: sm_sc.typ_l_complex))) as i_depdt_01_fft
    -- , sm_sc.fv_sgn_fft2(i_indepdt_01 :: sm_sc.typ_l_complex[] +` (i_indepdt_01 :: sm_sc.typ_l_complex[] *` ((0,1) :: sm_sc.typ_l_complex))) as i_indepdt_01_fft
    , sm_sc.fv_sgn_fft2(i_depdt_01) as i_depdt_01_fft
    , sm_sc.fv_sgn_fft2(i_indepdt_01) as i_indepdt_01_fft
    from sm_sc.tb_nn_train_input_buff
    where work_no = v_work_no
  )
  update sm_sc.tb_nn_train_input_buff tb_a_tar
  set 
    i_depdt_01 = -- array[i_depdt_01]
      sm_sc.fv_concat_y
      (
        -- 图像在制作成数据集的时候在直流频段上按照功率谱理论做了抑制，避免损失函数过大；推理时，还原为空间域要放大回来。
        array[sm_sc.fv_opr_real(i_depdt_01_fft)] /` v_depdt_hw
      , array[sm_sc.fv_opr_imaginary(i_depdt_01_fft)] /` v_depdt_hw
      ) 
  , i_indepdt_01 = 
      sm_sc.fv_concat_y
      (
        -- 图像在制作成数据集的时候在直流频段上按照功率谱理论做了抑制，避免损失函数过大；推理时，还原为空间域要放大回来。
        array[sm_sc.fv_opr_real(i_indepdt_01_fft)] /` v_indepdt_hw
      , array[sm_sc.fv_opr_imaginary(i_indepdt_01_fft)] /` v_indepdt_hw
      ) 
  from cte_fft tb_a_sour
  where tb_a_tar.work_no = v_work_no
    and tb_a_sour.ord_no = tb_a_tar.ord_no
  ;

end
$$
language plpgsql;