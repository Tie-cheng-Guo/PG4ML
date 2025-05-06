-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_inner(anyarray, anyarray);
create or replace function sm_sc.fv_opr_prod_inner
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyelement
as
$$
declare -- here
  -- v_x_cur   int  := 1  ;
  -- v_y_cur   int  := 1  ;
  -- v_return  alias for $0;
begin
  -- set search_path to sm_sc;
  if array_ndims(i_left) = 2 and array_ndims(i_right) = 2 and (array_length(i_left, 1) <> array_length(i_right, 1) or array_length(i_left, 2) <> array_length(i_right, 2))
    or array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) <> array_length(i_right, 1)
  then
    raise exception 'unmatched length!';
  end if;
  
  return |@+| (i_left *` i_right);

  -- -- if array_ndims(i_left) = 1 and array_ndims(i_right) = 1
  -- -- then
  -- --   v_return := i_left[1] - i_left[1];
  -- --   while v_y_cur <= array_length(i_right, 1)
  -- --   loop
  -- --     v_return := v_return + (i_left[v_y_cur] * i_right[v_y_cur]);
  -- --     v_y_cur := v_y_cur + 1;
  -- --   end loop;
  -- --   
  -- --   return v_return;
  -- -- elsif array_ndims(i_left) = 2 and array_ndims(i_right) = 2
  -- -- then
  -- --   v_return := i_left[1][1] - i_left[1][1];
  -- --   while v_y_cur <= array_length(i_right, 1)
  -- --   loop 
  -- --     v_x_cur := 1  ;
  -- --     while v_x_cur <= array_length(i_right, 2)
  -- --     loop
  -- --       v_return := v_return + (i_left[v_y_cur][v_x_cur] * i_right[v_y_cur][v_x_cur]);
  -- --       v_x_cur := v_x_cur + 1;
  -- --     end loop;
  -- --     v_y_cur := v_y_cur + 1;
  -- --   end loop;
  -- --   
  -- --   return v_return;
  -- -- else
  -- --   raise exception 'no method for such length!  L_Dim: %; R_Dim: %;', array_dims(i_left), array_dims(i_right);
  -- -- end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_prod_inner
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_prod_inner
--   (
--     array[12.3, -12.3, 45.6, -45.6],
--     array[-12.3, 12.3, -45.6, 45.6]
--   );
-- select sm_sc.fv_opr_prod_inner
--   (
--     array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]],
--     array[array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex], array[(2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]]
--   );
-- select sm_sc.fv_opr_prod_inner
--   (
--     array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex, (2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex],
--     array[(1.2, 1.6)::sm_sc.typ_l_complex, (1.3, 1.9)::sm_sc.typ_l_complex, (2.3, -2.1)::sm_sc.typ_l_complex, (2.5, -2.6)::sm_sc.typ_l_complex]
--   );