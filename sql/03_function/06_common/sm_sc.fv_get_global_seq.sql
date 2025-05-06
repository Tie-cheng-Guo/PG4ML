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
-- drop function if exists sm_sc.fv_get_global_seq(bigint);
create or replace function sm_sc.fv_get_global_seq
(
  i_cnt      bigint   default  1
)
returns int8range
as
$$
-- 不采用 pg sequence 特性，而采用自定义 seq 表。
-- pg sequence 的 currval() 只支持 session 范围内的，获得 seq 当前值，导致各个 session 无法获得一致的全局 seq 当前值。
-- -- -- declare
-- -- begin
-- --   return int8range(currval('sm_sc.__seq_global'), setval('sm_sc.__seq_global', currval('sm_sc.__seq_global') + i_cnt) - 1, '[]');

declare
  v_cur_val      bigint   ;
begin
  perform  from sm_sc.__vt_global_seq where seq_no = 1 for update;
  -- perform pg_sleep(15);
  update sm_sc.__vt_global_seq
  set cur_val = cur_val + i_cnt
  where seq_no = 1
  returning cur_val into v_cur_val
  ;
  return int8range(v_cur_val - i_cnt + 1, v_cur_val, '[]');
end
$$
language plpgsql volatile
parallel unsafe
cost 100
;

-- select sm_sc.fv_get_global_seq()
-- union all 
-- select sm_sc.fv_get_global_seq(3)