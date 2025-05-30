-- drop function if exists sm_sc.fv_eye_unit(float, int, int[]);
create or replace function sm_sc.fv_eye_unit
(
  in i_array_len                 int
, in i_identity_value            float
, in i_array_len_ex_heigh_width  int[] default null
)
  returns float[]
as
$$
declare -- here
  v_arr float[] := array_fill(0.0 :: float, i_array_len_ex_heigh_width || array[i_array_len, i_array_len]);
  v_cur int     ;
  v_arr_identity_value float[]:= array_fill(i_identity_value, i_array_len_ex_heigh_width || array[1,1]);
begin
  if array_length(i_array_len_ex_heigh_width, 1) = 1   -- 3d
  then 
    for v_cur in 1 .. i_array_len
    loop 
      v_arr[ : ][v_cur : v_cur][v_cur : v_cur] := v_arr_identity_value;
    end loop;
  elsif array_length(i_array_len_ex_heigh_width, 1) = 2   -- 4d
  then 
    for v_cur in 1 .. i_array_len
    loop 
      v_arr[ : ][ : ][v_cur : v_cur][v_cur : v_cur] := v_arr_identity_value;
    end loop;
  else -- 2d
    for v_cur in 1 .. i_array_len
    loop 
      v_arr[v_cur][v_cur] := i_identity_value;
    end loop;
  end if;

  return v_arr;
  -- -- return 
  -- -- (
  -- --   select 
  -- --     array_agg
  -- --     (
  -- --       array_x
  -- --       order by v_cur_y
  -- --     )
  -- --   from 
  -- --   (
  -- --     select v_cur_y,
  -- --       array_agg(case when v_cur_x = v_cur_y then i_identity_value else 0.0 end order by v_cur_x) as array_x
  -- --     from 
  -- --       generate_series(1,i_array_len) as v_cur_x
  -- --     , generate_series(1,i_array_len) as v_cur_y
  -- --     group by v_cur_y
  -- --   ) t_a_array_x
  -- -- )	
  -- -- ;

end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_eye_unit(5, 3534.776)
-- select sm_sc.fv_eye_unit(5, 3534.776, array[3])
-- select sm_sc.fv_eye_unit(5, 3534.776, array[3, 4])


-- ---------------------------------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_eye_unit(int);
create or replace function sm_sc.fv_eye_unit
(
  in i_array_len int
)
  returns float[]
as
$$
-- declare here

begin
  return sm_sc.fv_eye_unit(i_array_len, 1.0 :: float);
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_eye_unit(5)