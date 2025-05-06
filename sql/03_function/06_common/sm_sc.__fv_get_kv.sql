-- drop function if exists sm_sc.__fv_get_kv(varchar(64), boolean);
create or replace function sm_sc.__fv_get_kv
(
  i_arr_key      varchar(64)
, i_if_delete    boolean     default   false
)
returns float[]
as
$$
declare
  v_ret    float[];
begin
  if i_if_delete 
  then 
    delete from sm_sc.__vt_array_kv where arr_key = i_arr_key
    returning arr_val into v_ret
    ;
    return v_ret;
  else 
    return 
      (select arr_val from sm_sc.__vt_array_kv where arr_key = i_arr_key)
    ;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 1000
;

-- select sm_sc.__fv_get_kv(sm_sc.__fv_set_kv(sm_sc.fv_new_rand(array[2, 3])))