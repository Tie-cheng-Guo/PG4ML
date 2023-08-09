-- drop function if exists sm_sc.fv_opr_trunc(decimal[], int);
create or replace function sm_sc.fv_opr_trunc
(
  i_left         decimal[],
  i_num_digits    int
)
returns decimal[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_left, array_ndims(i_left)) is null
  then 
    return i_left;
  end if;

  -- trunc([][])
  if array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := trunc(i_left[v_y_cur][v_x_cur], i_num_digits);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- trunc []
  elsif array_ndims(i_left) = 1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := trunc(i_left[v_y_cur], i_num_digits);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_trunc(array[array[12.3, 25.1], array[2.56, 3.25]], 1)
-- select sm_sc.fv_opr_trunc(array[12.3, 25.1, 28.33], 0)
-- select sm_sc.fv_opr_trunc(array[]::float[])
-- select sm_sc.fv_opr_trunc(array[array[], array []]::float[])

-- ---------------------------------------------------------------------------
-- -- 以下单入参函数是必要的，无法用设置默认值的双入参代替，且一定不能用后者（两者对单入参调用冲突），后者无法支持单目运算符
-- drop function if exists sm_sc.fv_opr_trunc(decimal[]);
create or replace function sm_sc.fv_opr_trunc
(
  i_left     decimal[]
)
returns decimal[]
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_left, array_ndims(i_left)) is null
  then 
    return i_left;
  end if;

  -- trunc([][])
  if array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := trunc(i_left[v_y_cur][v_x_cur]);
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- trunc []
  elsif array_ndims(i_left) = 1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := trunc(i_left[v_y_cur]);
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_trunc(array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_trunc(array[12.3, 25.1, 28.33])
-- select sm_sc.fv_opr_trunc(array[]::float[])
-- select sm_sc.fv_opr_trunc(array[array[], array []]::float[])