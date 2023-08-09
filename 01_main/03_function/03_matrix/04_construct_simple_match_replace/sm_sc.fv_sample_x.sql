-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_sample_x(anyarray, int, int, int4range[], anyarray);
create or replace function sm_sc.fv_sample_x   -- 5 个参数
(
  i_array          anyarray          ,
  i_period         int               ,                                 -- 采样周期
  i_window_len     int               ,                                 -- 1d 采样窗口的长度或 2d 采样的窗口宽度。 null 值表示不约束窗口宽度
  i_simp_ranges    int4range[]       ,                                 -- 越界填充，类似于升采样，周期纵向插入 i_fill_values 元素稀释原矩阵
                                                                       -- 如果下界小于窗口左边界，则每组样本左侧填充 i_fill_values; 如果上界也小于窗口左边界，那么该 sim_range 和窗口无交集，抽样将全部是填充元素
                                                                       -- 如果上界大于窗口右边界，那么右侧填充 i_fill_values; 如果下界也大于窗口右边界，那么该 sim_range 和窗口无交集，抽样将全部是填充元素
                                                                       -- 其中超出上下界的数值代表 i_fill_values 重复填充次数，例如 -1 代表左侧重复填充 1 - (-1) = 2 次
  i_fill_values    anyarray                                            -- 如果用 default 值，那么参数的伪类型不易支持，那么分为两个入参不同的重载函数
)
returns anyarray
as
$$
declare
  v_fill_values    i_array%type  := i_fill_values;
begin
  if v_fill_values is null and array_ndims(i_array) = 2
  then
    v_fill_values := i_array[1 : 1][1 : 1];
    v_fill_values[1][1] := null;
  elsif v_fill_values is null and array_ndims(i_array) = 1
  then 
    v_fill_values := i_array[1 : 1];
    v_fill_values[1] := null;
  end if;

  -- 审计维度数量
  if v_fill_values is not null and i_array is not null and array_ndims(v_fill_values) <> array_ndims(i_array)
  then
    raise exception 'array_ndims of i_fill_values should be the same as i_array''s.  v_fill_values：%', v_fill_values;
  -- 审计填充数值矩阵的高度
  elsif v_fill_values is not null and array_ndims(v_fill_values) = 2 and array_length(v_fill_values, 1) not in (1, array_length(i_array, 1))
  then
    raise exception 'height of 2d i_fill_values should be 1 or the same as 2d i_array''s. ';
  -- 审计采样周期窗口在末尾刚好完整覆盖，不会产生碎片
  elsif
    array_ndims(i_array) = 1 and array_length(i_array, 1) % i_period > 0
    or array_ndims(i_array) = 2 and array_length(i_array, 2) % i_period > 0
  then
    raise exception 'the slide window with i_period: % and i_window_len: % is not intact at the tail of i_array len: %', i_period, i_window_len, case array_ndims(i_array) when 1 then array_length(i_array, 1) when 2 then array_length(i_array, 2) end;
  end if;

  i_window_len := coalesce(i_window_len, least((select max(upper(a_range)) - 1 from unnest(i_simp_ranges) tb_a(a_range)), case array_ndims(i_array) when 1 then array_length(i_array, 1) when 2 then array_length(i_array, 2) end));

  -- set search_path to sm_sc;
  if array_ndims(i_array) is null
  then 
    return i_array;
  elsif array_ndims(i_array) = 1
  then
    return 
    (
      select
        sm_sc.fa_array_concat
        (
          (
            select 
              sm_sc.fa_array_concat(v_fill_values) 
            from 
              generate_series
              (
                lower(a_range * int4range(null::int, 0, '[]')), 
                upper(a_range * int4range(null::int, 0, '[]')) - 1
              ) tb_a_filler_upper(a_upper_idx)
          )
          ||
          sm_sc.fv_rpad
          (
            i_array
            [
              a_idx + lower(a_range * int4range(1, i_window_len, '[]'))
              : 
              a_idx + upper(a_range * int4range(1, i_window_len, '[]')) - 1
            ]
            , upper(a_range * int4range(1, i_window_len, '[]')) - lower(a_range * int4range(1, i_window_len, '[]'))
            , v_fill_values
          )
          ||
          (
            select 
              sm_sc.fa_array_concat(v_fill_values) 
            from 
              generate_series
              (
                lower(a_range * int4range(i_window_len + 1, null::int, '[]')),
                upper(a_range * int4range(i_window_len + 1, null::int, '[]')) - 1
              ) tb_a_filler_upper(a_upper_idx)
          )
          order by a_idx, a_no
        )
      from generate_series(0, array_length(i_array, 1) - 1, i_period) tb_a_idx(a_idx)    -- -- generate_series(0, array_length(i_array, 1) - i_window_len, i_period) tb_a_idx(a_idx)
        , (
            select 
              row_number() over() as a_no
              , a_range 
            from unnest(i_simp_ranges) tb_a_ranges(a_range)
          ) tb_a_range      
    )
    ;
  elsif array_ndims(i_array) = 2
  then
    return 	
    (
      select
        sm_sc.fa_mx_concat_x
        (
          (
            select 
              sm_sc.fa_mx_concat_x(v_fill_values) 
            from 
              generate_series
              (
                lower(a_range * int4range(null::int, 0, '[]')), 
                upper(a_range * int4range(null::int, 0, '[]')) - 1
              ) tb_a_filler_upper(a_upper_idx)
          )
          ||||
          sm_sc.fv_rpad
          (
            i_array[ : ]
            [
              a_idx + lower(a_range * int4range(1, i_window_len, '[]'))
              : 
              a_idx + upper(a_range * int4range(1, i_window_len, '[]')) - 1
            ]
            , upper(a_range * int4range(1, i_window_len, '[]')) - lower(a_range * int4range(1, i_window_len, '[]'))
            , v_fill_values
          )
          ||||
          (
            select 
              sm_sc.fa_mx_concat_x(v_fill_values) 
            from 
              generate_series
              (
                lower(a_range * int4range(i_window_len + 1, null::int, '[]')), 
                upper(a_range * int4range(i_window_len + 1, null::int, '[]')) - 1
              ) tb_a_filler_upper(a_upper_idx)
          )
          order by a_idx, a_no
        )
      from generate_series(0, array_length(i_array, 2) - 1, i_period) tb_a_idx(a_idx)   -- -- generate_series(0, array_length(i_array, 2) - i_window_len, i_period) tb_a_idx(a_idx)
        , (
            select 
              row_number() over() as a_no
              , a_range 
            from unnest(i_simp_ranges) tb_a_ranges(a_range)
          ) tb_a_range    
    )
    ;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;



-- drop function if exists sm_sc.fv_sample_x(anyarray, int, int, int4range[]);
create or replace function sm_sc.fv_sample_x   -- 2 至 4 个参数
(
  i_array          anyarray          ,
  i_period         int               ,                                 -- 采样周期
  i_window_len     int           default null   ,                      -- 1d 采样窗口的长度或 2d 采样的窗口宽度。 null 值表示不约束窗口宽度
  i_simp_ranges    int4range[]   default array[int4range(1, 1, '[]')]  -- 越界填充，类似于升采样，周期纵向插入 i_fill_values 元素稀释原矩阵
                                                                       -- 如果下界小于窗口左边界，则每组样本左侧填充 i_fill_values; 如果上界也小于窗口左边界，那么该 sim_range 和窗口无交集，抽样将全部是填充元素
                                                                       -- 如果上界大于窗口右边界，那么右侧填充 i_fill_values; 如果下界也大于窗口右边界，那么该 sim_range 和窗口无交集，抽样将全部是填充元素
                                                                       -- 其中超出上下界的数值代表 i_fill_values 重复填充次数，例如 -1 代表左侧重复填充 1 - (-1) = 2 次
)
returns anyarray
as
$$
declare 
  v_fill_values    i_array%type;
begin
  if array_ndims(i_array) = 2
  then
    v_fill_values := i_array[1 : 1][1 : 1];
    v_fill_values[1][1] := null;
  elsif array_ndims(i_array) = 1
  then 
    v_fill_values := i_array[1 : 1];
    v_fill_values[1] := null;
  end if;

  return sm_sc.fv_sample_x(i_array, i_period, i_window_len, i_simp_ranges, v_fill_values);

end
$$
language plpgsql stable
parallel safe
cost 100;







-- -- set search_path to sm_sc;
-- select sm_sc.fv_sample_x
--   (
--     array[array[1, 2, 3, 4, 5, 6], array[7, 8, 9, 10, 11, 12]]
--     , 3
--     , 2
--     , array[int4range(1,2, '[]'), int4range(2,4, '[]')]
--   );
-- select sm_sc.fv_sample_x
--   (
--     array[array[1, 2, 3, 4, 5, 6], array[7, 8, 9, 10, 11, 12]]
--     , 3
--     , 5
--     , array[int4range(1,2, '[]'), int4range(2,4, '[]')]
--   );
-- select sm_sc.fv_sample_x
--   (
--     array[array[1, 2, 3, 4, 5, 6], array[7, 8, 9, 10, 11, 12]]
--     , 3
--     , null
--     , array[int4range(1,2, '[]'), int4range(2,4, '[]')]
--   );
-- select sm_sc.fv_sample_x
--   (
--     array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
--     , 3
--     , null :: int
--     , array[int4range(1,2, '[]'), int4range(2,4, '[]')]
--   );
-- select sm_sc.fv_sample_x
--   (
--     array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
--     , 3
--   );

-- select sm_sc.fv_sample_x
--   (
--     array[array[1, 2, 3, 4.6, 5, 6], array[7, 8, 9, 10, 11, 12]]
--     , 3
--     , 3
--     , array[int4range(-1,2, '[]'), int4range(-2,0, '[]'), int4range(3,5, '[]'), int4range(4,5, '[]')]
--     , array[array[21, 22], array[23, 24]] :: float[]
--   );