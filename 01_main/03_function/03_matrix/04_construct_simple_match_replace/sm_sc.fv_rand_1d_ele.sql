-- drop function if exists sm_sc.fv_rand_1d_ele(int, int);
create or replace function sm_sc.fv_rand_1d_ele
(
  i_all_cnt                int,
  i_pick_cnt               int
)
returns int[]
as
$$
declare -- here

begin
  return 
  (
    select 
      array_agg(round(random() * i_all_cnt + 0.5 :: float)::int)
    from generate_series(1, i_pick_cnt)
  );
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select sm_sc.fv_rand_1d_ele(8, 3);