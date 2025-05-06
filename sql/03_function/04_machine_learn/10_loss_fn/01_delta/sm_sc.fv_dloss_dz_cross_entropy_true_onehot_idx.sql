-- drop function if exists sm_sc.fv_dloss_dz_cross_entropy_true_onehot_idx(float[], float[]);
create or replace function sm_sc.fv_dloss_dz_cross_entropy_true_onehot_idx
(
  i_z               float[]          ,      -- 训练输出预测值
  i_true_onehot_idx float[]                 -- 训练集真实值
)
returns float[]
as
$$
declare 
  v_len_z           int[]     :=   (select array_agg(array_length(i_z, a_no) order by a_no) from generate_series(1, array_ndims(i_z)) tb_a(a_no));
  -- v_true_onehot_idx int[]     :=   (select array_agg(array_length(i_true_onehot_idx, a_no) order by a_no) from generate_series(1, array_ndims(i_true_onehot_idx)) tb_a(a_no));
  v_ret             float[]   :=   array_fill(0.0, v_len_z);
  v_cur_y           int       ;
  v_cur_x           int       ;
  v_cur_x3          int       ;
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计维度长度约束与对齐
    if  -- --  array_ndims(i_z) > 4 
        -- -- or array_ndims(i_true_onehot_idx) > 4 
        -- -- or 
         array_length(i_true_onehot_idx, 1) <> 1
      or array_length(i_z, 1) <> array_length(i_true_onehot_idx, 1)
    then
      raise exception 'no method for such length!  Y_Dims: %; Z_Dims: %;', array_dims(i_z), array_dims(i_true_onehot_idx);
    end if;
  end if;

  -- -- return 
  -- --   -- -` i_true /` sm_sc.fv_ele_replace((i_z *` array_length(i_z, 1) :: float) :: float[], array[0.0 :: float], 1.0e-128 :: float)   -- esp: 1.0e-308 :: float -- 1.0 / 1.0e308 :: float  此处308刚好不溢出，但进一步运算可能溢出
  -- -- ;
  
  -- 重整维数
  if array_ndims(i_z) <> array_ndims(i_true_onehot_idx)
  then
    i_true_onehot_idx := i_true_onehot_idx |><| (v_len_z[ : array_length(v_len_z, 1) - 1] || array[1]);
  end if;
  
  if array_ndims(i_z) = 1
  then 
    v_ret[i_true_onehot_idx[1]] :=  
      -1.0 / coalesce(nullif(i_z[i_true_onehot_idx[1]], 0.0), 1.0e-128 :: float)
    ;
  elsif array_ndims(i_z) = 2
  then 
    for v_cur_y in 1 .. array_length(i_true_onehot_idx, 1)
    loop
      v_ret[v_cur_y][i_true_onehot_idx[v_cur_y][1]] :=  
        -1.0 / coalesce(nullif(i_z[v_cur_y][i_true_onehot_idx[v_cur_y][1]], 0.0), 1.0e-128 :: float)
      ;
    end loop;
  elsif array_ndims(i_z) = 3
  then 
    for v_cur_y in 1 .. array_length(i_true_onehot_idx, 1)
    loop
      for v_cur_x in 1 .. array_length(i_true_onehot_idx, 2)
      loop
          v_ret[v_cur_y][v_cur_x][i_true_onehot_idx[v_cur_y][v_cur_x][1]] :=  
            -1.0 / coalesce(nullif(i_z[v_cur_y][v_cur_x][i_true_onehot_idx[v_cur_y][v_cur_x][1]], 0.0), 1.0e-128 :: float)
          ;
      end loop;
    end loop;
  elsif array_ndims(i_z) = 4
  then 
    for v_cur_y in 1 .. array_length(i_true_onehot_idx, 1)
    loop
      for v_cur_x in 1 .. array_length(i_true_onehot_idx, 2)
      loop
        for v_cur_x3 in 1 .. array_length(i_true_onehot_idx, 3)
        loop
            v_ret[v_cur_y][v_cur_x][v_cur_x3][i_true_onehot_idx[v_cur_y][v_cur_x][v_cur_x3][1]] :=  
              -1.0 / coalesce(nullif(i_z[v_cur_y][v_cur_x][v_cur_x3][i_true_onehot_idx[v_cur_y][v_cur_x][v_cur_x3][1]], 0.0), 1.0e-128 :: float)
            ;
        end loop;
      end loop;
    end loop;
  end if;
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_dloss_dz_cross_entropy_true_onehot_idx(array[[0.1, 0.2, 0.7], [0.2, 0.3, 0.5]], array[[3], [2]])