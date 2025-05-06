-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_concat_x_dloss_dindepdt(anyarray, int4range, int[]);
create or replace function sm_sc.fv_d_concat_x_dloss_dindepdt
(
  i_dloss_ddepdt       anyarray   ,
  i_indepdt_idx_range  int4range  ,
  i_indepdt_len        int[]   default null
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if i_indepdt_len[2] <> upper(i_indepdt_idx_range) - lower(i_indepdt_idx_range)
    then 
      raise exception 'unmatch indepdt idx range at dloss_ddepdt and indepdt len. ';
    end if;
  end if;
  
  if array_ndims(i_dloss_ddepdt) = 4
  then
    if i_indepdt_len is null 
    then 
      return 	
        i_dloss_ddepdt[ : ][lower(i_indepdt_idx_range) : upper(i_indepdt_idx_range) - 1][ : ][ : ]
      ;
    else 
      -- 广播追踪
      return 
        sm_sc.fv_aggr_chunk_sum
        (
          i_dloss_ddepdt[ : ][lower(i_indepdt_idx_range) : upper(i_indepdt_idx_range) - 1][ : ][ : ]
        , i_indepdt_len
        )
      ;
    end if;
  elsif array_ndims(i_dloss_ddepdt) = 3
  then
    if i_indepdt_len is null 
    then 
      return 	
        i_dloss_ddepdt[ : ][lower(i_indepdt_idx_range) : upper(i_indepdt_idx_range) - 1][ : ]
      ;
    else 
      -- 广播追踪
      return 
        sm_sc.fv_aggr_chunk_sum
        (
          i_dloss_ddepdt[ : ][lower(i_indepdt_idx_range) : upper(i_indepdt_idx_range) - 1][ : ]
        , i_indepdt_len
        )
      ;
    end if;
  elsif array_ndims(i_dloss_ddepdt) = 2
  then
    if i_indepdt_len is null 
    then 
      return 	
        i_dloss_ddepdt[ : ][lower(i_indepdt_idx_range) : upper(i_indepdt_idx_range) - 1]
      ;
    else 
      -- 广播追踪
      return 
        sm_sc.fv_aggr_chunk_sum
        (
          i_dloss_ddepdt[ : ][lower(i_indepdt_idx_range) : upper(i_indepdt_idx_range) - 1]
        , i_indepdt_len
        )
      ;
    end if;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_dloss_ddepdt);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_concat_x_dloss_dindepdt
--   (
--     array[array[1, 2], array[3, 4]]   ,
--     int4range(2, 2, '[]')
--   );
-- -- select sm_sc.fv_d_concat_x_dloss_dindepdt
-- --   (
-- --     array[1, 2, 3, 4]   ,
-- --     int4range(2, 2, '[]')
-- --   );
-- select sm_sc.fv_d_concat_x_dloss_dindepdt
--   (
--     array[array[1, 2], array[3, 4], array[5, 6]]   ,
--     int4range(2, 2, '[]')
--   );
-- select sm_sc.fv_d_concat_x_dloss_dindepdt
--   (
--     array[array[1, 2, 7], array[3, 4, 8], array[5, 6, 9]]   ,
--     int4range(2, 2, '[]')
--   );
-- select sm_sc.fv_d_concat_x_dloss_dindepdt
--   (
--     array[[[1,2,3,4],[11,12,13,14],[111,112,113,114]],[[5,6,7,8],[15,16,17,18],[115,116,117,118]]]   ,
--     int4range(2, 2, '[]')
--   );
-- select sm_sc.fv_d_concat_x_dloss_dindepdt
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]   ,
--     int4range(2, 2, '[]')
--   );