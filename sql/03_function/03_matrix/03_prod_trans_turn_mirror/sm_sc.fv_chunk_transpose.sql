-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_chunk_transpose(anyarray, int[2]);
create or replace function sm_sc.fv_chunk_transpose
(
  i_right        anyarray
, i_chunk_len    int[2]
)
returns anyarray
as
$$
declare 
  v_ret             i_right%type ;
  v_cur_heigh       int          ;
  v_cur_width       int          ;
begin
  -- set search_path to sm_sc;
  -- 审计二维长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_right) not between 2 and 4
    then
      raise exception 'unsupport ndims!';
    elsif array_length(i_right, array_ndims(i_right) - 1) % i_chunk_len[1] <> 0
      or array_length(i_right, array_ndims(i_right)) % i_chunk_len[2] <> 0
    then 
      raise exception 'unmatch array_len for chunk_len!';
    end if;
  end if;
  
  
    
  if array_ndims(i_right) is null
  then 
    return i_right;
    
  elsif array_ndims(i_right) = 2
  then
    v_ret  :=   
      array_fill
      (
        v_ret[0]
      , array
        [
          array_length(i_right, 1) / i_chunk_len[1] * i_chunk_len[2]
        , array_length(i_right, 2) / i_chunk_len[2] * i_chunk_len[1]
        ]
      );
    for v_cur_heigh in 1 .. array_length(i_right, array_ndims(i_right) - 1) / i_chunk_len[1]
    loop 
      for v_cur_width in 1 .. array_length(i_right, array_ndims(i_right)) / i_chunk_len[2]
      loop 
        v_ret
          [(v_cur_heigh - 1) * i_chunk_len[2] + 1 : v_cur_heigh * i_chunk_len[2]]
          [(v_cur_width - 1) * i_chunk_len[1] + 1 : v_cur_width * i_chunk_len[1]]   
        :=  
          |^~| 
          (
            i_right
              [(v_cur_heigh - 1) * i_chunk_len[1] + 1 : v_cur_heigh * i_chunk_len[1]]
              [(v_cur_width - 1) * i_chunk_len[2] + 1 : v_cur_width * i_chunk_len[2]]
          )
        ;
      end loop;
    end loop;
    return v_ret;
    
  elsif array_ndims(i_right) = 3
  then
    v_ret  :=   
      array_fill
      (
        v_ret[0]
      , array
        [
          array_length(i_right, 1)
        , array_length(i_right, 2) / i_chunk_len[1] * i_chunk_len[2]
        , array_length(i_right, 3) / i_chunk_len[2] * i_chunk_len[1]
        ]
      );
    for v_cur_heigh in 1 .. array_length(i_right, array_ndims(i_right) - 1) / i_chunk_len[1]
    loop 
      for v_cur_width in 1 .. array_length(i_right, array_ndims(i_right)) / i_chunk_len[2]
      loop 
        v_ret
          [ : ]
          [(v_cur_heigh - 1) * i_chunk_len[2] + 1 : v_cur_heigh * i_chunk_len[2]]
          [(v_cur_width - 1) * i_chunk_len[1] + 1 : v_cur_width * i_chunk_len[1]]   
        :=  
          |^~| 
          (
            i_right
              [ : ]
              [(v_cur_heigh - 1) * i_chunk_len[1] + 1 : v_cur_heigh * i_chunk_len[1]]
              [(v_cur_width - 1) * i_chunk_len[2] + 1 : v_cur_width * i_chunk_len[2]]
          )
        ;
      end loop;
    end loop;
    return v_ret;
    
  elsif array_ndims(i_right) = 4
  then
    v_ret  :=   
      array_fill
      (
        v_ret[0]
      , array
        [
          array_length(i_right, 1)
        , array_length(i_right, 2)
        , array_length(i_right, 3) / i_chunk_len[1] * i_chunk_len[2]
        , array_length(i_right, 4) / i_chunk_len[2] * i_chunk_len[1]
        ]
      );
    for v_cur_heigh in 1 .. array_length(i_right, array_ndims(i_right) - 1) / i_chunk_len[1]
    loop 
      for v_cur_width in 1 .. array_length(i_right, array_ndims(i_right)) / i_chunk_len[2]
      loop 
        v_ret
          [ : ]
          [ : ]
          [(v_cur_heigh - 1) * i_chunk_len[2] + 1 : v_cur_heigh * i_chunk_len[2]]
          [(v_cur_width - 1) * i_chunk_len[1] + 1 : v_cur_width * i_chunk_len[1]]   
        :=  
          |^~| 
          (
            i_right
              [ : ]
              [ : ]
              [(v_cur_heigh - 1) * i_chunk_len[1] + 1 : v_cur_heigh * i_chunk_len[1]]
              [(v_cur_width - 1) * i_chunk_len[2] + 1 : v_cur_width * i_chunk_len[2]]
          )
        ;
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
-- -- set search_path to sm_sc;
-- select sm_sc.fv_chunk_transpose
--   (
--     sm_sc.fv_new_rand(array[6, 15])
--   , array[3, 5]
--   );
-- select sm_sc.fv_chunk_transpose
--   (
--     sm_sc.fv_new_rand(array[2, 6, 15])
--   , array[3, 5]
--   );
-- select sm_sc.fv_chunk_transpose
--   (
--     sm_sc.fv_new_rand(array[3, 2, 6, 15])
--   , array[3, 5]
--   );