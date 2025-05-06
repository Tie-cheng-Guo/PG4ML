-- drop function if exists sm_sc.fv_regexp_matches_strs_once(text, text, text);
create or replace function sm_sc.fv_regexp_matches_strs_once
(
  in i_text text, 
  in i_reg  text, 
  in i_opt  text default ''
)
  -- returns timestamp 
  returns text[]
as
$$
-- declare here
begin
  -- 最终输出
  if i_opt like '%g%'
  then
    raise exception 'this fn not support globel option';
  else
    return (select regexp_matches(i_text, i_reg, i_opt) limit 1);
  end if
  ; 

  -- exception, then null
  exception
    when others 
    then 
      return null;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.fv_regexp_matches_strs_once('aaaaabbbaaa', 'a.a')
-- select sm_sc.fv_regexp_matches_strs_once('aaaaabbbaaa', 'A.A', 'i')