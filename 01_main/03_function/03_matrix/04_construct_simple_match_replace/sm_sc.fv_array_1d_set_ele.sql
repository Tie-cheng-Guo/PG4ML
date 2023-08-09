-- drop function if exists sm_sc.fv_array_1d_set_ele(anyarray, int, anyelement);
create or replace function sm_sc.fv_array_1d_set_ele
(
  i_array    anyarray,
  i_pos      int,    -- 可以为负值，由尾部向前追溯位置
  i_element  anyelement
)
returns anyarray
as
$$
-- declare
begin
  if i_pos between 1 and array_length(i_array, 1)
  then
    return i_array[: i_pos - 1] || i_element || i_array[i_pos + 1 : ];
  elsif i_pos between -array_length(i_array, 1) and -1 
  then
    return i_array[: array_length(i_array, 1) + i_pos] || i_element || i_array[array_length(i_array, 1) + i_pos + 2 : ];
  else
    return i_array;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 2, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -2, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 1, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 4, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -1, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -4, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 0, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 5, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -5, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 6, 5)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -6, 5)

-- ------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_array_1d_set_ele(anyarray, int, anyarray);
create or replace function sm_sc.fv_array_1d_set_ele
(
  i_array    anyarray,
  i_pos      int,    -- 可以为负值，由尾部向前追溯位置
  i_elements anyarray
)
returns anyarray
as
$$
-- declare
begin
  if i_pos between 1 and array_length(i_array, 1)
  then
    return i_array[: i_pos - 1] || i_elements || i_array[i_pos + 1 : ];
  elsif i_pos between -array_length(i_array, 1) and -1 
  then
    return i_array[: array_length(i_array, 1) + i_pos] || i_elements || i_array[array_length(i_array, 1) + i_pos + 2 : ];
  else
    return i_array;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 2, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -2, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 1, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 4, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -1, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -4, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 0, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 5, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -5, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], 6, array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], -6, array[5,6,7])

-- ------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_array_1d_set_ele(anyarray, int[], anyarray);
create or replace function sm_sc.fv_array_1d_set_ele
(
  i_array             anyarray  ,
  i_pos_range         int4range ,    -- 可以为负值，由尾部向前追溯位置；约束不可以上下边界同号或为0
  i_elements          anyarray
)
returns anyarray
as
$$
-- declare
begin
  if lower(i_pos_range) < 0 and upper(i_pos_range) - 1 > 0
  then
    raise 'Unsupport!';
  elsif i_pos_range && int4range(1, array_length(i_array, 1), '[]')
  then
    return i_array[: coalesce(lower(i_pos_range), 1) - 1] || i_elements || i_array[coalesce(upper(i_pos_range), 1) : ];
  elsif i_pos_range && int4range(-array_length(i_array, 1), -1, '[]')
  then
    return i_array[: array_length(i_array, 1) + coalesce(lower(i_pos_range), 1)] || i_elements || i_array[array_length(i_array, 1) + coalesce(upper(i_pos_range), 1) + 1 : ];
  else
    return i_array;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[2, 3]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-3, -2] '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[1, 2]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[3, 4]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-2, -1] '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-4, -3] '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-2, 0]  '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[0, 2]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[4, 6]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[5, 6]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[6, 7]   '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-6, -4] '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-6, -5] '::int4range , array[5,6,7])
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-7, -6] '::int4range , array[5,6,7])

-- ------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_array_1d_set_ele(anyarray, int[], anyelement);
create or replace function sm_sc.fv_array_1d_set_ele
(
  i_array             anyarray  ,
  i_pos_range         int4range ,    -- 可以为负值，由尾部向前追溯位置；约束不可以上下边界同号或为0
  i_element           anyelement
)
returns anyarray
as
$$
-- declare
begin
  return sm_sc.fv_array_1d_set_ele(i_array, i_pos_range, array[i_element]);
end
$$
language plpgsql stable
parallel safe
cost 100;

-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[2, 3]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-3, -2] '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[1, 2]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[3, 4]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-2, -1] '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-4, -3] '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-2, 0]  '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[0, 2]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[4, 6]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[5, 6]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[6, 7]   '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-6, -4] '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-6, -5] '::int4range , 6)
-- select sm_sc.fv_array_1d_set_ele(array[1,2,3,4], '[-7, -6] '::int4range , 6)