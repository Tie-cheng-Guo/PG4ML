-- drop function if exists sm_sc.__fv_get_kvs(varchar(64)[], boolean);
create or replace function sm_sc.__fv_get_kvs
(
  i_arr_keys      varchar(64)[]
, i_if_delete    boolean     default   false
)
returns sm_sc.__typ_array_ex[]
as
$$
declare
  v_ret  sm_sc.__typ_array_ex[];
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_arr_keys) <> 1
    then
      raise exception 'unsupport array_ndims. ';
    end if;
  end if;

  if i_if_delete 
  then 
    with 
    cte_key as 
    (
      select  
        a_no
      , i_arr_keys[a_no] as a_key
      from generate_series(1, array_length(i_arr_keys, 1)) tb_a(a_no)
    ),
    cte_del as 
    (
      delete from sm_sc.__vt_array_kv tb_a_kv
      using cte_key tb_a_key
      where tb_a_kv.arr_key = tb_a_key.a_key
      returning tb_a_key.a_no, tb_a_kv.arr_val
    )
    select 
      array_agg(tb_a_kv.arr_val :: sm_sc.__typ_array_ex order by tb_a.a_no) 
    into v_ret
    from generate_series(1, array_length(i_arr_keys, 1)) tb_a(a_no)
    left join cte_del tb_a_kv
      on tb_a_kv.a_no = tb_a.a_no
    ;
    return v_ret;
  else 
    return 
    (
      select 
        array_agg(tb_a_kv.arr_val :: sm_sc.__typ_array_ex order by tb_a.a_no)
      from generate_series(1, array_length(i_arr_keys, 1)) tb_a(a_no)
      left join sm_sc.__vt_array_kv tb_a_kv
        on arr_key = i_arr_keys[a_no]
    )
    ;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 1000
;

-- select sm_sc.__fv_get_kvs(array[sm_sc.__fv_set_kv(sm_sc.fv_new_rand(array[2, 3]))])
-- select sm_sc.__fv_get_kvs(array[sm_sc.__fv_set_kv(sm_sc.fv_new_rand(array[2, 3])), 'no_such_key'])
-- select sm_sc.__fv_get_kvs(array[sm_sc.__fv_set_kv(sm_sc.fv_new_rand(array[2, 3]))], true)
-- select sm_sc.__fv_get_kvs(array[sm_sc.__fv_set_kv(sm_sc.fv_new_rand(array[2, 3])), 'no_such_key'], true)