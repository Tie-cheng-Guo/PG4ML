-- -- 用于从规约的 buff 表中分组随机获得单次训练的小批量
-- -- 规约输出
-- drop function if exists sm_sc.ft_nn_buff_slice_rand(bigint, int4range[], int[]);
create or replace function sm_sc.ft_nn_buff_slice_rand
(
  i_work_no            bigint             ,
  i_slice_ranges       int4range[]        ,     
  i_rand_pick_cnts     int[]    
)
-- -- 规约：buff 表为 sm_sc.tb_nn_train_input_buff
returns table
(
  o_ord_no               int,
  o_slice_rand_pick      float[] 
)
as
$$
declare 
  v_ord_nos     int[]  := 
    (
      with
      cte_pick_ord_no as 
      (
        select 
          row_number() over() as a_range_no,
          -- 允许采样有小概率重复，对训练影响可控，避免 fv_rand_1d_ele_pick 的递归调用对内存的较大开销
          -- -- sm_sc.fv_rand_1d_ele_pick
          sm_sc.fv_rand_1d_ele
          (
            upper(a_range) - lower(a_range), i_rand_pick_cnts[row_number() over()]
          ) :: int[] 
          +` (lower(a_range) - 1) as a_range_eles
        from unnest(i_slice_ranges) tb_a(a_range)
      )
      select 
        sm_sc.fa_array_concat(a_range_eles order by a_range_no)
      from cte_pick_ord_no
    )
  ;
begin

  return query
    select 
      tb_a_buff.ord_no as o_ord_no,
      tb_a_buff.i_indepdt    as o_slice_rand_pick
    from generate_series(1, array_length(v_ord_nos, 1)) tb_a(a_ord_no)
    left join sm_sc.tb_nn_train_input_buff tb_a_buff
      on tb_a_buff.ord_no = v_ord_nos[a_ord_no]
        and tb_a_buff.work_no = i_work_no
  ;

end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select *
-- from
--   sm_sc.ft_nn_buff_slice_rand
--   (
--     2022032401,
--     array
--     [
--       int4range(1, 5923, '[]'), 
--       int4range(5924, 12665, '[]'),
--       int4range(12666, 18623, '[]'),
--       int4range(18624, 24754, '[]'),
--       int4range(24755, 30596, '[]'),
--       int4range(30597, 36017, '[]'),
--       int4range(36018, 41935, '[]'),
--       int4range(41936, 48200, '[]'),
--       int4range(48201, 54052, '[]'),
--       int4range(54053, 60001, '[]')
--     ],
--     array_fill(7, array[10])
--   ) tb_a
