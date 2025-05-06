-- drop function if exists sm_sc.ft_regexp_matches(text, text, text);
create or replace function sm_sc.ft_regexp_matches
(
  in i_text text, 
  in i_reg  text, 
  in i_opt  text default ''
)
  -- returns timestamp 
  returns table
    (o_matches_text text[])
as
$$
-- declare here
begin
  -- 最终输出
  return query
    select regexp_matches(i_text, i_reg, i_opt) as o_matches_text
  ; 

  -- exception, then null
  exception
    when others 
    then 
      return query select null;
end
$$
  language plpgsql volatile
  cost 100;

-- select sm_sc.ft_regexp_matches('aaaaabbbaaa', 'a.a')
-- select sm_sc.ft_regexp_matches('aaaaabbbaaa', 'A.A', 'gi')