-- drop function if exists sm_sc.fv_mx_times_row(float[][], int, float);
create or replace function sm_sc.fv_mx_times_row
(
  in i_original_matrix   float[][]   ,
  in i_row_no            int                  ,
  in i_times             float
)
  returns float[][]
as
$$
-- declare here
declare v_cur int := 1;

begin
  while v_cur <= array_length(i_original_matrix, 2)
  loop
    i_original_matrix[i_row_no][v_cur] = i_original_matrix[i_row_no][v_cur] * i_times;
    v_cur = v_cur + 1;
  end loop;

  return i_original_matrix;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_times_row(array[[1.9, 34.5, 0.55, 45.7, 400.5],[45.9, 4.6, 34.5, 0.55, 45.7],[3.2, 7.7, 1.9, 34.5, 0.55],[4.7, 9.0, 4.6, 34.5, 0.55]], 2, 3.3)
