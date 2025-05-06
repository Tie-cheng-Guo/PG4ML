-- drop function if exists sm_sc.__fv_delete_kv(varchar(64)[]);
create or replace function sm_sc.__fv_delete_kv
(
  i_arr_keys      varchar(64)[]
)
returns varchar(64)[]
as
$$
declare
  v_key  varchar(64)                    ;
  v_ret  varchar(64)[]  default  array[] :: varchar(64)[];
begin
  if array_ndims(i_arr_keys) = 1
  then 
    foreach v_key in array i_arr_keys
    loop 
      delete from sm_sc.__vt_array_kv
      where arr_key = v_key
      returning arr_key into v_key
      ;
      if v_key is not null 
      then 
        v_ret :=  v_ret || v_key;
      end if
      ;
    end loop;
  end if;
  return v_ret;
end
$$
language plpgsql volatile
parallel safe
cost 1000
;

-- select sm_sc.__fv_delete_kv(array[sm_sc.__fv_set_kv(array[3.1,4.6], 'test_001_val'), 'test_002_val'])