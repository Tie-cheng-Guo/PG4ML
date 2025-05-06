-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new_rand_enum(anyarray, int[2]);
create or replace function sm_sc.fv_new_rand_enum
(
  i_dispersed_array   anyarray    ,
  i_dims_len            int[]
)
returns anyarray
as
$$
declare -- here
  v_enum_dic    name[]  :=  
  (
    select 
      array_agg(distinct enumlabel)
    from unnest(i_dispersed_array) tb_a_enum(enumlabel)
  );
  v_dic_len     int      :=  array_length(v_enum_dic, 1);
  v_ret    i_dispersed_array%type   ;
  v_cur_y  int       ;
  v_cur_x  int       ;
  v_cur_x3 int       ;
  v_cur_x4 int       ;
  v_cur_x5 int       ;
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dims_len) <> 1 
      or array_length(i_dims_len, 1) not between 1 and 5
      or 1 <= any(i_dims_len)
    then
      raise exception 'unsupport ndims or length!';
    end if;
  end if;

  if array_length(i_dims_len, 1) = 1
  then
    return 
    (
      select 
        array_agg(v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int])
      from generate_series(1, i_dims_len[1])
    );
  elsif array_length(i_dims_len, 1) = 2
  then 
    v_ret := array_fill(null :: float, i_dims_len);
    for v_cur_y in 1 .. i_dims_len[1]
    loop 
      for v_cur_x in 1 .. i_dims_len[2]
      loop 
        v_ret[v_cur_y][v_cur_x] = v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int];
      end loop;
    end loop;
    return v_ret;
  elsif array_length(i_dims_len, 1) = 3
  then 
    v_ret := array_fill(null :: float, i_dims_len);
    for v_cur_y in 1 .. i_dims_len[1]
    loop 
      for v_cur_x in 1 .. i_dims_len[2]
      loop 
        for v_cur_x3 in 1 .. i_dims_len[3]
        loop 
          v_ret[v_cur_y][v_cur_x][v_cur_x3] = v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int];
        end loop;
      end loop;
    end loop;
    return v_ret;
  elsif array_length(i_dims_len, 1) = 4
  then 
    v_ret := array_fill(null :: float, i_dims_len);
    for v_cur_y in 1 .. i_dims_len[1]
    loop 
      for v_cur_x in 1 .. i_dims_len[2]
      loop 
        for v_cur_x3 in 1 .. i_dims_len[3]
        loop 
          for v_cur_x4 in 1 .. i_dims_len[4]
          loop 
            v_ret[v_cur_y][v_cur_x][v_cur_x3][v_cur_x4] = v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int];
          end loop;
        end loop;
      end loop;
    end loop;
    return v_ret;
  elsif array_length(i_dims_len, 1) = 5
  then 
    v_ret := array_fill(null :: float, i_dims_len);
    for v_cur_y in 1 .. i_dims_len[1]
    loop 
      for v_cur_x in 1 .. i_dims_len[2]
      loop 
        for v_cur_x3 in 1 .. i_dims_len[3]
        loop 
          for v_cur_x4 in 1 .. i_dims_len[4]
          loop 
            for v_cur_x5 in 1 .. i_dims_len[5]
            loop 
              v_ret[v_cur_y][v_cur_x][v_cur_x3][v_cur_x4][v_cur_x5] = v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int];
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;
    return v_ret;
  else
    raise exception 'unsupport ndims!';
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_rand_enum
--   (
--     array['abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'efg', 'fgh', 'cde', 'cde', 'cde'],
--     array[5, 6]
--   );
-- select sm_sc.fv_new_rand_enum
--   (
--     array['abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'efg', 'fgh', 'cde', 'cde', 'cde'],
--     array[5]
--   );