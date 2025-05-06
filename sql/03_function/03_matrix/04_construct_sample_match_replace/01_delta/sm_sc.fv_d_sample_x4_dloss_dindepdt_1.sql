-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_sample_x4_dloss_dindepdt_1(float[], int, int, int4range[]);
create or replace function sm_sc.fv_d_sample_x4_dloss_dindepdt_1
(
  i_dloss_ddepdt   float[]      ,                -- 损失函数对因变量的导数
  i_array_len_x4    int          ,               -- 自变量数组在采样维度的长度
  -- i_period         int          ,                -- 采样周期长度
  i_window_len     int          ,                -- 约束窗口宽度
  i_simp_ranges    int4range[]                   -- 采样(多)区间
  
)
returns float[]
as
$$
declare 
  v_ret            float[]  ;
  v_period         int      ;      -- i_array 采样周期
  v_window_len_ex  int  :=         -- 生成 i_dloss_ddepdt 的周期
    (
      select 
        max(upper(a_range * int4range(1, i_window_len, '[]'))) 
        - min(lower(a_range * int4range(1, i_window_len, '[]')))
      from unnest(i_simp_ranges) tb_a_range(a_range)
    )
  ;
  v_cur_1          int      ;
  v_cur_2          int      ;
  v_arr_idxs       int[]    ;    -- 采样到的切片下标集合
  v_dd_idxss       text[]   ;    -- 采样到的每个单元切片对应导数下标集合，再所有单元切片 array_agg 集合，相当于不整齐的二维 int 数组。
  -- v_zero_slice     float[]  ;    -- 零切片
begin
  -- set search_path to sm_sc;
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_dloss_ddepdt) <> 4
    then 
      raise exception 'unsupport ndims of i_dloss_ddepdt.';
    elsif array_length(i_dloss_ddepdt, 4) % v_window_len_ex > 0
      or i_array_len_x4 / (array_length(i_dloss_ddepdt, 4) % v_window_len_ex) > 0
    then 
      raise exception 'unmatch 4d length of i_dloss_ddepdt, simp_range or i_array_len for period.';
    end if;
  end if;
  
  -- 窗口约束重整采样区间
  for v_cur_1 in 1 .. array_length(i_simp_ranges, 1)
  loop
    i_simp_ranges[v_cur_1] := i_simp_ranges[v_cur_1] * int4range(1, i_window_len, '[]');
  end loop;
  
  -- 换算出 i_array 周期
  v_period  :=   i_array_len_x4 / (array_length(i_dloss_ddepdt, 4) / v_window_len_ex);
  
  v_ret     :=   array_fill(0.0, array[array_length(i_dloss_ddepdt, 1)] || array_length(i_dloss_ddepdt, 2) || array_length(i_dloss_ddepdt, 3) || i_array_len_x4);

  with recursive
  -- 迭代 cte 算出区间与 dloss_ddepdt 的位置对应关系
  cte_range_dd_idx as 
  (
    select 
      1 as a_range_idx,
      lower(i_simp_ranges[1])                           as a_lower,
      upper(i_simp_ranges[1]) - lower(i_simp_ranges[1]) as a_range_len,
      1 as a_range_dd_pos
    union all 
    select 
      a_range_idx + 1 as a_range_idx,
      lower(i_simp_ranges[a_range_idx + 1])                                         as a_lower,
      upper(i_simp_ranges[a_range_idx + 1]) - lower(i_simp_ranges[a_range_idx + 1]) as a_range_len,
      a_range_dd_pos + a_range_len as a_range_dd_pos
    from cte_range_dd_idx
    where a_range_idx < array_length(i_simp_ranges, 1)
  ),
  -- 算出区间与 i_arr 的下标对应关系
  cte_range_arr_idx as 
  (
    select 
      a_arr_idx,
      a_range_idx
    from generate_series(1, array_length(i_simp_ranges, 1)) tb_a_range_idx(a_range_idx)
      , generate_series
        (
          lower(i_simp_ranges[a_range_idx])
        , upper(i_simp_ranges[a_range_idx]) - 1
        ) tb_a_cur_idx(a_arr_idx)
    -- where a_arr_idx <@ i_simp_ranges[a_range_idx]
  ),
  -- 映射出  i_arr 每一个切片与 dloss_ddepdt 的对应关系，并以 i_arr 单位切片为分组，agg后，记录一对多关系，且聚合滤掉未被采样位置。
  cte_map_arr_idx_dd_idx_per_period as
  (
    select 
      tb_a_arr_idx.a_arr_idx,
      array_agg
      (
        tb_a_dd_idx.a_range_dd_pos 
        + tb_a_arr_idx.a_arr_idx 
        - tb_a_dd_idx.a_lower 
        -- order by tb_a_dd_idx.a_range_dd_pos
      ) :: text as a_dd_idxs
    from cte_range_arr_idx tb_a_arr_idx
    inner join cte_range_dd_idx tb_a_dd_idx
      on tb_a_dd_idx.a_range_idx = tb_a_arr_idx.a_range_idx
    group by tb_a_arr_idx.a_arr_idx
    having count(tb_a_dd_idx.a_range_dd_pos) > 0
  )
  select 
    array_agg(a_arr_idx order by a_arr_idx),
    array_agg(a_dd_idxs order by a_arr_idx)
  into 
    v_arr_idxs,
    v_dd_idxss
  from cte_map_arr_idx_dd_idx_per_period
  ;
  
  -- 逐个周期，以单位切片为分组，合计 dloss_ddepdt，赋值到 v_ret 对应下标位置，未被采样切片，返回零切片为导数
  for v_cur_1 in 1 .. (array_length(i_dloss_ddepdt, 4) / v_window_len_ex)
  loop 
    for v_cur_2 in 1 .. array_length(v_arr_idxs, 1)
    loop 
      if (v_cur_1 - 1) * v_period + v_arr_idxs[v_cur_2] between 1 and array_length(v_ret, 4)
      then 
        v_ret[ : ][ : ][ : ][(v_cur_1 - 1) * v_period + v_arr_idxs[v_cur_2] : (v_cur_1 - 1) * v_period + v_arr_idxs[v_cur_2]] :=
        (
          select 
            sm_sc.fa_mx_sum
            (
              i_dloss_ddepdt
              [ : ]
              [ : ]
              [ : ]
              [
                (v_dd_idxss[v_cur_2] :: int[])[a_cur_dd_idx] 
              : (v_dd_idxss[v_cur_2] :: int[])[a_cur_dd_idx]
              ]
            )
          from generate_series(1, array_length((v_dd_idxss[v_cur_2] :: int[]), 1)) tb_a_cur_dd_idx(a_cur_dd_idx)
        );
      end if;
    end loop;
  end loop;
  
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_sample_x4_dloss_dindepdt_1
--   (
--     array
--     [[[
--       [1, 2, 3, 4, 5, 6, 7, 8, 9]
--     , [11, 12, 13, 14, 15, 16 ,17 ,18 ,19]
--     ]]]
--   , 15
--   , 3
--   , array[int4range(1, 3, '[]'), int4range(2, 5, '[]')]
--   );