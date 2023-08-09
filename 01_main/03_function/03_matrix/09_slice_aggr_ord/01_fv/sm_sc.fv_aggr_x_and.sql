-- set search_path to sm_sc;
-- boolean
-- drop function if exists sm_sc.fv_aggr_x_and(boolean[]);
create or replace function sm_sc.fv_aggr_x_and
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
        array_agg(array[sm_sc.fv_aggr_slice_and(i_array[col_a_y : col_a_y][ : ])] order by col_a_y)
      from generate_series(1, array_length(i_array, 1)) tb_a_y(col_a_y)
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
-- select sm_sc.fv_aggr_x_and
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
-- drop function if exists sm_sc.fv_aggr_x_and(bit[], int[], int[]);
create or replace function sm_sc.fv_aggr_x_and
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
        array_agg(array[sm_sc.fv_aggr_slice_and(i_array[col_a_y : col_a_y][ : ])] order by col_a_y)
      from generate_series(1, array_length(i_array, 1)) tb_a_y(col_a_y)
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
-- select sm_sc.fv_aggr_x_and
--   (
--     array[array[B'10101', B'10101', B'10101']
--         , array[B'101', B'101', B'110']
--         , array[B'1101', B'1001', B'1101']
--          ]
--   );