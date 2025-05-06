-- drop function if exists sm_sc.fv_opr_conjugate_45(sm_sc.typ_l_complex[]);
create or replace function sm_sc.fv_opr_conjugate_45
(
  i_right     sm_sc.typ_l_complex[]
)
returns sm_sc.typ_l_complex[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- sm_sc.fv_opr_conjugate_45([][])
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := sm_sc.fv_opr_conjugate_45(i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- sm_sc.fv_opr_conjugate_45 []
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := sm_sc.fv_opr_conjugate_45(i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- sm_sc.fv_opr_conjugate_45 [][][]
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            sm_sc.fv_opr_conjugate_45(i_right[v_y_cur][v_x_cur][v_x3_cur]) 
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- sm_sc.fv_opr_conjugate_45 [][][][]
  elsif array_ndims(i_right) = 4
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_right, 4)
          loop
            i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              sm_sc.fv_opr_conjugate_45(i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_conjugate_45(array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_conjugate_45(array[12.3, 25.1, 28.33])
-- select sm_sc.fv_opr_conjugate_45(array[array[(12.3, 10.6)::sm_sc.typ_l_complex, (-25.1, 5.6)::sm_sc.typ_l_complex], array[(-2.56, 4.1)::sm_sc.typ_l_complex, (3.25, 5.2)::sm_sc.typ_l_complex]])
-- select sm_sc.fv_opr_conjugate_45(array[(12.3, 5.1)::sm_sc.typ_l_complex, (-25.1, 7.8)::sm_sc.typ_l_complex, (28.33, 1.9)::sm_sc.typ_l_complex])
-- select sm_sc.fv_opr_conjugate_45(array[]::float[])
-- select sm_sc.fv_opr_conjugate_45(array[array[], array []]::float[])
-- select 
--   sm_sc.fv_opr_conjugate_45
--   (
--     array[[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]],[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]]] :: sm_sc.typ_l_complex[]
--   )
-- select 
--   sm_sc.fv_opr_conjugate_45
--   (
--     array[[[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]],[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]]],[[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]],[[(12.3, -25.1), (-2.56, 3.25)],[(12.3, -25.1), (-2.56, 3.25)]]]] :: sm_sc.typ_l_complex[]
--   )