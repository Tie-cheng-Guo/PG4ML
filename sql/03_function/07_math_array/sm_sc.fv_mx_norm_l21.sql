-- drop function if exists sm_sc.fv_mx_norm_l21(float[][]);
create or replace function sm_sc.fv_mx_norm_l21
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
      sum(col_l2_f)
    from
    (
      select 
        sqrt(sum(i_matrix[v_cur_y][v_cur_x] * i_matrix[v_cur_y][v_cur_x])) as col_l2_f
      from generate_series(1, array_length(i_matrix, 1)) v_cur_y
        , generate_series(1, array_length(i_matrix, 2)) v_cur_x
      group by v_cur_x
    ) v_col_l2_f
  )
  ;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_norm_l21(array[[1,2],[0,7],[5,0],[3,4]])
-- select sm_sc.fv_mx_norm_l21(array[[1,-2,0,7],[5,0,3,4],[0,0,0,0],[0,-2,0,-6]])