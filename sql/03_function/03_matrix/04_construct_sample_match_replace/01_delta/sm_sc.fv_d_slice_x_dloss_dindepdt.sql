-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_slice_x_dloss_dindepdt(float[], int, int4range[]);
create or replace function sm_sc.fv_d_slice_x_dloss_dindepdt
(
  i_dloss_ddepdt   float[]    ,
  i_arr_len_x      int      ,
  i_slice_range    int4range[]
)
returns float[]
as
$$
declare 
  v_ret    float[]  ;
  v_cur    record   ;
begin
  -- set search_path to sm_sc;
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_dloss_ddepdt) not between 2 and 4
    then 
      raise exception 'unsupport ndims of i_dloss_ddepdt.';
    elsif i_arr_len_x < (select max(upper(a_range)) - 1 from unnest(i_slice_range) tb_a_range(a_range))
      or 1 > (select min(lower(a_range)) from unnest(i_slice_range) tb_a_range(a_range))
    then
      raise exception 'overflow range for i_arr_len_x.';
    elsif array_length(i_dloss_ddepdt, 2) <> (select sum(upper(a_range) - lower(a_range)) from unnest(i_slice_range) tb_a_range(a_range))
    then 
      raise exception 'unmatched 2d length between i_dloss_ddepdt and i_slice_range';
    end if;
  end if;
  
  if array_ndims(i_dloss_ddepdt) = 2
  then 
    v_ret := array_fill(0.0, array[array_length(i_dloss_ddepdt, 1)] || i_arr_len_x);
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    v_ret := array_fill(0.0, array[array_length(i_dloss_ddepdt, 1)] || i_arr_len_x || array[array_length(i_dloss_ddepdt, 3)]);
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    v_ret := array_fill(0.0, array[array_length(i_dloss_ddepdt, 1)] || i_arr_len_x || array[array_length(i_dloss_ddepdt, 3), array_length(i_dloss_ddepdt, 4)]);
  end if;
  
  for v_cur in 
    with recursive
    -- 迭代 cte 算出区间与 dloss_ddepdt 的位置对应关系
    cte_range_dd_idx as 
    (
      select 
        1 as a_range_idx,
        lower(i_slice_range[1])                           as a_lower,
        -- upper(i_slice_range[1]) - 1                       as a_upper,
        upper(i_slice_range[1]) - lower(i_slice_range[1]) as a_range_len,
        1 as a_range_dd_pos
      union all 
      select 
        a_range_idx + 1 as a_range_idx,
        lower(i_slice_range[a_range_idx + 1])                                         as a_lower,
        -- upper(i_slice_range[a_range_idx + 1]) - 1                                     as a_upper,
        upper(i_slice_range[a_range_idx + 1]) - lower(i_slice_range[a_range_idx + 1]) as a_range_len,
        a_range_dd_pos + a_range_len as a_range_dd_pos
      from cte_range_dd_idx
      where a_range_idx < array_length(i_slice_range, 1)
    ),
    -- 算出区间与 i_arr 的下标对应关系
    cte_range_arr_idx as 
    (
      select 
        a_arr_idx,
        a_range_idx
      from generate_series(1, i_arr_len_x) tb_a_cur_idx(a_arr_idx)
        , generate_series(1, array_length(i_slice_range, 1)) tb_a_range_idx(a_range_idx)
      where a_arr_idx <@ i_slice_range[a_range_idx]
    )
    -- 映射出  i_arr 每一个切片与 dloss_ddepdt 的对应关系，并以 i_arr 切片为分组，合计 dloss_ddepdt 切片导数，从而反向传播求导
    select 
      tb_a_arr_idx.a_arr_idx,
      sm_sc.fa_mx_sum(i_dloss_ddepdt[ : ][a_range_dd_pos + a_arr_idx - a_lower : a_range_dd_pos + a_arr_idx - a_lower]) as a_dloss_dindepdt
    from cte_range_arr_idx tb_a_arr_idx
    inner join cte_range_dd_idx tb_a_dd_idx
      on tb_a_dd_idx.a_range_idx = tb_a_arr_idx.a_range_idx
    group by tb_a_arr_idx.a_arr_idx
  loop 
    v_ret[ : ][v_cur.a_arr_idx : v_cur.a_arr_idx] := v_cur.a_dloss_dindepdt;
  end loop;
  
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_d_slice_x_dloss_dindepdt
--   (
--     array[[1, 2, 3, 4, 5], [11, 12, 13, 14, 15]]
--   , 7
--   , array[int4range(1, 3, '[]'), int4range(2, 3, '[]')]
--   );

-- select sm_sc.fv_d_slice_x_dloss_dindepdt
--   (
--     array
--     [
--       [[[1, -1], [2, -2]], [[3, -3], [4, -4]], [[5, -5], [6, -6]], [[7, -7], [8, -8]], [[9.7, -9], [10, -10]]]
--     , [[[1, -1], [2, -2]], [[3, -3], [4, -4]], [[5, -5], [6, -6]], [[7, -7], [8, -8]], [[9.7, -9], [10, -10]]]
--     ]::float[]
--   , 7
--   , array[int4range(1, 3, '[]'), int4range(2, 3, '[]')]
--   );

