-- drop function if exists sm_sc.fv_mx_norm_eigenvalue(float[][]);
create or replace function sm_sc.fv_mx_norm_eigenvalue
(
  in i_matrix float[][]
)
  returns float
as
$$
-- declare here

begin
  return
  (
    select 
      sqrt(max((sm_sc.fv_mx_evd_value((|^~| i_matrix) |**| i_matrix))[v_cur_x]))
    from generate_series(1, array_length(i_matrix, 2)) v_cur_x
  )
  ;
end
$$
  language plpgsql volatile
  cost 100;

-- -- -- 尚未调试 等待 sm_sc.fv_mx_evd_value 完成
-- select sm_sc.fv_mx_norm_eigenvalue(array[[1,2],[0,7],[5,0],[3,4]])
-- select sm_sc.fv_mx_norm_eigenvalue(array[[1,-2,0,7],[5,0,3,4],[0,0,0,0],[0,-2,0,-6]])