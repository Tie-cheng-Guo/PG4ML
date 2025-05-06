-- drop function if exists sm_sc.fv_opr_ceil(anyarray, int);
create or replace function sm_sc.fv_opr_ceil
(
  i_left         anyarray,
  i_num_digits    int
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
  v_balan   decimal  := 5.0 * power(0.1, i_num_digits + 1) :: decimal  ;
begin
  -- ceil(null :: anyarray, int) = null :: anyarray
  if array_length(i_left, array_ndims(i_left)) is null
  then 
    return i_left;
  end if;

  -- ceil([][])
  if array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        -- -- i_left[v_y_cur][v_x_cur] := 
        -- --   case 
        -- --     when i_left[v_y_cur][v_x_cur] = round(i_left[v_y_cur][v_x_cur], i_num_digits) 
        -- --       then i_left[v_y_cur][v_x_cur]
        -- --     else round(i_left[v_y_cur][v_x_cur] + v_balan, i_num_digits) 
        -- --   end;
        if i_left[v_y_cur][v_x_cur] <> round(i_left[v_y_cur][v_x_cur], i_num_digits)
        then 
          i_left[v_y_cur][v_x_cur] := round(i_left[v_y_cur][v_x_cur] + v_balan, i_num_digits);
        end if;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- ceil []
  elsif array_ndims(i_left) = 1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      -- -- i_left[v_y_cur] := 
      -- --   case 
      -- --     when i_left[v_y_cur] = round(i_left[v_y_cur], i_num_digits) 
      -- --       then i_left[v_y_cur]
      -- --     else round(i_left[v_y_cur] + v_balan, i_num_digits) 
      -- --   end;
      if i_left[v_y_cur] <> round(i_left[v_y_cur], i_num_digits)
      then 
        i_left[v_y_cur] := round(i_left[v_y_cur] + v_balan, i_num_digits);
      end if;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
    
  -- ceil [][][]
  elsif array_ndims(i_left) = 3
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          -- -- i_left[v_y_cur][v_x_cur][v_x3_cur] := 
          -- --   case 
          -- --     when i_left[v_y_cur][v_x_cur][v_x3_cur] = round(i_left[v_y_cur][v_x_cur][v_x3_cur], i_num_digits) 
          -- --       then i_left[v_y_cur][v_x_cur][v_x3_cur]
          -- --     else round(i_left[v_y_cur][v_x_cur][v_x3_cur] + v_balan, i_num_digits) 
          -- --   end;
          if i_left[v_y_cur][v_x_cur][v_x3_cur] <> round(i_left[v_y_cur][v_x_cur][v_x3_cur], i_num_digits)
          then 
            i_left[v_y_cur][v_x_cur][v_x3_cur] := round(i_left[v_y_cur][v_x_cur][v_x3_cur] + v_balan, i_num_digits);
          end if;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- ceil [][][][]
  elsif array_ndims(i_left) = 4
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_left, 4)
          loop
            -- -- i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] := 
            -- --   case 
            -- --     when i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = round(i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_num_digits) 
            -- --       then i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur]
            -- --     else round(i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] + v_balan, i_num_digits) 
            -- --   end;
            if i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] <> round(i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur], i_num_digits)
            then 
              i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] := round(i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] + v_balan, i_num_digits);
            end if;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_left;

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_ceil(array[array[-12.34584, 25.143540], array[2.560454, -3.2504870]], 2)
-- select sm_sc.fv_opr_ceil(array[-12.304725, 25.1874, -28.33407], 0)
-- select sm_sc.fv_opr_ceil(array[0, 1.00003, -2.00005, 0.99993, -1.999995, 1.01, -1.01], 2)
-- select sm_sc.fv_opr_ceil(array[]::decimal[])
-- select sm_sc.fv_opr_ceil(array[array[], array []]::decimal[])
-- select sm_sc.fv_opr_ceil(array[[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]],[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]]]::decimal[], 2)
-- select sm_sc.fv_opr_ceil(array[[[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]],[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]]],[[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]],[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]]]]::decimal[], 1)

-- ---------------------------------------------------------------------------
-- -- 以下单入参函数是必要的，无法用设置默认值的双入参代替，且一定不能用后者（两者对单入参调用冲突），后者无法支持单目运算符
-- drop function if exists sm_sc.fv_opr_ceil(anyarray);
create or replace function sm_sc.fv_opr_ceil
(
  i_left     anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
  v_x3_cur      int  := 1  ;
  v_x4_cur      int  := 1  ;
begin
  -- ceil(null :: anyarray) = null :: anyarray
  if array_length(i_left, array_ndims(i_left)) is null
  then 
    return i_left;
  end if;

  -- ceil([][])
  if array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := ceil(i_left[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- ceil []
  elsif array_ndims(i_left) = 1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := ceil(i_left[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- ceil [][][]
  elsif array_ndims(i_left) = 3
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          i_left[v_y_cur][v_x_cur][v_x3_cur] = 
            ceil(i_left[v_y_cur][v_x_cur][v_x3_cur])
          ;
        end loop;    
      end loop;
    end loop;
    return i_left;
    
  -- ceil [][][][]
  elsif array_ndims(i_left) = 4
  then
    for v_y_cur in 1 .. array_length(i_left, 1)
    loop
      for v_x_cur in 1 .. array_length(i_left, 2)
      loop
        for v_x3_cur in 1 .. array_length(i_left, 3)
        loop
          for v_x4_cur in 1 .. array_length(i_left, 4)
          loop
            i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur] = 
              ceil(i_left[v_y_cur][v_x_cur][v_x3_cur][v_x4_cur])
            ;
          end loop;
        end loop;    
      end loop;
    end loop;
    return i_left;

  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_left);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_ceil(array[array[12.35450, -25.1507], array[-2.56405, 3.2544444446]])
-- select sm_sc.fv_opr_ceil(array[12.3101, -25.711, 28.33920])
-- select sm_sc.fv_opr_ceil(array[0, 1.0 :: decimal, -2.0])
-- select sm_sc.fv_opr_ceil(array[]::decimal[])
-- select sm_sc.fv_opr_ceil(array[array[], array []]::decimal[])
-- select sm_sc.fv_opr_ceil(array[[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]],[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]]]::decimal[])
-- select sm_sc.fv_opr_ceil(array[[[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]],[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]]],[[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]],[[12.3101, -25.711, 28.33920],[-12.3101, 25.711, -28.33920]]]]::decimal[])