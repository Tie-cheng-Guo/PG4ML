-- drop function if exists sm_sc.__fv_set_kv(float[], varchar(64));
create or replace function sm_sc.__fv_set_kv
(
  i_arr          float[]
, i_arr_key      varchar(64)    default null
)
returns varchar(64)
as
$$
-- declare
  -- v_key  varchar(64);
begin
  if i_arr is not null or i_arr_key is not null
  then 
    insert into sm_sc.__vt_array_kv
    (
      arr_key
    , arr_val
    )
    values 
    (
      coalesce(i_arr_key, gen_random_uuid()::varchar(64))
    , i_arr
    )
    on conflict (arr_key) do
    update set 
      arr_val           = EXCLUDED.arr_val
    , last_update_date  = now()
    returning arr_key into i_arr_key
    ;
    return i_arr_key;
  else 
    return null;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 1000
;

-- select sm_sc.__fv_set_kv(array[1.0, 2.3])
-- select sm_sc.__fv_set_kv(sm_sc.fv_new_rand(array[2, 3]))