-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_norm(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_norm
(
  i_right    sm_sc.typ_l_complex
)
returns float
as
$$
-- declare 
begin
  return sqrt(i_right.m_re ^ 2 + i_right.m_im ^ 2);
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_norm
--   (
--     (-45.6, -45.6)
--   );
-- select sm_sc.fv_opr_norm
--   (
--     100.0
--   );

-- drop function if exists sm_sc.fv_opr_norm(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_norm
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
  v_ret     float[]   := case array_ndims(i_right) when 2 then array_fill(null :: float, array[array_length(i_right, 1), array_length(i_right, 2)]) when 1 then array_fill(null :: float, array[array_length(i_right, 1)]) else null end;

begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- norm([][])
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        v_ret[v_y_cur][v_x_cur] := sm_sc.fv_opr_norm(i_right[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- abs []
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      v_ret[v_y_cur] := sm_sc.fv_opr_norm(i_right[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return v_ret;

  -- abs [][][]
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            sm_sc.fv_opr_norm(i_right[v_y_cur][v_x_cur][v_x3_cur])
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- abs [][][][]
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
              sm_sc.fv_opr_norm(i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
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

-- select 
--   sm_sc.fv_opr_norm
--   (
--     -` array[[row(32.5, -1.5) :: sm_sc.typ_l_complex, row(1.26, -1.5) :: sm_sc.typ_l_complex, row(33.6, -1.5) :: sm_sc.typ_l_complex]
--            , [row(-9.1, -1.5) :: sm_sc.typ_l_complex, row(8.6, -1.5) :: sm_sc.typ_l_complex, row(4.69, -1.5) :: sm_sc.typ_l_complex]]
--   )