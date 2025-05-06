-- step 3. 从 tb_tmp_mnist_000000016 加工至本框架公共的 buff 表 sm_sc.tb_nn_train_input_buff，生成 onehot 编码，作为 i_y
delete from sm_sc.tb_nn_train_input_buff
where work_no = -000000016;
commit;
insert into sm_sc.tb_nn_train_input_buff
(
  work_no,
  ord_no,
  i_depdt_01,
  i_indepdt_01
)
with 
cte_org_fft as 
(
  select 
    num
  , array
    [[
      case num
        when 0
          then array[1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        when 1
          then array[0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        when 2
          then array[0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        when 3
          then array[0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        when 4
          then array[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        when 5
          then array[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
        when 6
          then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]
        when 7
          then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0]
        when 8
          then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]
        when 9
          then array[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]
      end 
    ]]
      as i_depdt_01
  , sm_sc.fv_mx_ele_1d_2_2d(num_arr, 28) :: float[] as a_indepdt_01_org_2d
  , sm_sc.fv_sgn_fft2(sm_sc.fv_mx_ele_1d_2_2d(num_arr, 28) :: float[] :: sm_sc.typ_l_complex[]) as a_indepdt_01_fft
  from sm_dat.tb_tmp_mnist_000000016
)
select 
  -000000016 as work_no
, row_number() over(order by num) as ord_no
, i_depdt_01
, sm_sc.fv_concat_y
  (
    array[a_indepdt_01_org_2d]
  , sm_sc.fv_concat_y
    (
      array[sm_sc.fv_opr_real(a_indepdt_01_fft)]
    , array[sm_sc.fv_opr_imaginary(a_indepdt_01_fft)]
    )         
  )         
    as i_indepdt_01
from cte_org_fft
;