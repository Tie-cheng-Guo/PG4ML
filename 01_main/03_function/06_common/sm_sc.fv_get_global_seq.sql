-- -- -- 避免 parallel 调用，也避免获得重复 seq 值，
-- -- -- 将返回单值函数，合并至返回 range 函数。保证单例调用，保证 parallel unsafe 生效
-- -- drop function if exists sm_sc.fv_get_global_seq();
-- -- create or replace function sm_sc.fv_get_global_seq()
-- -- returns bigint
-- -- as
-- -- $$
-- -- -- declare
-- -- begin
-- --   return nextval('sm_sc.__seq_global' :: regclass);
-- -- end
-- -- $$
-- -- language plpgsql volatile
-- -- parallel unsafe
-- -- cost 100
-- -- ;
-- ----------------------------------------------------
drop function if exists sm_sc.fv_get_global_seq(bigint);
create or replace function sm_sc.fv_get_global_seq
(
  i_cnt      bigint   default  1
)
returns int8range
as
$$
-- declare
begin
  return int8range(currval('sm_sc.__seq_global'), setval('sm_sc.__seq_global', currval('sm_sc.__seq_global') + i_cnt), '[]');
end
$$
language plpgsql volatile
parallel unsafe
cost 100
;

-- select sm_sc.fv_get_global_seq()
-- union all 
-- select sm_sc.fv_get_global_seq(3)