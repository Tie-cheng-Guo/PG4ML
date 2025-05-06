-- -- 逻辑运算
-- drop function if exists sm_sc.fv_opr_not(boolean[]);
create or replace function sm_sc.fv_opr_not
(
  i_right     boolean[]
)
returns boolean[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- not (null :: boolean[][], boolean) = null :: boolean[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- not ([][])
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := (not (i_right[v_y_cur][v_x_cur]));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- not ([])
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := (not (i_right[v_y_cur]));
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
    
  -- not ([][][])
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            (not(i_right[v_y_cur][v_x_cur][v_x3_cur]))
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- not ([][][][])
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
              (not(i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]))
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
-- select sm_sc.fv_opr_not(array[[true, false], [false, true]])
-- select sm_sc.fv_opr_not(array[true, false, false, true])
-- select sm_sc.fv_opr_not(array[]::boolean[])
-- select sm_sc.fv_opr_not(array[[], []]::boolean[])
-- select sm_sc.fv_opr_not(array[[[true, false],[false, true]],[[true, false],[false, true]]])
-- select sm_sc.fv_opr_not(array[[[[true, false],[false, true]],[[true, false],[false, true]]],[[[true, false],[false, true]],[[true, false],[false, true]]]])

-- -------------------------------------------------------------------------------------------

-- -- 位运算
-- drop function if exists sm_sc.fv_opr_not(varbit[]);
create or replace function sm_sc.fv_opr_not
(
  i_right     varbit[]
)
returns varbit[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- ~(null :: varbit[][], varbit) = null :: varbit[][]
  if array_length(i_right, array_ndims(i_right)) is null
  then 
    return i_right;
  end if;

  -- ~([][], varbit)
  if array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := (~ (i_right[v_y_cur][v_x_cur]));
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- ~([])
  elsif array_ndims(i_right) = 1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := (~ (i_right[v_y_cur]));
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
    
  -- ~ ([][][])
  elsif array_ndims(i_right) = 3
  then
    for v_y_cur in 1 .. array_length(i_right, 1)
    loop
      for v_x_cur in 1 .. array_length(i_right, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_right, 3)
        loop
          i_right[v_y_cur][v_x_cur][v_x3_cur] = 
            ~ (i_right[v_y_cur][v_x_cur][v_x3_cur]) 
          ;
        end loop;    
      end loop;
    end loop;
    return i_right;
    
  -- ~ ([][][][])
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
              ~ (i_right[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]) 
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
-- select sm_sc.fv_opr_not(array[[B'101', B'010'], [B'100', B'001']])
-- select sm_sc.fv_opr_not(array[B'101', B'010', B'100', B'001'])
-- select sm_sc.fv_opr_not(array[]::varbit[])
-- select sm_sc.fv_opr_not(array[[],  []]::varbit[])
-- select sm_sc.fv_opr_not(array[[[B'101', B'010'], [B'100', B'001']],[[B'101', B'010'], [B'100', B'001']]])
-- select sm_sc.fv_opr_not(array[[[[B'101', B'010'], [B'100', B'001']],[[B'101', B'010'], [B'100', B'001']]],[[[B'101', B'010'], [B'100', B'001']],[[B'101', B'010'], [B'100', B'001']]]])