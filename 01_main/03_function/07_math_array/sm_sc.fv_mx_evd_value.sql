-- -- householder
-- -- https://wenku.baidu.com/view/c2e34678168884868762d6f9.html
-- -- https://wenku.baidu.com/view/63a32e72f242336c1eb95e89.html

-- -- 本算法不支持求解复数特征值。通常准对称实矩阵，特征值为实数
-- drop function sm_sc.fv_mx_evd_value(float[][]);
create or replace function sm_sc.fv_mx_evd_value
(
  in i_matrix float[][]
)
  returns float[]
as
$$
-- declare here
declare 
  v_loop_cnt_01      int                   := 1;
  v_len              int                   := array_length(i_matrix, 1);

begin
  if v_len = array_length(i_matrix, 2)
  then
    while v_loop_cnt_01 <= 1000  -- 如果1000次循环内仍然未收敛，则终止
      and exists (select from generate_series(1, v_len) v_cur_y, generate_series(1, v_cur_y - 1) v_cur_x where abs(i_matrix[v_cur_y][v_cur_x]) > 1e-128 :: float)
    loop
      i_matrix = (select mx_r |**| mx_q from sm_sc.ft_mx_qr(i_matrix));
      v_loop_cnt_01 = v_loop_cnt_01 + 1;
    end loop;

    return 
      (select array_agg(i_matrix[v_cur][v_cur] order by i_matrix[v_cur][v_cur] desc) from generate_series(1, v_len) v_cur)
    ;
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_evd_value(array[[1,2],[3,4]])
-- select sm_sc.fv_mx_evd_value(array[[1,2,3],[0,8,9],[4,5,6]])
-- -- select sm_sc.fv_mx_evd_value(array[[1,2,3,4],[0,8,9,10],[4,5,6,7],[5,7,2,10]])  -- 本算法不支持求解复数特征值
-- select sm_sc.fv_mx_evd_value(array[[0,1,2],[1,1,4],[2,-1,0]])
-- select sm_sc.fv_mx_evd_value(array[
--   [1.0000,2.0000,3.0000,4.0000,5.0000,6.0000,7.0000],  
--   [2.0000,3.0000,4.0000,5.0000,6.0000,7.0000,8.0000],  
--   [3.0000,4.0000,5.0000,6.0000,7.0000,8.0000,9.0000],  
--   [4.0000,5.0000,6.0000,7.0000,8.0000,9.0000,10.000],   
--   [5.0000,6.0000,7.0000,8.0000,9.0000,10.000,11.000],   
--   [6.0000,7.0000,8.0000,9.0000,10.000,11.000,12.000],   
--   [7.0000,8.0000,9.0000,10.000,11.000,12.000,13.000]
--   ])


-- select sm_sc.fv_mx_evd_value(array[[2,3],[1,7]])
-- truncate table t_tmp_debug_info
-- select * from t_tmp_debug_info




-- -- -- ----------------------------------------------------------------------------

-- for debug data
-- -- with 
-- -- cte_loop_1 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr(array[[5,-3,2],[6,-4,4],[4,-4,5]])
-- -- ),
-- -- cte_loop_2 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_1))
-- -- ),
-- -- cte_loop_3 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_2))
-- -- ),
-- -- cte_loop_4 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_3))
-- -- ),
-- -- cte_loop_5 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_4))
-- -- ),
-- -- cte_loop_6 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_5))
-- -- ),
-- -- cte_loop_7 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_6))
-- -- ),
-- -- cte_loop_8 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_7))
-- -- ),
-- -- cte_loop_9 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_8))
-- -- ),
-- -- cte_loop_10 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_9))
-- -- ),
-- -- cte_loop_11 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_10))
-- -- ),
-- -- cte_loop_12 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_11))
-- -- ),
-- -- cte_loop_13 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_12))
-- -- ),
-- -- cte_loop_14 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_13))
-- -- ),
-- -- cte_loop_15 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_14))
-- -- ),
-- -- cte_loop_16 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_15))
-- -- ),
-- -- cte_loop_17 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_16))
-- -- ),
-- -- cte_loop_18 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_17))
-- -- ),
-- -- cte_loop_19 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_18))
-- -- ),
-- -- cte_loop_20 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_19))
-- -- ),
-- -- cte_loop_21 as
-- -- (
-- --   select mx_q, mx_r from sm_sc.ft_mx_qr((select mx_r |**| mx_q from cte_loop_20))
-- -- )
-- -- select mx_r |**| mx_q from cte_loop_21