-- drop function if exists sm_sc.fv_enum_rand_pick(varchar(64), int);
create or replace function sm_sc.fv_enum_rand_pick
(
  i_enum_type_name    varchar(64),
  i_cnt               int
)
returns name[] -- pg_enum%enumlabel
as
$$
declare -- here
  v_enum_type_name    varchar(64)  := (select coalesce(a_match[1], i_enum_type_name) from regexp_matches(i_enum_type_name, '(?<=\.)[^\.]+') tb_a(a_match) limit 1);
  v_enum_type_scheme  varchar(64)  := (select coalesce(a_match[1], 'public') from regexp_matches(i_enum_type_name, '[^\.]+(?=\.)') tb_a(a_match) limit 1);
  v_enum_dic    name[]  :=  
  (
    select 
      array_agg(tb_a_enum.enumlabel)
    from pg_type tb_a_ty
    inner join pg_enum tb_a_enum
      on tb_a_enum.enumtypid = tb_a_ty.oid
	inner join pg_namespace tb_a_ns
	  on tb_a_ns.oid = tb_a_ty.typnamespace
    where tb_a_ty.typname = v_enum_type_name
	  and tb_a_ns.nspname = v_enum_type_scheme
  );
  v_dic_len    int      :=  array_length(v_enum_dic, 1);

begin
  if i_cnt > v_dic_len
  then
    raise exception 'pick_cnt must be less than all_cnt.';
  else
    return   
    (
      select 
        array_agg(v_enum_dic[a_cur])
      from unnest(sm_sc.fv_rand_1d_ele_pick(v_dic_len, i_cnt)) tb_a(a_cur)
    ) 
  ;
  end if;
end
$$
language plpgsql volatile
parallel unsafe
cost 100;

-- create type sm_sc.typ_enum_day as enum('SUN','MON','TUE','WED','THU','FRI','SAT');
-- select sm_sc.fv_enum_rand_pick('sm_sc.typ_enum_day', 3);