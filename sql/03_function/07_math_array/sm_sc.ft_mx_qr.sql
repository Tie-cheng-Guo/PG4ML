-- -- householder
-- -- https://wenku.baidu.com/view/c2e34678168884868762d6f9.html
-- -- https://wenku.baidu.com/view/63a32e72f242336c1eb95e89.html

-- -- define return Q+R struct
-- drop type if exists cls_mx_qr_return;
-- create type cls_mx_qr_return as
-- (
--   mx_q    float[][]      ,
--   mx_r    float[][]
-- );
-- 
-- -- --------------------------------

-- drop function if exists sm_sc.ft_mx_qr(float[][]);
create or replace function sm_sc.ft_mx_qr
(
  in i_matrix float[][]
)
--   returns float[2][][]  
-- -- 出参解释：
-- -- [1][:][:]: q矩阵
-- -- [2][:][:]: r矩阵
returns TABLE
(
  o_mx_q    float[][],
  o_mx_r    float[][]
)

as
$$
-- declare here
declare 
  v_loop_cnt_01           int                   := 0;
  v_loop_cnt_02           int;
  v_loop_matrix           float[][]     := i_matrix;
 
  v_dims_len                int                   :=   array_length(i_matrix, 1) ;                 -- 方阵维数
  v_col_array             float[]; -- 当次循环下，待变换一列的下子列
  v_col_down_part_norm    float;   -- 当次循环下，待变换一列的下子列的模
  v_array_e               float[];  -- 当次循环下，自然基底向量
  v_array_w               float[];  -- 当次循环下，欧米伽法向量
  v_array_w_norm          float;    -- 当次循环下，欧米伽法向量的模
  v_mx_w                  float[][];  -- 当次循环下，欧米伽矩阵
  v_mx_w_prepend          float[][];  -- 当次循环下，欧米伽矩阵的左上扩展
  v_mx_q                  float[][]    := sm_sc.fv_eye_unit(v_dims_len);  -- q矩阵
  v_mx_r                  float[][]    := i_matrix;  -- r矩阵

begin


  if v_dims_len = array_length(i_matrix, 2)
    -- -- -- and /*待处理欠秩判断？？*/
  then
    while v_loop_cnt_01 < v_dims_len - 1
    loop
      -- 准备本次迭代入参子矩阵
      v_loop_cnt_01 = v_loop_cnt_01 + 1;
      v_loop_matrix = v_mx_r[v_loop_cnt_01 : ][v_loop_cnt_01 : ];

      -- 下子列
      v_col_array = sm_sc.fv_mx_ele_2d_2_1d(|^~| v_loop_matrix[1:][1:1]);

      -- 下子列的模
      v_col_down_part_norm = sm_sc.fv_arr_norm_2(v_col_array);  
      if v_col_down_part_norm < 1e-128 :: float
      then 
        continue;
      end if;

      -- 自然基底向量
      v_array_e = array_fill(0.0 :: float, array[v_dims_len + 1 - v_loop_cnt_01]);
      v_array_e[1] = 1.0;

      -- 欧米伽法向量
      v_array_w = v_col_array -` (v_col_down_part_norm *` v_array_e);   -- 下一步才除以模
      v_array_w_norm = sm_sc.fv_arr_norm_2(v_array_w);
      if v_array_w_norm < 1e-128 :: float
      then 
        continue;
      end if;

      v_array_w = v_array_w /` v_array_w_norm;

      -- 欧米伽矩阵
      v_mx_w = sm_sc.fv_eye_unit(v_dims_len + 1 - v_loop_cnt_01) -` (2.0 :: float *` ((|^~| array[v_array_w]) |**| array[v_array_w]));

      -- 欧米伽矩阵的左上扩展
      v_mx_w_prepend = sm_sc.fv_area_replace(sm_sc.fv_eye_unit(v_dims_len), array[v_loop_cnt_01, v_loop_cnt_01], v_mx_w);

      -- 迭代Q矩阵
      v_mx_q = v_mx_q |**| v_mx_w_prepend;

      -- 迭代R矩阵
      v_mx_r = v_mx_w_prepend |**| v_mx_r;

    end loop;

    -- return array[v_mx_q, v_mx_r]
    return query 
      select v_mx_q, v_mx_r
    ;

  else
    return query 
      select 
        null :: float[][], 
        null :: float[][];
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select o_mx_q, o_mx_r from sm_sc.ft_mx_qr(array[[1,2],[3,4]])
-- select o_mx_q, o_mx_r from sm_sc.ft_mx_qr(array[[1,2,3],[0,8,9],[4,5,6]])
-- select o_mx_q, o_mx_r from sm_sc.ft_mx_qr(array[[1,2,3,4],[0,8,9,10],[4,5,6,7],[5,7,2,10]])
-- select o_mx_q, o_mx_r from sm_sc.ft_mx_qr(array[[0,1,2],[1,1,4],[2,-1,0]])

-- select o_mx_q, o_mx_r from sm_sc.ft_mx_qr(array[[2,3],[1,7]])
-- truncate table t_tmp_debug_info
-- select * from t_tmp_debug_info