-- drop function if exists sm_sc.fv_mx_norm_l0(float[][]);
create or replace function sm_sc.fv_mx_norm_l0
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
      count(*)
    from generate_series(1, array_length(i_matrix, 1)) v_cur_y
      , generate_series(1, array_length(i_matrix, 2)) v_cur_x
    where i_matrix[v_cur_y][v_cur_x] <> 0
  )
  ;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_norm_l0(array[[1,2],[0,7],[5,0],[3,4]])
-- select sm_sc.fv_mx_norm_l0(array[[1,-2,0,7],[5,0,3,4],[0,0,0,0],[0,-2,0,-6]])