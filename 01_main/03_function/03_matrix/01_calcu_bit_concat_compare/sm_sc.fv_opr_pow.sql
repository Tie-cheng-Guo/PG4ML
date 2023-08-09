-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_pow(anyarray, anyarray);
create or replace function sm_sc.fv_opr_pow
(
  i_left     anyarray    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;  -- -- -- 从 0 开始游标，避免(array[]::float[])[1]
  v_y_cur   int  := 1  ;
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if array_ndims(i_left) > 2 
    or array_ndims(i_right) > 2
    or array_ndims(i_left) = 1 
      and array_ndims(i_right) = 1 
      and array_length(i_left, 1) <> array_length(i_right, 1)
      and array_length(i_left, 1) <> 1
      and array_length(i_right, 1) <> 1
    or array_ndims(i_left) = 2 and array_ndims(i_right) = 2
      and array_length(i_left, 1) <> array_length(i_right, 1) 
      and array_length(i_left, 1) <> array_length(i_right, 2)
      and array_length(i_left, 2) <> array_length(i_right, 1)
      and array_length(i_left, 1) <> 1
      and array_length(i_right, 1) <> 1
      and array_length(i_left, 2) <> 1
      and array_length(i_right, 2) <> 1
  then
    raise exception 'no method!';
  end if;

  -- array[] ^ []
  if array_length(i_left, array_ndims(i_left)) is null and i_left is not null -- = 0
  then 
    return i_right;
  -- [] ^ array[]
  elsif array_length(i_right, array_ndims(i_right)) is null and i_right is not null -- = 0
  then 
    return i_left;

  elsif i_left is null or i_right is null
  then
    return null::anyarray;

  -- [.] ^ []
  elsif array_ndims(i_left) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_pow(i_left[1], i_right);
  -- [] ^ [.]
  elsif array_ndims(i_right) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_pow(i_left, i_right[1]);

  -- [[.]] ^ []
  elsif array_length(i_left, 2) = 1 and array_length(i_left, 1) = 1
  then 
    return sm_sc.fv_opr_pow(i_left[1][1], i_right);
  -- [] ^ [[.]]
  elsif array_length(i_right, 2) = 1 and array_length(i_right, 1) = 1
  then 
    return sm_sc.fv_opr_pow(i_left, i_right[1][1]);

  -- [] ^ []
  elsif array_ndims(i_left) = 1 and array_ndims(i_right) = 1 and array_length(i_left, 1) = array_length(i_right, 1)
  then 
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := case when i_left[v_y_cur] > 1.0 and i_right[v_y_cur] = '-inf' :: float 
                                or i_left[v_y_cur] < 1.0 and i_right[v_y_cur] = 'inf' :: float 
                              then 0.0
                              else i_left[v_y_cur] ^ i_right[v_y_cur] end;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 以下 if 分支已隐含 1 <= array_ndims(i_left) = array_ndims(i_right) <= 2 条件。
  -- 同形状 [][] ^ [][]
  elsif array_length(i_left, 1) = array_length(i_right, 1) and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_left[v_y_cur][v_x_cur] := case when i_left[v_y_cur][v_x_cur] > 1.0 and i_right[v_y_cur][v_x_cur] = '-inf' :: float 
                                           or i_left[v_y_cur][v_x_cur] < 1.0 and i_right[v_y_cur][v_x_cur] = 'inf' :: float 
                                         then 0.0
                                         else i_left[v_y_cur][v_x_cur] ^ i_right[v_y_cur][v_x_cur] end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 横向广播，i_left 需要延拓 [][1] ^ [][]
  elsif array_length(i_left, 2) = 1 and array_ndims(i_right) = 2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := case when i_left[v_y_cur][1] > 1.0 and i_right[v_y_cur][v_x_cur] = '-inf' :: float 
                                           or i_left[v_y_cur][1] < 1.0 and i_right[v_y_cur][v_x_cur] = 'inf' :: float 
                                         then 0.0
                                         else i_left[v_y_cur][1] ^ i_right[v_y_cur][v_x_cur] end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 横向广播，i_right 需要延拓 [][] ^ [][1]
  elsif array_length(i_right, 2) = 1 and array_ndims(i_left) = 2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := case when i_left[v_y_cur][v_x_cur] > 1.0 and i_right[v_y_cur][1] = '-inf' :: float 
                                           or i_left[v_y_cur][v_x_cur] < 1.0 and i_right[v_y_cur][1] = 'inf' :: float 
                                         then 0.0
                                         else i_left[v_y_cur][v_x_cur] ^ i_right[v_y_cur][1] end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;
  -- 纵向广播 i_left 需要延拓 [1][] ^ [][]
  elsif array_length(i_left, 1) = 1 and array_length(i_left, 2) = array_length(i_right, 2)
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := case when i_left[1][v_x_cur] > 1.0 and i_right[v_y_cur][v_x_cur] = '-inf' :: float 
                                           or i_left[1][v_x_cur] < 1.0 and i_right[v_y_cur][v_x_cur] = 'inf' :: float 
                                         then 0.0
                                         else i_left[1][v_x_cur] ^ i_right[v_y_cur][v_x_cur] end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;
  -- 纵向广播 i_right 需要延拓 [][] ^ [1][]
  elsif array_length(i_right, 1) = 1 and array_length(i_right, 2) = array_length(i_left, 2)
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := case when i_left[v_y_cur][v_x_cur] > 1.0 and i_right[1][v_x_cur] = '-inf' :: float 
                                           or i_left[v_y_cur][v_x_cur] < 1.0 and i_right[1][v_x_cur] = 'inf' :: float 
                                         then 0.0
                                         else i_left[v_y_cur][v_x_cur] ^ i_right[1][v_x_cur] end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- 审计二维长度
  else
    return null; raise notice 'no method for such length!  L_Ndim: %; L_len_1: %; L_len_2: %; R_Ndim: %; R_len_1: %; R_len_2: %;', array_ndims(i_left), array_length(i_left, 1), array_length(i_left, 2), array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_pow
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[array[32.5], array[-9.1]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[12.5], array[-19.1]]
--   );
-- -- select sm_sc.fv_opr_pow    -- 设计不支持一维二维混合运算
-- --   (
-- --     array[32.5, -9.1],
-- --     array[array[-12.3, 12.3], array[-45.6, 45.6]]
-- --   );
-- -- select sm_sc.fv_opr_pow    -- 设计不支持一维二维混合运算
-- --   (
-- --     array[array[12.3, -12.3], array[45.6, -45.6]],
-- --     array[12.5, -19.1]
-- --   );
-- select sm_sc.fv_opr_pow
--   (
--     array[array[32.5, -9.1]],
--     array[array[-12.3, 12.3], array[-45.6, 45.6]]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[array[12.3, -12.3], array[45.6, -45.6]],
--     array[array[12.5, -19.1]]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[array[], array []]::float[],
--     array[]::float[]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[array[], array []]::float[],
--     array[array[], array []]::float[]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[1.2, 2.3]::float[],
--     array[2.1, 3.2]::float[]
--   );
-- select sm_sc.fv_opr_pow
--   (
--     array[0.2, 2.3]::float[],
--     array['inf', '-inf']::float[]
--   );
-- select sm_sc.fv_opr_pow(array[2], array[1,2,3]);
-- select sm_sc.fv_opr_pow(array[2], array[array[1,2,3]]);
-- select sm_sc.fv_opr_pow(array[array[2.5]], array[1,2,3]::float[]);
-- select sm_sc.fv_opr_pow(array[array[2.5]], array[array[1,2,3]]::float[]);

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_pow(anyarray, anyelement);
create or replace function sm_sc.fv_opr_pow
(
  i_left     anyarray    ,
  i_right    anyelement
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- null :: float[][] ^ float = null :: float[][]
  if array_length(i_left, array_ndims(i_left)) is null and i_right is not null
  then 
    return i_left;
  -- -- elsif i_right is null
  -- -- then
  -- --   return null::anyarray;

  -- [][] ^ float
  elsif array_ndims(i_left) =  2
  then
    while v_y_cur <= array_length(i_left, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_left, 2)
      loop
        i_left[v_y_cur][v_x_cur] := case when i_left[v_y_cur][v_x_cur] > 1.0 and i_right = '-inf' :: float 
                                           or i_left[v_y_cur][v_x_cur] < 1.0 and i_right = 'inf' :: float 
                                         then 0.0
                                         else i_left[v_y_cur][v_x_cur] ^ i_right end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_left;

  -- [] ^ float
  elsif array_ndims(i_left) =  1
  then
    while v_y_cur <= array_length(i_left, 1)
    loop
      i_left[v_y_cur] := case when i_left[v_y_cur] > 1.0 and i_right = '-inf' :: float 
                                or i_left[v_y_cur] < 1.0 and i_right = 'inf' :: float 
                              then 0.0
                              else i_left[v_y_cur] ^ i_right end;
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
-- select sm_sc.fv_opr_pow(array[array[12.3, 25.1], array[2.56, 3.25]], 8.8)
-- select sm_sc.fv_opr_pow(array[array[12.3, 25.1], array[2.56, 3.25]] :: float[], '-inf' :: float)
-- select sm_sc.fv_opr_pow(array[]::float[], 8.8)
-- select sm_sc.fv_opr_pow(array[]::float[], null)
-- select sm_sc.fv_opr_pow(array[1.2, 2.3]::float[], 8.8)
-- select sm_sc.fv_opr_pow(array[array[], array []]::float[], 8.8)
-- select sm_sc.fv_opr_pow(array[1.2, 2.3]::float[], null::float)

-- -----------------------------------------------------------------------
-- drop function if exists sm_sc.fv_opr_pow(anyelement, anyarray);
create or replace function sm_sc.fv_opr_pow
(
  i_left     anyelement    ,
  i_right    anyarray
)
returns anyarray
as
$$
declare -- here
  v_x_cur   int  := 1  ;
  v_y_cur   int  := 1  ;
begin
  -- null :: float[][] ^ float = null :: float[][]
  if array_length(i_right, array_ndims(i_right)) is null and i_left is not null
  then 
    return i_right;
  -- -- elsif i_left is null
  -- -- then
  -- --   return null::anyarray;

  -- float ^ [][]
  elsif array_ndims(i_right) =  2
  then
    while v_y_cur <= array_length(i_right, 1)
    loop 
      v_x_cur := 1  ;
      while v_x_cur <= array_length(i_right, 2)
      loop
        i_right[v_y_cur][v_x_cur] := case when i_left > 1.0 and i_right[v_y_cur][v_x_cur] = '-inf' :: float 
                                            or i_left < 1.0 and i_right[v_y_cur][v_x_cur] = 'inf' :: float 
                                          then 0.0
                                          else i_left ^ i_right[v_y_cur][v_x_cur] end;
        v_x_cur := v_x_cur + 1;
      end loop;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  -- float ^ []
  elsif array_ndims(i_right) =  1
  then
    while v_y_cur <= array_length(i_right, 1)
    loop
      i_right[v_y_cur] := case when i_left > 1.0 and i_right[v_y_cur] = '-inf' :: float 
                                 or i_left < 1.0 and i_right[v_y_cur] = 'inf' :: float 
                               then 0.0
                               else i_left ^ i_right[v_y_cur] end;
      v_y_cur := v_y_cur + 1;
    end loop;
    return i_right;

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_right), array_length(i_right, 1), array_length(i_right, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_opr_pow(8.8, array[array[12.3, 25.1], array[2.56, 3.25]])
-- select sm_sc.fv_opr_pow(8.8, array[]::float[] )
-- select sm_sc.fv_opr_pow(null, array[]::float[])
-- select sm_sc.fv_opr_pow(8.8, array[1.2, 2.3]::float[] )
-- select sm_sc.fv_opr_pow(8.8, array[array[], array []]::float[])
-- select sm_sc.fv_opr_pow(null::float, array[1.2, 2.3]::float[] )
-- select sm_sc.fv_opr_pow(8.8::float, array['-inf'::float, 2.3])
-- select sm_sc.fv_opr_pow(0.8::float, array['inf'::float, 2.3])