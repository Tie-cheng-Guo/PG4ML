-- set search_path to sm_sc;
-- boolean
-- drop function if exists sm_sc.fv_aggr_y_and(boolean[]);
create or replace function sm_sc.fv_aggr_y_and
(
  i_array          boolean[]
)
returns boolean[]
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2
  then
    return 
    (
      select 
        array[array_agg(sm_sc.fv_aggr_slice_and(i_array[ : ][col_a_x : col_a_x]) order by col_a_x)]
      from generate_series(1, array_length(i_array, 2)) tb_a_x(col_a_x)
    );
  else
    raise exception 'no method fand such length!';
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_y_and
--   (
--     array[array[true, false, false]
--         , array[true, false, false]
--         , array[true, false, true]
--         , array[false, true, true]
--         , array[false, false, true]
--         , array[true, true, true]
--          ]
--   );

-- ---------------------------------------------------------------------------------------------------------------------------------

-- set search_path to sm_sc;
-- bit
-- drop function if exists sm_sc.fv_aggr_y_and(bit[]);
create or replace function sm_sc.fv_aggr_y_and
(
  i_array          bit[]
)
returns bit[]
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2
  then
    return 
    (
      select 
        array[array_agg(sm_sc.fv_aggr_slice_and(i_array[ : ][col_a_x : col_a_x]) order by col_a_x)]
      from generate_series(1, array_length(i_array, 2)) tb_a_x(col_a_x)
    );
  else
    raise exception 'no method fand such length!';
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_y_and
--   (
--     array[array[B'10101', B'101', B'1101']
--         , array[B'10101', B'101', B'1101']
--         , array[B'10001', B'001', B'1101']
--         , array[B'10101', B'101', B'1101']
--         , array[B'10101', B'101', B'1001']
--         , array[B'10001', B'101', B'1001']
--          ]
--   );