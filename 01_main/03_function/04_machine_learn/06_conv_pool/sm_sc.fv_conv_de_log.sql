-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_conv_de_log(anyarray, anyarray, int[2], int[4], anyelement);
create or replace function sm_sc.fv_conv_de_log
(
  i_window             anyarray                                             ,  -- 窗口
  i_background              anyarray                                             ,
  i_stride             int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding            int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value      anyelement          default  '0.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_window_len_y    int   :=    array_length(i_window, 1)  ;
  v_window_len_x    int   :=    array_length(i_window, 2)  ;
begin
  -- 审计二维长度
  if array_ndims(i_background) <> 2
  then 
    return null; raise notice 'no method for such i_background length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_background), array_length(i_background, 1), array_length(i_background, 2);
  elsif array_ndims(i_window) <> 2
  then 
    return null; raise notice 'no method for such i_window length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_window), array_length(i_window, 1), array_length(i_window, 2);
  elsif (coalesce(i_padding[1], 0) + array_length(i_background, 1) + coalesce(i_padding[2], 0) - v_window_len_y) % i_stride[1] <> 0
  then 
    raise exception 'imperfect window at 1d.';
  elsif (coalesce(i_padding[3], 0) + array_length(i_background, 2) + coalesce(i_padding[4], 0) - v_window_len_x) % i_stride[2] <> 0
  then 
    raise exception 'imperfect window at 2d.';
  else
    i_background := 
      sm_sc.fv_augmented
      (
        i_background, 
        array[-i_padding[1] + 1, -i_padding[3] + 1], 
        array[array_length(i_background, 1) + i_padding[2], array_length(i_background, 2) + i_padding[4]], 
        i_padding_value
      );
    return 
    (
      with 
      cte_ret_y as
      (
        select 
          col_a_y,
          sm_sc.fa_mx_concat_x(i_window ^!` i_background[col_a_y : col_a_y + v_window_len_y - 1][col_a_x : col_a_x + v_window_len_x - 1] order by col_a_x) as ret_y
        from generate_series(1, array_length(i_background, 1) - v_window_len_y + i_stride[1], i_stride[1]) tb_a_y(col_a_y)
          , generate_series(1, array_length(i_background, 2) - v_window_len_x + i_stride[2], i_stride[2]) tb_a_x(col_a_x)
        group by col_a_y
      )
      select sm_sc.fa_mx_concat_y(ret_y order by col_a_y) from cte_ret_y
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_conv_de_log
--   (
--     array[[1.5 :: float, 2.0, 3.0], [1.5, 3.0, 2.0], [3.0, 2.0, 1.5]]
--    , array[array[1.5 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--         , array[100.0 :: float,200.0 :: float,300.0 :: float,400.0 :: float,500.0 :: float,600.0 :: float,700.0]
--         , array[1.5 :: float,2.0 :: float,3.0,4.0,5.0,6.0,7.0]
--         , array[10.0 :: float,20.0 :: float,30.0 :: float,40.0 :: float,50.0 :: float,60.0 :: float,70.0]
--          ]
--    , array[2, 2]
--   );
