-- drop function if exists sm_sc.fv_opr_conjugate_i(sm_sc.typ_l_complex[2]);
create or replace function sm_sc.fv_opr_conjugate_i
(
  i_right     sm_sc.typ_l_complex[2]
)
returns sm_sc.typ_l_complex[2]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     sm_sc.typ_l_complex[]   := case array_ndims(i_right) when 2 then array_fill(null::sm_sc.typ_l_complex, array[array_length(i_right, 2), array_length(i_right, 1)]) else null::sm_sc.typ_l_complex[] end;

begin
  -- log(null :: sm_sc.typ_l_complex[][], sm_sc.typ_l_complex) = null :: sm_sc.typ_l_complex[][]
  if array_length(i_right, 1) is null
  then 
    return i_right;
  end if;

  -- ~([][])
  if array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_x_cur][v_y_cur] := ~ i_right[v_y_cur][v_x_cur];
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_conjugate_i(array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex])
-- select sm_sc.fv_opr_conjugate_i(array[array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex], array[(12.3, 0.0 :: float)::sm_sc.typ_l_complex, (0.0 :: float, 3.25)::sm_sc.typ_l_complex]])
-- select sm_sc.fv_opr_conjugate_i(array[]::sm_sc.typ_l_complex[])
-- select sm_sc.fv_opr_conjugate_i(array[array[], array []]::sm_sc.typ_l_complex[])