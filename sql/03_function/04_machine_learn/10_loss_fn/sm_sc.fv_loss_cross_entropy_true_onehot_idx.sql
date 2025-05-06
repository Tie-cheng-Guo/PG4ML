-- 参考 https://zhuanlan.zhihu.com/p/35709485

-- drop function if exists sm_sc.fv_loss_cross_entropy_true_onehot_idx(float[], float[]);
create or replace function sm_sc.fv_loss_cross_entropy_true_onehot_idx
(
  i_nn_depdt_01                 float[]                 -- 训练输出预测值
, i_true_01_onehot_idx          float[]                 -- 训练集真实值
-- --, i_nn_depdt_02                 float[]                 -- 训练输出预测值
-- , i_true_02                     float[]                 -- 训练集真实值
)
returns float
as
$$
declare
  v_len_z           int[]     :=   (select array_agg(array_length(i_nn_depdt_01, a_no) order by a_no) from generate_series(1, array_ndims(i_nn_depdt_01)) tb_a(a_no));
  v_true_onehot_idx int[]     :=   (select array_agg(array_length(i_true_01_onehot_idx, a_no) order by a_no) from generate_series(1, array_ndims(i_true_01_onehot_idx)) tb_a(a_no));
  v_ret             float[]   :=   array_fill(0.0, v_len_z);
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计维度长度约束与对齐
    if  -- --  array_ndims(i_nn_depdt_01) > 4 
        -- -- or array_ndims(i_true_01_onehot_idx) > 4 
        -- -- or 
      array_length(i_true_01_onehot_idx, array_ndims(i_true_01_onehot_idx)) <> 1
      or v_len_z[ : 1] <> v_true_onehot_idx[ : 1]
    then
      raise exception 'no method for such length!  Y_Dims: %; Z_Dims: %;', array_dims(i_nn_depdt_01), array_dims(i_true_01_onehot_idx);
    end if;
  end if;
 
  -- -- return 
  -- --   -- esp: 1e-323 :: float 此处323刚好不溢出，但进一步运算可能溢出
  -- --   - sm_sc.fv_aggr_slice_sum_py(i_true *` (^!` sm_sc.fv_ele_replace(i_nn_depdt_01, array[0.0 :: float], 1.0e-8 :: float))) / array_length(i_nn_depdt_01, 1) :: float
  -- -- ;
  
  -- 重整维数
  if array_ndims(i_nn_depdt_01) <> array_ndims(i_true_01_onehot_idx)
  then
    i_true_01_onehot_idx := i_true_01_onehot_idx |><| (v_len_z[ : array_length(v_len_z, 1) - 1] || array[1]);
  end if;

  -- log(0.0)处理参考: https://blog.csdn.net/wekings/article/details/123578464
  if array_ndims(i_nn_depdt_01) = 1
  then 
    return 
      - ln
        (
          -- coalesce(nullif(i_nn_depdt_01[i_true_01_onehot_idx[1]], 0.0), 1.0e-8 :: float)
          least(greatest(i_nn_depdt_01[i_true_01_onehot_idx[1]], 0.0001 / (array_length(i_nn_depdt_01, 1) - 1)), 0.9999)
        ) -- / array_length(i_nn_depdt_01, 1) :: float
    ;
  elsif array_ndims(i_nn_depdt_01) = 2
  then 
    return 
      - 
      (
        select 
          sum
          (
            ln
            (
              -- coalesce(nullif(i_nn_depdt_01[a_y_no][i_true_01_onehot_idx[a_y_no][1]], 0.0), 1.0e-8 :: float)
              least(greatest(i_nn_depdt_01[a_y_no][i_true_01_onehot_idx[a_y_no][1]], 0.0001 / (array_length(i_nn_depdt_01, 2) - 1)), 0.9999)
            )
          )
        from generate_series(1, array_length(i_true_01_onehot_idx, 1)) tb_a_y_no(a_y_no)
      ) 
      / array_length(i_true_01_onehot_idx, 1) :: float
    ;
  elsif array_ndims(i_nn_depdt_01) = 3
  then 
    return 
      - 
      (
        select 
          sum
          (
            ln
            (
              -- coalesce(nullif(i_nn_depdt_01[a_y_no][a_x_no][i_true_01_onehot_idx[a_y_no][a_x_no][1]], 0.0), 1.0e-8 :: float)
              least(greatest(i_nn_depdt_01[a_y_no][a_x_no][i_true_01_onehot_idx[a_y_no][a_x_no][1]], 0.0001 / (array_length(i_nn_depdt_01, 3) - 1)), 0.9999)
            )
          )
        from generate_series(1, array_length(i_true_01_onehot_idx, 1)) tb_a_y_no(a_y_no)
          , generate_series(1, array_length(i_true_01_onehot_idx, 2)) tb_a_x_no(a_x_no)
      ) 
      / array_length(i_true_01_onehot_idx, 1) :: float
    ;
  elsif array_ndims(i_nn_depdt_01) = 4
  then 
    return 
      - 
      (
        select 
          sum
          (
            ln
            (
              -- coalesce(nullif(i_nn_depdt_01[a_y_no][a_x_no][a_x3_no][i_true_01_onehot_idx[a_y_no][a_x_no][a_x3_no][1]], 0.0), 1.0e-8 :: float)
              least(greatest(i_nn_depdt_01[a_y_no][a_x_no][a_x3_no][i_true_01_onehot_idx[a_y_no][a_x_no][a_x3_no][1]], 0.0001 / (array_length(i_nn_depdt_01, 4) - 1)), 0.9999)
            )
          )
        from generate_series(1, array_length(i_true_01_onehot_idx, 1)) tb_a_y_no(a_y_no)
          , generate_series(1, array_length(i_true_01_onehot_idx, 2)) tb_a_x_no(a_x_no)
          , generate_series(1, array_length(i_true_01_onehot_idx, 3)) tb_a_x3_no(a_x3_no)
      ) 
      / array_length(i_true_01_onehot_idx, 1) :: float
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_loss_cross_entropy_true_onehot_idx(array[[0.1, 0.2, 0.7], [0.2, 0.3, 0.5]], array[[3.0], [3.0]])
-- select sm_sc.fv_loss_cross_entropy_true_onehot_idx(array[[[0.1, 0.2, 0.7], [0.1, 0.2, 0.7]], [[0.1, 0.2, 0.7], [0.1, 0.2, 0.7]]], array[[[3.0], [2.0]], [[1.0], [3.0]]])