-- drop function if exists sm_sc.fv_d_repeat_axis_dloss_dindepdt(float[], int[], int[]);
create or replace function sm_sc.fv_d_repeat_axis_dloss_dindepdt
(
  i_dloss_ddepdt     float[]
, i_dims             int[]  
, i_repeats          int[]  
)
returns float[]    -- 返回值为 2d
as
$$
declare 
  v_dims             int[]    := i_dims %` array_ndims(i_dloss_ddepdt);
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_ddepdt) not between 1 and 6
    then 
      raise exception 'unsupport ndims of i_dloss_ddepdt.';
    elsif |@|`| ((@|` i_dims) >` array_ndims(i_dloss_ddepdt))   -- 判断 i_dims 是否有越界 i_dloss_ddepdt 的维度
    then 
      raise exception 'i_dims cross the border of i_dloss_ddepdt'' ndims.';
    elsif array_ndims(i_dims) <> array_ndims(i_repeats)
    then 
      raise exception 'unmatch ndims for i_dims and i_repeats';
    end if;
  end if;
  
  return 
    sm_sc.fv_aggr_slice_sum_py
    (
      i_dloss_ddepdt
    , (
        select 
          array_agg(coalesce(a_repeat, 1) order by a_dim_no)
        from generate_series(1, array_ndims(i_dloss_ddepdt)) tb_a_dim_no(a_dim_no)
        left join unnest(i_dims, i_repeats) tb_a_axis_no(a_axis_no, a_repeat)
          on tb_a_axis_no.a_axis_no = tb_a_dim_no.a_dim_no
      )
    )
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select 
--   sm_sc.fv_d_repeat_axis_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[6,9,10,8])
--   , array[2, 3]
--   , array[3, 5]
--   );
-- select 
--   sm_sc.fv_d_repeat_axis_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[6,10,8])
--   , array[1, 3]
--   , array[2, 4]
--   );
-- select 
--   sm_sc.fv_d_repeat_axis_dloss_dindepdt
--   (
--     sm_sc.fv_new_rand(array[10,8])
--   , array[1]
--   , array[2]
--   );
