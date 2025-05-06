-- drop function if exists sm_sc.fv_d_mx_slice_4d_2_3d_dloss_dindepdt(float[], int[], int, int);
create or replace function sm_sc.fv_d_mx_slice_4d_2_3d_dloss_dindepdt
(
  i_dloss_dindepdt  float[]  
, i_indepdt_len     int[4]                  -- 自变量规格
, i_dim_sliced      int                     -- 被切片维度
, i_slice_pos       int     default  1      -- 被切片位置序号
)
returns float[]
as
$$
declare
  v_ret      i_dloss_dindepdt%type;
begin
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if i_dim_sliced not between 1 and 4
    then 
      raise exception 'i_dim_sliced is out of length.';
    elsif array_ndims(i_dloss_dindepdt) <> 3
    then 
      raise exception 'ndims of dloss_dindepdt should be 3.';
    elsif array[array_length(i_dloss_dindepdt, 1), array_length(i_dloss_dindepdt, 2), array_length(i_dloss_dindepdt, 3)] <> (i_indepdt_len[ : i_dim_sliced - 1] || i_indepdt_len[i_dim_sliced + 1 : ])
    then 
      raise exception 'len of i_dloss_dindepdt should match with i_indepdt_len by i_dim_sliced.';
    elsif i_slice_pos not between 1 and i_indepdt_len[i_dim_sliced]
    then 
      raise exception 'i_slice_pos is out of i_indepdt_len[i_dim_sliced].';
    end if;
  end if;

  v_ret := array_fill(0.0 , i_indepdt_len);
  
  if i_dim_sliced = 1
  then 
    v_ret[i_slice_pos : i_slice_pos][ : ][ : ][ : ] := i_dloss_dindepdt;
  elsif i_dim_sliced = 2
  then 
    v_ret[ : ][i_slice_pos : i_slice_pos][ : ][ : ] := i_dloss_dindepdt;
  elsif i_dim_sliced = 3
  then 
    v_ret[ : ][ : ][i_slice_pos : i_slice_pos][ : ] := i_dloss_dindepdt;
  elsif i_dim_sliced = 4
  then 
    v_ret[ : ][ : ][ : ][i_slice_pos : i_slice_pos] := i_dloss_dindepdt;
    
  end if;
  
  return v_ret;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select 
--   sm_sc.fv_d_mx_slice_4d_2_3d_dloss_dindepdt
--   (
--     (
--       array
--       [[
--         [1, 2, 3, 4, 5]     ,
--         [11, 12, 13, 14, 15],
--         [21, 22, 23, 24, 25], 
--         [31, 32, 33, 34, 35] 
--       ]]
--     )
--     , array[2, 1, 4, 5]
--     , 1
--     , 2
--   )