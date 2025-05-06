-- drop function if exists sm_sc.__fv_set_kvs(float[], varchar(64)[]);
create or replace function sm_sc.__fv_set_kvs
(
  i_arrs          sm_sc.__typ_array_ex[]
, i_arr_keys      varchar(64)[]    default null
)
returns varchar(64)[]
as
$$
-- declare
  -- v_key  varchar(64);
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_arrs) <> 1 or array_ndims(i_arr_keys) <> 1
    then
      raise exception 'unsupport array_ndims. ';
    elsif array_length(i_arrs, 1) <> array_length(i_arr_keys, 1)
    then 
      raise exception 'unmatched array_length. ';
    end if;
  end if;

  if sm_sc.fv_aggr_slice_coalesce(i_arrs) is not null or sm_sc.fv_aggr_slice_coalesce(i_arr_keys) is not null
  then 
    with 
    cte_unnest as 
    (
      select
        a_no
      , coalesce(i_arr_keys[a_no], gen_random_uuid()::varchar(64)) as a_key
      , i_arrs[a_no].m_array as a_value
      from generate_series(1, array_length(i_arrs, 1)) tb_a(a_no)
      where i_arr_keys[a_no] is not null or i_arrs[a_no].m_array is not null
    ),
    cte_upd as 
    (
      insert into sm_sc.__vt_array_kv
      (
        arr_key
      , arr_val
      )
      select
        coalesce(i_arr_keys[a_no], gen_random_uuid()::varchar(64))
      , i_arrs[a_no].m_array
      from cte_unnest
      on conflict (arr_key) do
      update set 
        arr_val           = EXCLUDED.arr_val
      , last_update_date  = now()
    )
    select 
      array_agg(a_key order by a_no)
    into i_arr_keys
    from cte_unnest
    ;
    return i_arr_keys;
  else 
    return null;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 1000
;

-- select sm_sc.__fv_set_kvs(array[array[1.0, 2.3] :: float[] :: sm_sc.__typ_array_ex, array[-1.0, 1.3, 9.4] :: float[] :: sm_sc.__typ_array_ex])
-- select sm_sc.__fv_set_kvs(array[array[1.0, 2.3] :: float[] :: sm_sc.__typ_array_ex, array[-1.0, 1.3, 9.4] :: float[] :: sm_sc.__typ_array_ex, null])
-- select sm_sc.__fv_set_kvs(array[sm_sc.fv_new_rand(array[2, 3]) :: sm_sc.__typ_array_ex, array[-1.0, 1.3, 9.4] :: float[] :: sm_sc.__typ_array_ex], array['test_key_1', null])
-- select sm_sc.__fv_set_kvs(array[sm_sc.fv_new_rand(array[2, 3]) :: sm_sc.__typ_array_ex, array[-1.0, 1.3, 9.4] :: float[] :: sm_sc.__typ_array_ex, null], array['test_key_1', null, null])