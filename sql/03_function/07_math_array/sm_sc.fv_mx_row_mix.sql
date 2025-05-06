-- drop function if exists sm_sc.fv_mx_row_mix(float[][], int, int, int);
create or replace function sm_sc.fv_mx_row_mix
(
  in i_original_matrix   float[][]   ,
  in i_target_row_no     int                  ,
  in i_target_column_no  int                  ,
  in i_refer_row_no      int
)
  returns float[][]
as
$$
-- declare here
declare v_cur       int := 1;
declare v_times     float;

begin

  if i_original_matrix[i_target_row_no][i_target_column_no] = 0.0
  then 
    return i_original_matrix;

  elseif i_original_matrix[i_refer_row_no][i_target_column_no] = 0.0
  then
    return null::float[][];

  else
    v_times = i_original_matrix[i_target_row_no][i_target_column_no] / i_original_matrix[i_refer_row_no][i_target_column_no];
    while v_cur <= array_length(i_original_matrix, 2)
    loop
      i_original_matrix[i_target_row_no][v_cur] = i_original_matrix[i_target_row_no][v_cur] - i_original_matrix[i_refer_row_no][v_cur] * v_times;
      v_cur = v_cur + 1;
    end loop;
    i_original_matrix[i_target_row_no][i_target_column_no] = 0.0;
    return i_original_matrix;
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_row_mix(array[[1.9, 34.5, 0.55, 45.7, 400.5],[45.9, 4.6, 34.5, 0.55, 45.7],[3.2, 7.7, 1.9, 34.5, 0.55],[4.7, 9.0, 4.6, 34.5, 0.55]], 2, 3, 4)
