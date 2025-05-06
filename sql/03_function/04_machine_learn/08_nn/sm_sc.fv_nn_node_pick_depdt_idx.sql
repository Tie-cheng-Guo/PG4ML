-- drop function if exists sm_sc.fv_nn_node_pick_depdt_idx(varchar(64), int4multirange, float[]);
create or replace function sm_sc.fv_nn_node_pick_depdt_idx
(
  i_node_fn_type           varchar(64),
  i_indepdt_idx            int4multirange[],
  i_node_fn_asso_value     float[]
)
returns     int4multirange[]                    -- 返回采样后的原始序号集合
as 
$$
-- declare 
begin  
  -- 参看 readme 文档，算子说明的“训练集输入集合是否变化”
  if i_node_fn_type = '04_new'
  then 
    return sm_sc.fv_new(i_indepdt_idx, i_node_fn_asso_value[1 : ] :: int[]);
  elsif i_node_fn_type = '04_slice_y' 
  then 
    return 
    (
      select 
        array_agg
        (
          sm_sc.fv_idx_samp_by_samp
          (
            i_indepdt_idx, 
            int4multirange(int4range(i_node_fn_asso_value[1][tb_a_cur_range_no] :: int, coalesce(i_node_fn_asso_value[2][tb_a_cur_range_no], i_node_fn_asso_value[1]) :: int + 1, '[)'))
          )
          order by tb_a_cur_range_no
        )
      from generate_series(1, array_length(i_node_fn_asso_value, 2)) tb_a_cur_range_no(tb_a_cur_range_no)
    );
  elsif i_node_fn_type = '04_sample_y' 
  then 
    return 
    (
      select
        sm_sc.fa_concat_y
        (
          sm_sc.fv_sample_y
          (
            (select a_ele from unnest(i_indepdt_idx) tb_a_range(a_range), generate_series(lower(a_range), upper(a_range) - 1) tb_a_ele(a_ele))
          , i_node_fn_asso_value[1][1]
          , i_node_fn_asso_value[2][1]
          , int4range(i_node_fn_asso_value[3][tb_a_cur_range_no], i_node_fn_asso_value[4][tb_a_cur_range_no] + 1, '[)')
          )
          order by tb_a_cur_range_no
        )
      from generate_series(1, array_length(i_node_fn_asso_value, 2)) tb_a_cur_range_no(tb_a_cur_range_no)
    );
  -- -- elsif i_node_fn_type = '04_rand_pick_y'    -- 不支持反向传播
  -- -- then 
  -- --   return
  -- --     sm_sc.fv_idx_samp_by_samp
  -- --     (
  -- --       i_indepdt_idx, 
  -- --       (
  -- --         select array_agg(int4range(a_ele :: int, a_ele :: int, '[]')) 
  -- --         from unnest(tb_a_indepdt_fore.bi_opr_input_1st[ : ][array_length(tb_a_indepdt_fore.bi_opr_input_1st, 2) : ]) tb_a_ele(a_ele)   -- 规约在 fv_lambda_arr 中， rand_pick_y, rand_pick_x 算子的最后一列/行，为 rand 到的切片序号
  -- --       )
  -- --     );
  -- -- elsif i_node_fn_type = '06_aggr_mx_concat_y'   -- 不支持反向传播
  -- -- then 
  -- --   return sm_sc.fa_range_or(i_indepdt_idx);
  else 
    return i_indepdt_idx;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select 
--   sm_sc.fv_nn_node_pick_depdt_idx
--   (
--     '04_slice_y'
--   , array[int4multirange(int4range(2, 5, '[]')), int4multirange(int4range(7, 11, '[]'))]
--   , array[[3.0], [6.0]]
--   )