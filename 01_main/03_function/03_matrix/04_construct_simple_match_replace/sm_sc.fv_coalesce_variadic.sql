

-- drop function if exists sm_sc.fv_coalesce_variadic(variadic anyarray);
create or replace function sm_sc.fv_coalesce_variadic
(
  variadic i_array  anyarray
)
  returns anyarray
as
$$
-- declare here

begin
  if array_ndims(i_array) = 2
  then
    return 
    (
      with 
      cte_y as
      (
        select 
          a_y,
          sm_sc.fa_coalesce(i_array[a_variadic][a_y] order by a_variadic) as a_y_ele
        from generate_series(1, array_length(i_array, 1)) tb_a_variadic(a_variadic)
          , generate_series(1, array_length(i_array, 2)) tb_a_y(a_y)
        group by a_y
      )
      select 
        array_agg(a_y_ele order by a_y) 
      from cte_y
    );
  elsif array_ndims(i_array) = 3
  then
    return
    (
      with 
      cte_yx as
      (
        select 
          a_y,
          a_x,
          sm_sc.fa_coalesce(i_array[a_variadic][a_y][a_x] order by a_variadic) as a_yx_ele
        from generate_series(1, array_length(i_array, 1)) tb_a_variadic(a_variadic)
          , generate_series(1, array_length(i_array, 2)) tb_a_y(a_y)
          , generate_series(1, array_length(i_array, 3)) tb_a_x(a_x)
        group by a_y, a_x
      ),
      cte_x as
      (
        select 
          a_y,
          array_agg(a_yx_ele order by a_x) as a_x_ele
        from cte_yx
        group by a_y
      )
      select 
        array_agg(a_x_ele order by a_y) 
      from cte_x
    );
  else
    raise exception 'unsurpport ndim!';
  end if; 
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- -- select sm_sc.fv_coalesce_variadic(1.2, 2.3, 5.6, 52.1)
-- select sm_sc.fv_coalesce_variadic(variadic array[array[null, 2.4, 5.6, 52.3], array[1.2, 2.3, null, 52.1]])
-- select sm_sc.fv_coalesce_variadic(variadic array[array[array[null, 2.4, 5.6, null], array[1.2, 2.3, null, 25.6]], array[array[1, 2, null, 4], array[5, 6, 7, 8]]])
