-- drop function if exists sm_sc.fv_idx_samp_by_samp(int4range[], int4range[]);
create or replace function sm_sc.fv_idx_samp_by_samp
(
  i_sour_idxes         int4range[]     ,   -- 采样前原始序号集合
  i_fn_idxes           int4range[]         -- 本次采样到的顺序号集合
)
returns     int4range[]                    -- 返回采样后的原始序号集合
as 
$$
-- declare 
begin 
  if array_ndims(i_sour_idxes) > 1 or array_ndims(i_fn_idxes) > 1 
  then 
    raise exception 'unsupport ndims > 1.  ';
    
  -- 当 $2 是 null 时，返回 $1
  elsif i_fn_idxes is null 
  then 
    return i_sour_idxes;
    
  -- 当 $1 是单区间（通常来自 slice, random）
  elsif array_length(i_sour_idxes, 1) = 1
  then 
    return 
    (
      select 
        array_agg
        (
          int4range
          (
            (greatest(lower(i_sour_idxes[1]) + lower(a_idx) - 1, lower(i_sour_idxes[1]))) :: int,
            (least(lower(i_sour_idxes[1]) + (upper(a_idx) - 1) - 1, (upper(i_sour_idxes[1]) - 1))) :: int,
            '[]'
          )
        )
      from unnest(i_fn_idxes) tb_a_idx(a_idx)
      where lower(a_idx) <= (upper(i_sour_idxes[1]) - 1)
        and (upper(a_idx) - 1) >= 1
        and a_idx is not null
    )
    ;
  else 
    return 
    (
      with 
      cte_sour_unnest as 
      (
        select 
          row_number() over() as idx_y_no,
          (upper(abs_idx_range) - 1) - lower(abs_idx_range) + 1 as idx_range_len,
          abs_idx_range
        from unnest(i_sour_idxes) tb_abs_idx_range(abs_idx_range)
        where abs_idx_range is not null
      ),
      cte_fn_unnest as 
      (
        select 
          tb_a_main.idx_y_no,
          coalesce(sum(tb_a_above.idx_range_len), 0) as above_idx_range_len,
          tb_a_main.abs_idx_range,
          int4range
          (
            (coalesce(sum(tb_a_above.idx_range_len), 0) + 1) :: int,
            (coalesce(sum(tb_a_above.idx_range_len), 0) + max(tb_a_main.idx_range_len)) :: int,
            '[]'
          ) as a_fn_idx_range
        from cte_sour_unnest tb_a_main
        left join cte_sour_unnest tb_a_above
          on tb_a_above.idx_y_no < tb_a_main.idx_y_no
        group by tb_a_main.idx_y_no, tb_a_main.abs_idx_range
      ),
      cte_rela_range as 
      (
        select 
          tb_a_sour.idx_y_no,
          tb_a_sour.abs_idx_range,
          tb_a_sour.above_idx_range_len,
          tb_a_sour.a_fn_idx_range * tb_a_fn_idx.a_fn_idx as rela_idx_range
        from unnest(i_fn_idxes) tb_a_fn_idx(a_fn_idx)
        inner join cte_fn_unnest tb_a_sour
          on tb_a_sour.a_fn_idx_range && tb_a_fn_idx.a_fn_idx  
      )        
      select 
        array_agg 
        (
          int4range 
          (
            (lower(abs_idx_range) + lower(rela_idx_range) - above_idx_range_len - 1) :: int,
            (lower(abs_idx_range) + (upper(rela_idx_range) - 1) - above_idx_range_len - 1) :: int,
            '[]'
          )
        )
      from cte_rela_range
    )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- -- 当 $2 是 null 时，返回 $1
-- select 
--   sm_sc.fv_idx_samp_by_samp
--   (
--     array
--     [
--       int4range(1, 3, '[]'),
--       int4range(8, 12, '[]'),
--       int4range(13, 15, '[]')
--     ],
--     null
--   )

-- -- 当 $1 是单值单区间，返回单值多区间（通常来自 random）
-- select 
--   sm_sc.fv_idx_samp_by_samp
--   (
--     array
--     [
--       int4range(1, 15, '[]')
--     ],
--     array
--     [
--       int4range(3, 3, '[]'),
--       int4range(6, 6, '[]'),
--       int4range(8, 8, '[]'),
--       int4range(9, 9, '[]')  --,
--       -- int4range(19, 19, '[]')
--     ]
--   )

-- -- 当 $1, $2 是普通多值或多区间时，返回多区间（通常来自 random）
-- select 
--   sm_sc.fv_idx_samp_by_samp
--   (
--     array
--     [
--       int4range(1, 3, '[]'),
--       int4range(8, 12, '[]'),
--       int4range(13, 15, '[]')
--     ],
--     array
--     [
--       int4range(4, 6, '[]'),
--       int4range(8, 12, '[]') -- ,
--       -- int4range(13, 15, '[]')
--     ]
--   )