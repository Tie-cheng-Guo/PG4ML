-- drop function if exists sm_sc.fv_mx_descend_dim(anyarray, int);
create or replace function sm_sc.fv_mx_descend_dim
(
  i_array         anyarray  ,
  i_descend_time  int       default   1
)
returns anyarray
as
$$
declare
  v_ret            i_array%type   
    := array_fill
       (
         nullif(i_array[1], i_array[1])
       , (select array_agg(array_length(i_array, a_no) order by a_no) from generate_series(i_descend_time + 1, array_ndims(i_array)) tb_a(a_no))
       )
  ;
begin
  -- 审计维度数量
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array) < i_descend_time + 1
    then 
      raise exception 'unsupport i_descend_time > ndims of i_array - 1.';
    elsif exists (select  from generate_series(2, i_descend_time) tb_a(a_no) where array_length(i_array, a_no) > 1)
    then 
      raise exception 'unsupport length of descend dim > 1';
    end if;
  end if;
  
  if i_descend_time = 0
  then 
    v_ret[:] := i_array;
  elsif i_descend_time = 1
  then 
    v_ret[:] := i_array[1:1];
  elsif i_descend_time = 2
  then 
    v_ret[:] := i_array[1:1][1:1];
  elsif i_descend_time = 3
  then 
    v_ret[:] := i_array[1:1][1:1][1:1];
  elsif i_descend_time = 4
  then 
    v_ret[:] := i_array[1:1][1:1][1:1][1:1];
  elsif i_descend_time = 5
  then 
    v_ret[:] := i_array[1:1][1:1][1:1][1:1][1:1];
  end if;
  
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_descend_dim(array[[1, 2]])
-- select sm_sc.fv_mx_descend_dim(array[[1, 2]], 1)
-- select sm_sc.fv_mx_descend_dim(array[[[1, 2]]], 2)
-- select sm_sc.fv_mx_descend_dim(array[[[[1, 2]]]], 3)
-- select sm_sc.fv_mx_descend_dim(array[[[1, 2]]])
-- select sm_sc.fv_mx_descend_dim(array[[[1, 2]]], 1)
-- select sm_sc.fv_mx_descend_dim(array[[[1, 2]]], 2)