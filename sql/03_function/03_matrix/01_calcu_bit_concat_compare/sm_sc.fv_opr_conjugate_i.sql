-- drop function if exists sm_sc.fv_opr_conjugate_i(sm_sc.typ_l_complex[][]);
create or replace function sm_sc.fv_opr_conjugate_i
(
  i_right     sm_sc.typ_l_complex[][]
)
returns sm_sc.typ_l_complex[][]
as
$$
declare -- here
  v_y_cur   int  := 1  ;
  v_x_cur   int  := 1  ;
  v_x3_cur  int  := 1  ;
  v_x4_cur  int  := 1  ;
  v_ret     sm_sc.typ_l_complex[][]   
    := case array_ndims(i_right) 
         when 2 then array_fill(null::sm_sc.typ_l_complex, array[array_length(i_right, 2), array_length(i_right, 1)]) 
         when 3 then array_fill(null::sm_sc.typ_l_complex, array[array_length(i_right, 1), array_length(i_right, 3), array_length(i_right, 2)]) 
         when 4 then array_fill(null::sm_sc.typ_l_complex, array[array_length(i_right, 1), array_length(i_right, 2), array_length(i_right, 4), array_length(i_right, 3)]) 
         else null::sm_sc.typ_l_complex[] 
       end;

begin
  -- log(null :: sm_sc.typ_l_complex[][], sm_sc.typ_l_complex) = null :: sm_sc.typ_l_complex[][]
  if array_length(i_right, 1) is null
  then 
    return i_right;
  end if;

  -- ~([][])
  if array_ndims(i_right) = 2
  then    
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop 
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop 
        v_ret[v_x_cur][v_y_cur] := ~ i_right[v_y_cur][v_x_cur];
      end loop;
    end loop;
    return v_ret;
  -- ~([][][])
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop 
      for v_x3_cur in 1 .. array_length(i_right, 3)
      loop 
        for v_x_cur in 1 .. array_length(i_right, 2)
        loop 
          v_ret[v_y_cur][v_x3_cur][v_x_cur] := ~ i_right[v_y_cur][v_x_cur][v_x3_cur];
        end loop;
      end loop;
    end loop;
    return v_ret;
  -- ~([][][][])
  elsif array_ndims(i_right) = 4
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop 
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop 
        for v_x4_cur in 1 .. array_length(i_right, 4)
        loop 
          for v_x3_cur in 1 .. array_length(i_right, 3)
          loop 
            v_ret[v_y_cur][v_x_cur][v_x4_cur][v_x3_cur] := ~ i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur];
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
-- select sm_sc.fv_opr_conjugate_i(array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex])
-- select sm_sc.fv_opr_conjugate_i(array[array[(12.3, -25.1), (-2.56, 3.25)], array[(12.3, 0.0 :: float), (0.0 :: float, 3.25)]] :: sm_sc.typ_l_complex[])
-- select sm_sc.fv_opr_conjugate_i(array[]::sm_sc.typ_l_complex[])
-- select sm_sc.fv_opr_conjugate_i(array[array[], array []]::sm_sc.typ_l_complex[])