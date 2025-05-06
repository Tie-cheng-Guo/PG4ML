-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_conv_de_log_stride_1(anyarray, anyarray);
create or replace function sm_sc.fv_opr_conv_de_log_stride_1
(                                         
  i_window             anyarray      ,    -- 窗口
  i_background         anyarray    
)
returns anyarray
as
$$
-- declare 
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    -- 审计二维长度
    if array_ndims(i_background) > 4
    then 
      raise exception 'no method for such i_background length!  Dims: %;', array_dims(i_background);
    elsif array_ndims(i_window) > 2 and array_ndims(i_window) <> array_ndims(i_background)
    then 
      raise exception 'no method for such i_window length!  Dims: %;', array_dims(i_window);
    elsif array_ndims(i_window) = 3 and array_length(i_window, 1) <> array_length(i_background, 1)
      or array_ndims(i_window) = 4 and (array_length(i_window, 1) <> array_length(i_background, 1) or array_length(i_window, 2) <> array_length(i_background, 2))
    then 
      raise exception 'unmatch length between i_window and i_background at 3d or 4d.';
    end if;
  end if;
  
  if array_ndims(i_background) = 1 and array_ndims(i_window) = 1
  then 
    if array_length(i_background, 1) < array_length(i_window, 1)
    then 
      raise exception 'imperfect window at 1d.';
    else 
      return 
      (
        select 
          sm_sc.fa_array_concat(i_window ^!` i_background[col_a_y : col_a_y + array_length(i_window, 1) - 1] order by col_a_y)
        from generate_series(1, array_length(i_background, 1) - array_length(i_window, 1) + 1) tb_a_y(col_a_y)
      )
      ;
    end if;
  end if;
  
  if array_length(i_background, array_ndims(i_background) - 1) < array_length(i_window, 1)
  then 
    raise exception 'imperfect window at 1d.';
  elsif array_length(i_background, array_ndims(i_background)) < array_length(i_window, 2)
  then 
    raise exception 'imperfect window at 2d.';
  else
    return 
      sm_sc.fv_conv_de_log
      (
        i_window     ,
        i_background      
      )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_conv_de_log_stride_1
--   (
--     array[[1.0, 2.0, 3.0], [-1.0, -2.0, -3.0], [3.0, -2.0, 1.0]]
--   , array
--         [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--   );

-- select sm_sc.fv_opr_conv_de_log_stride_1
--   (
--     array[[1.0, 2.0, 3.0], [-1.0, -2.0, -3.0], [3.0, -2.0, 1.0]]
--   , array
--       [
--         [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--       , [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--       ]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_opr_conv_de_log_stride_1
--   (
--     array
--     [
--       [
--         [[0.15, 0.2, 0.3], [1.4, 0.2, 0.3], [0.3, 0.2, 0.17]]
--       , [[1.4, 0.2, 0.3], [0.15, 0.2, 0.3], [0.3, 0.2, 0.17]]
--       ]
--     , [
--         [[1.5, 2.0, 3.0], [3.0, 2.0, 1.7], [1.4, 2.0, 3.0]]
--       , [[3.0, 2.0, 1.7], [1.4, 2.0, 3.0], [1.5, 2.0, 3.0]]
--       ]
--     ]
--   , array
--     [
--       [
--         [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--       , [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--       ]
--     , [
--         [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--       , [
--           [1.1,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
--         , [1.2,2.2,3.3,4.1,5.6,6.2,7.4,8.4,9.4]
--         , [1.3,2.3,3.3,4.3,5.3,6.3,7.3,8.3,9.3]
--         , [1.4,2.4,3.4,4.4,5.4,6.4,7.4,8.4,9.4]
--         , [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5]
--         ]
--       ]
--     ]
--   ) :: decimal[] ~=` 3;

-- select sm_sc.fv_opr_conv_de_log_stride_1
--   (
--     array[1.5, 2, 3]
--   , array[1.3, 2, 3, 4, 5, 6, 7, 8, 9]
--   );