-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_aggr_slice_avg(anyarray);
create or replace function sm_sc.fv_aggr_slice_avg
(
  i_array          anyarray
)
returns anyelement
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) is null
  then
    return i_array[0];
  else
    return
    (
      select 
        avg(a_ele)
      from unnest(i_array) a_ele   -- tb_a(a_ele)  --  unnest 表内字段别名，对自定义复合类型数组的支持有 bug?，例如：select a_ele from unnest(array[(1.2, 2.3) :: sm_sc.typ_l_complex]) tb_a(a_ele)
    );
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_aggr_slice_avg
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]::float[]
--   );

-- select sm_sc.fv_aggr_slice_avg
--   (
--     array[1,2,3,4,5,6]::float[]
--   );

-- select sm_sc.fv_aggr_slice_avg
--   (
--     array[]::float[]
--   );

