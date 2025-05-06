-- drop function if exists sm_sc.fv_opr_real(sm_sc.typ_l_complex[]);
create or replace function sm_sc.fv_opr_real
(
  i_right     sm_sc.typ_l_complex[]
)
returns float[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_ret     float[]    ;

begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- sm_sc.fv_opr_real([][])
  if array_ndims(i_right) =  2
  then
    v_ret := array_fill(null::float, array[array_length(i_right, 1), array_length(i_right, 2)]);
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sm_sc.fv_opr_real(i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- sm_sc.fv_opr_real ([])
  elsif array_ndims(i_right) = 1
  then
    v_ret := array_fill(null::float, array[array_length(i_right, 1)]);
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := sm_sc.fv_opr_real(i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- sm_sc.fv_opr_real([][][])
  elsif array_ndims(i_right) = 3
  then
    v_ret := array_fill(null::float, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3)]);
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          v_ret[v_y_cur][v_x_cur][v_x3_cur] = 
            sm_sc.fv_opr_real(i_right[v_y_cur][v_x_cur][v_x3_cur]) 
          ;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  -- sm_sc.fv_opr_real([][][][])
  elsif array_ndims(i_right) = 4
  then
    v_ret := array_fill(null::float, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 3), array_length(i_right, 4)]);
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            v_ret[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              sm_sc.fv_opr_real(i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return v_ret;
    
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_real(array[array[(12.3, 10.6)::sm_sc.typ_l_complex, (-25.1, 5.6)::sm_sc.typ_l_complex], array[(-2.56, 4.1)::sm_sc.typ_l_complex, (3.25, 5.2)::sm_sc.typ_l_complex]])
-- select sm_sc.fv_opr_real(array[(12.3, 5.1)::sm_sc.typ_l_complex, (-25.1, 7.8)::sm_sc.typ_l_complex, (28.33, 1.9)::sm_sc.typ_l_complex])
-- select sm_sc.fv_opr_real(array[]::float[])
-- select sm_sc.fv_opr_real(array[array[], array []]::float[])
-- select 
--   sm_sc.fv_opr_real
--   (
--     array[[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]],[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]]] :: sm_sc.typ_l_complex[]
--   )
-- select 
--   sm_sc.fv_opr_real
--   (
--     array[[[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]],[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]]],[[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]],[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]]]] :: sm_sc.typ_l_complex[]
--   )