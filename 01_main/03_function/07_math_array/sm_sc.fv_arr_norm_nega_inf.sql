-- drop function sm_sc.fv_arr_norm_nega_inf(float[]);
create or replace function sm_sc.fv_arr_norm_nega_inf
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
      min(abs(i_array[v_cur]))
    from generate_series(1, array_length(i_array, 1)) v_cur
  )
  ;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_arr_norm_nega_inf(array[1,2])
-- select sm_sc.fv_arr_norm_nega_inf(array[1,2,3])