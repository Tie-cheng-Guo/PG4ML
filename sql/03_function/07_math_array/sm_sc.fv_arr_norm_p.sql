-- drop function if exists sm_sc.fv_arr_norm_p(float[], int);
create or replace function sm_sc.fv_arr_norm_p
(
  in i_array float[],
  in i_p     int
)
  returns float
as
$$
-- declare here

begin
  if i_p > 0
  then
    return
    (
      select 
        power(sum(power(i_array[v_cur], i_p)), 1.0 :: float/ i_p)
      from generate_series(1, array_length(i_array, 1)) v_cur
    )
    ;
  else
    return null;
  end if;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_arr_norm_p(array[1,2], 2)
-- select sm_sc.fv_arr_norm_p(array[1,2,3], 3)