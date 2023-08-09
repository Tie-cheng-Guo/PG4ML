-- drop function if exists sm_sc.fv_enum_rand(varchar(64), int);
create or replace function sm_sc.fv_enum_rand
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
  v_enum_dic          name[]       :=  
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
  return 
  (
    select 
      array_agg(v_enum_dic[round(random() * v_dic_len + 0.5 :: float)::int])
    from generate_series(1, i_cnt)
  )
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- create type sm_sc.typ_enum_day as enum('SUN','MON','TUE','WED','THU','FRI','SAT');
-- -- -- select sm_sc.fv_enum_rand('sm_sc.typ_enum_day', 3);
-- select sm_sc.fv_enum_rand('typ_enum_day', 3);