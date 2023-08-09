-- drop function sm_sc.fv_arr_norm_2(float[]);
create or replace function sm_sc.fv_arr_norm_2
(
  in i_array float[]
)
  returns float
as
$$
-- declare here

begin
  return
  (
    select 
      sqrt(sum(i_array[v_cur] * i_array[v_cur]))
    from generate_series(1, array_length(i_array, 1)) v_cur
  )
  ;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_arr_norm_2(array[1,2])
-- select sm_sc.fv_arr_norm_2(array[1,2,3])