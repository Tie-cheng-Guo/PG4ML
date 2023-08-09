-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_conv_de_log(anyarray, anyarray);
create or replace function sm_sc.fv_opr_conv_de_log
(
  i_window             anyarray          ,    -- 窗口
  i_background              anyarray                                          
)
returns anyarray
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_background) > 2
  then 
    return null; raise notice 'no method for such i_background length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_background), array_length(i_background, 1), array_length(i_background, 2);
  elsif array_ndims(i_window) > 2
  then 
    return null; raise notice 'no method for such i_window length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_window), array_length(i_window, 1), array_length(i_window, 2);
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
  
  if array_length(i_background, 1) < array_length(i_window, 1)
  then 
    raise exception 'imperfect window at 1d.';
  elsif array_length(i_background, 2) < array_length(i_window, 2)
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
-- select sm_sc.fv_opr_conv_de_log
--   (
--     array[[1.5 :: float, 2.0, 3.0], [1.5, 2.0, 3.0], [3.0, 2.0, 1.7]],
--     array[[1.5 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0, 8.0, 9.0]
--         , [10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0, 8.0, 9.0]
--         , [100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0, 8.0, 9.0]
--         , [1.5 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0, 8.0, 9.0]
--         , [10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0, 8.0, 9.0]
--         , [10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0, 8.0, 9.0]
--          ]
--   );

-- select sm_sc.fv_opr_conv_de_log
--   (
--     array[1.5, 2, 3]
--     , array[1.5, 2, 3, 4, 5, 6, 7, 8, 9]
--   );