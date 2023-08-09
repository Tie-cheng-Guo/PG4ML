-- set search_path to sm_sc;
-- -- 仅支持 2d, 1d
-- drop function if exists sm_sc.fv_aggr_slice_median(anyarray);
create or replace function sm_sc.fv_aggr_slice_median
(
  i_array          anyarray
)
returns anyelement
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2
  then
    -- -- return (select mode(col_a) from unnest(i_array[i_begin_pos[1] : i_end_pos[1]][i_begin_pos[2] : i_end_pos[2]]) tb_a(col_a));

    -- -- return 
    -- -- (
    -- --   select 
    -- --     ( percentile_disc(0.5 :: float) within group ( order by i_array[col_a_y][col_a_x] ) 
    -- --       + percentile_disc(0.5 :: float) within group ( order by i_array[col_a_y][col_a_x] desc )
    -- --     ) / 2
    -- --   from generate_series(1,  array_length(i_array, 1)) tb_a_y(a_y)
    -- --     , generate_series(1,  array_length(i_array, 2)) tb_a_x(a_x)
    -- -- );

    return 
    (
      with 
      cte_ord_no as
      (
        select 
          row_number() over (order by i_array[a_y][a_x]) as a_ord_no,
          a_y, 
          a_x
        from generate_series(1,  array_length(i_array, 1)) tb_a_y(a_y)
          , generate_series(1,  array_length(i_array, 2)) tb_a_x(a_x)
      )
      select avg(i_array[a_y][a_x]) 
      from cte_ord_no 
      where a_ord_no in (floor((array_length(i_array, 1) * array_length(i_array, 2) + 1.0 :: float) / 2.0 :: float)
                           , ceil((array_length(i_array, 1) * array_length(i_array, 2) + 1.0 :: float) / 2.0 :: float)
                          )
    );

  elsif array_ndims(i_array) = 1
  then

    return 
    (
      with 
      cte_ord_no as
      (
        select 
          row_number() over (order by i_array[a_y]) as a_ord_no,
          a_y
        from generate_series(1,  array_length(i_array, 1)) tb_a_y(a_y)
      )
      select avg(i_array[a_y]) 
      from cte_ord_no 
      where a_ord_no in (floor((array_length(i_array, 1) + 1.0 :: float) / 2.0 :: float)
                           , ceil((array_length(i_array, 1) + 1.0 :: float) / 2.0 :: float)
                          )
    );

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_median
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]
--   );

-- select sm_sc.fv_aggr_slice_median
--   (
--     array[10,20,30,40,50,60]
--   );

