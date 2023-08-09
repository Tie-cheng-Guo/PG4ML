-- drop function if exists sm_sc.fv_opr_imaginary(sm_sc.typ_l_complex[]);
create or replace function sm_sc.fv_opr_imaginary
(
  i_right     sm_sc.typ_l_complex[]
)
returns float[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_ret     float[]   := case array_ndims(i_right) when 2 then array_fill(null::float, array[array_length(i_right, 1), array_length(i_right, 2)]) when 1 then array_fill(null::float, array[array_length(i_right, 1)]) else null::float[] end;

begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- sm_sc.fv_opr_imaginary([][])
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sm_sc.fv_opr_imaginary(i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- sm_sc.fv_opr_imaginary ([])
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := sm_sc.fv_opr_imaginary(i_right[v_y_cur]);
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
-- select sm_sc.fv_opr_imaginary(array[array[(12.3, 10.6)::sm_sc.typ_l_complex, (-25.1, 5.6)::sm_sc.typ_l_complex], array[(-2.56, 4.1)::sm_sc.typ_l_complex, (3.25, 5.2)::sm_sc.typ_l_complex]])
-- select sm_sc.fv_opr_imaginary(array[(12.3, 5.1)::sm_sc.typ_l_complex, (-25.1, 7.8)::sm_sc.typ_l_complex, (28.33, 1.9)::sm_sc.typ_l_complex])
-- select sm_sc.fv_opr_imaginary(array[]::float[])
-- select sm_sc.fv_opr_imaginary(array[array[], array []]::float[])