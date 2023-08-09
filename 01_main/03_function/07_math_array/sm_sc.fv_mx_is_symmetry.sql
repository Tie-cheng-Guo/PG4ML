-- drop function sm_sc.fv_mx_is_symmetry(float[][]);
create or replace function sm_sc.fv_mx_is_symmetry
(
  in i_matrix float[][]
)
  returns boolean
as
$$
-- declare here
begin
  if array_length(i_matrix, 1) <> array_length(i_matrix, 2)
  then
    return false;
  elseif array_length(i_matrix, 1) = array_length(i_matrix, 2)
    and exists 
        (
          select from 
            generate_series(1, array_length(i_matrix, 1)) cur_y
            , generate_series(1, cur_y - 1) cur_x
          where i_matrix[cur_y][cur_x] <> i_matrix[cur_x][cur_y]
        )
  then
    return false;
  else 
    return true;
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_mx_is_symmetry(array[[1,2],[3,4]])
-- select sm_sc.fv_mx_is_symmetry(array[[1,3,5,7],[2,4,6,8]])
-- select sm_sc.fv_mx_is_symmetry(array[[1,3,5,7],[3,4,6,8],[5,6,6,8],[7,8,8,8]])