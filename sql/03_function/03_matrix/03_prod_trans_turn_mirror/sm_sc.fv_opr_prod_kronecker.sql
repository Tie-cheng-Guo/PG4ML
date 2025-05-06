-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_kronecker(anyarray, anyarray);
create or replace function sm_sc.fv_opr_prod_kronecker
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
-- declare -- here
begin
  -- set search_path to sm_sc;
  if array_ndims(i_left) <> 2 or array_ndims(i_right) <> 2
  then
    raise exception 'unsupport ndims!';
  elsif array_ndims(i_left) = 2 and array_ndims(i_right) = 2
  then    
    return 
    (
      with 
      cte_y_grp as
      (
        select 
          a_cur_left_y,
          sm_sc.fa_mx_concat_x(i_left[a_cur_left_y][a_cur_left_x] *` i_right order by a_cur_left_x) as a_y_ele_grp
        from generate_series(1, array_length(i_left, 1)) tb_a_cur_left_y(a_cur_left_y)
          , generate_series(1, array_length(i_left, 2)) tb_a_cur_left_x(a_cur_left_x)
        group by a_cur_left_y
      )
      select 
        sm_sc.fa_mx_concat_y(a_y_ele_grp order by a_cur_left_y)
      from cte_y_grp
    )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_prod_kronecker
--   (
--     array[array[1.0 :: float, -2.0], array[-3.0, 4.0]],
--     array[array[1.0 :: float, -2.0 :: float, 3.0], array[-4.0, 5.0, 6.0], array[7.0, 8.0, -9.0]]
--   );
-- select sm_sc.fv_opr_prod_kronecker
--   (
--     array[array[1.0 :: float, -2.0 :: float, 3.0], array[-4.0, 5.0, 6.0], array[7.0, 8.0, -9.0]],
--     array[array[1.0 :: float, -2.0], array[-3.0, 4.0]]
--   );
-- select sm_sc.fv_opr_prod_kronecker
--   (
--     array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]],
--     array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]]
--   );
-- select sm_sc.fv_opr_prod_kronecker
--   (
--     array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex, (2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex],
--     array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex, (2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]
--   );