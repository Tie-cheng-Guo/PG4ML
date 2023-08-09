-- -- https://blog.csdn.net/Supper_Shenchao/article/details/121785115

-- drop function sm_sc.ft_mx_lu(float[][]);
create or replace function sm_sc.ft_mx_lu
(
  in i_mx float[][]
)
--   returns float[2][][]  
-- -- 出参解释：
-- -- [1][:][:]: L矩阵
-- -- [2][:][:]: U矩阵
returns TABLE
(
  o_mx_l    float[][],
  o_mx_u    float[][]
)

as
$$
-- declare here
declare 
  v_matrix_len  int                   :=  array_length(i_mx, 1);
  v_mx_l        float[][]    :=  sm_sc.fv_eye_unit(1.0 :: float, v_matrix_len);       -- 下三角矩阵
  v_mx_u        float[][]    :=  array_fill(0.0 :: float, array[v_matrix_len, v_matrix_len]);    -- 上三角矩阵
  
  v_cur_1       int;
  v_cur_2       int;

begin

  if v_matrix_len <> array_length(i_mx, 2)
  then 
    raise exception 'array_length(i_mx, 2) should be equal to array_length(i_mx, 1)';
  -- -- -- elsif
  -- -- --   -- -- -- 判断 顺序主子式 是否为零
  -- -- -- then 
  -- -- --   
  else
    -- 初始化 上三角矩阵第一行，（期待，可以优雅的对数组变量的切片整体赋值）
    for v_cur_1 in 1 .. v_matrix_len
    loop 
      v_mx_u[1][v_cur_1] = i_mx[1][v_cur_1];
    end loop;

    for v_cur_1 in 2 .. v_matrix_len
    loop 
    
      -- 更新 v_mx_l 这一列
      for v_cur_2 in v_cur_1 .. v_matrix_len
      -- 根据矩阵乘法，i_mx[v_cur_2][v_cur_1] = |@+| (v_mx_l[v_cur_2 : v_cur_2][ : ] *` v_mx_u[ : ][v_cur_1 : v_cur_1])
      -- 又，v_mx_u 上三角矩阵，所以 v_mx_u[v_cur_1 + 1 : ][v_cur_1 : v_cur_1] 的元素都是 0.0；
      -- 推出：i_mx[v_cur_2][v_cur_1] = |@+| (v_mx_l[v_cur_2 : v_cur_2][ : v_cur_1] *` v_mx_u[ : v_cur_1][v_cur_1 : v_cur_1])
      --   即：i_mx[v_cur_2][v_cur_1 - 1] = |@+| (v_mx_l[v_cur_2 : v_cur_2][ : v_cur_1 - 2] *` v_mx_u[ : v_cur_1 - 2][v_cur_1 - 1 : v_cur_1 - 1]) 
      --                                       + (v_mx_l[v_cur_2][v_cur_1 - 1] * v_mx_u[v_cur_1 - 1][v_cur_1 - 1])
      loop 
        v_mx_l[v_cur_2][v_cur_1 - 1] := (i_mx[v_cur_2][v_cur_1 - 1] - coalesce((|@+| (sm_sc.fv_mx_ele_2d_2_1d(v_mx_l[v_cur_2 : v_cur_2][ : v_cur_1 - 2]) *` sm_sc.fv_mx_ele_2d_2_1d(v_mx_u[ : v_cur_1 - 2][v_cur_1 - 1 : v_cur_1 - 1]))), 0.0 :: float)) / nullif(v_mx_u[v_cur_1 - 1][v_cur_1 - 1], 0.0 :: float);
      end loop;


      -- 更新 v_mx_u 这一行
      for v_cur_2 in v_cur_1 .. v_matrix_len
      -- 根据矩阵乘法，i_mx[v_cur_1][v_cur_2] = |@+| (v_mx_l[v_cur_1 : v_cur_1][ : ] *` v_mx_u[ : ][v_cur_2 : v_cur_2])
      -- 又，v_mx_l 下三角矩阵，所以 v_mx_l[v_cur_1 : v_cur_1][v_cur_1 + 1 : ] 的元素都是 0.0；v_mx_l[v_cur_1][v_cur_1] == 1
      -- 推出：i_mx[v_cur_1][v_cur_2] = |@+| (v_mx_l[v_cur_1 : v_cur_1][ : v_cur_1] *` v_mx_u[ : v_cur_1][v_cur_2 : v_cur_2])
      --   即：i_mx[v_cur_1][v_cur_2] = |@+| (v_mx_l[v_cur_1 : v_cur_1][ : v_cur_1 - 1] *` v_mx_u[ : v_cur_1 - 1][v_cur_2 : v_cur_2]) 
      --                                   + (v_mx_l[v_cur_1][v_cur_1] * v_mx_u[v_cur_1][v_cur_2])
      -- 也即：i_mx[v_cur_1][v_cur_2] = |@+| (v_mx_l[v_cur_1 : v_cur_1][ : v_cur_1 - 1] *` v_mx_u[ : v_cur_1 - 1][v_cur_2 : v_cur_2]) 
      --                                   + v_mx_u[v_cur_1][v_cur_2])
      loop 
        v_mx_u[v_cur_1][v_cur_2] := i_mx[v_cur_1][v_cur_2] - coalesce(|@+| (sm_sc.fv_mx_ele_2d_2_1d(v_mx_l[v_cur_1 : v_cur_1][ : v_cur_1 - 1]) *` sm_sc.fv_mx_ele_2d_2_1d(v_mx_u[ : v_cur_1 - 1][v_cur_2 : v_cur_2])), 0.0 :: float);
      end loop;

    end loop
    ;
  end if;
  
  return query
    select v_mx_l, v_mx_u
  ;
end
$$
  language plpgsql volatile
  cost 100;

-- select o_mx_l, o_mx_u from sm_sc.ft_mx_lu(array[[1,2],[3,4]])
-- select o_mx_l, o_mx_u from sm_sc.ft_mx_lu(array[[1,2,3],[0,8,9],[4,5,6]])
-- select o_mx_l, o_mx_u from sm_sc.ft_mx_lu(array[[2,1,-1,3],[4,3,-2,11],[-4,1,5,8],[6,2,12,3]])
-- select o_mx_l |**| o_mx_u from sm_sc.ft_mx_lu(array[[2,1,-1,3],[4,3,-2,11],[-4,1,5,8],[6,2,12,3]])
-- select o_mx_l, o_mx_u from sm_sc.ft_mx_lu(array[[0,1,2],[1,1,4],[2,-1,0]])

-- select o_mx_l, o_mx_u from sm_sc.ft_mx_lu(array[[2,3],[1,7]])