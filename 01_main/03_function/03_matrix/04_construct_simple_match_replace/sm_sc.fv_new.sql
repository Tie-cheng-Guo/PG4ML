-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new(anynonarray, int[]);
create or replace function sm_sc.fv_new
(
  i_meta_val     anynonarray    ,
  i_yx_len       int[]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if array_ndims(i_yx_len) > 1
  then
    raise exception 'no method!';
  elsif array_ndims(i_yx_len) is null
  then 
    return array[] :: i_meta_val%type;
  else
    return array_fill(i_meta_val, i_yx_len);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new
--   (
--     12.3,
--     array[5, 6]
--   );

-- drop function if exists sm_sc.fv_new(anyarray, int[]);
create or replace function sm_sc.fv_new
(
  i_meta_val     anyarray    ,
  i_yx_times        int[]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if array_ndims(i_meta_val) > 2 or array_ndims(i_yx_times) <> 1 or array_length(i_yx_times, 1) <> array_ndims(i_meta_val)
  then
    raise exception 'no method!';
  elsif array_ndims(i_meta_val) is null
  then 
    return array[] :: i_meta_val%type;
  elsif array_ndims(i_meta_val) = 1
  then
    return (select sm_sc.fa_array_concat(i_meta_val) from generate_series(1, i_yx_times[1]) tb_a);
  elsif array_ndims(i_meta_val) = 2
  then
    return 
    (
      with
      cte_y as 
      (
        select 
          sm_sc.fa_mx_concat_x(i_meta_val) as a_x_meta_val
        from generate_series(1, i_yx_times[2]) tb_a_x(a_x_no)
      )
      select 
        sm_sc.fa_mx_concat_y(a_x_meta_val) 
      from cte_y, generate_series(1, i_yx_times[1]) tb_a_y(a_y_no)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new
--   (
--     array[12.3, 156.6, 7.8, -93.6],
--     array[5]
--   );
-- select sm_sc.fv_new
--   (
--     array[array[12.3, 156.6, 7.8, -93.6]],
--     array[5, 2]
--   );
-- select sm_sc.fv_new
--   (
--     array[array[12.3, 3.3], array[156.6, 3.3], array[7.8, 3.3], array[-93.6, 3.3]],
--     array[5, 2]
--   );
-- select sm_sc.fv_new
--   (
--     array[array[12.3]],
--     array[5, 2]
--   );