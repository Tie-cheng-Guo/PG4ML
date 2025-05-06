-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_onehot(anyarray, float, float);
create or replace function sm_sc.fv_onehot
(
  i_array              anyarray,
  i_upper               float    default    1.0 :: float  ,
  i_lower                float    default    0.0
)
returns float[]     -- 输出列序与 i_array 元素原位置一致
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2 and array_length(i_array, 2) = 1
  then 
    i_array := sm_sc.fv_mx_ele_2d_2_1d(i_array);
  elsif array_ndims(i_array) <> 1
  then
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
    
  return 
  (
    with 
    cte_ele as
    (
      select 
        a_no
      , rank() over(order by i_array[a_no]) :: int as a_no_rank
      from generate_series(1, array_length(i_array, 1)) tb_a(a_no)
    ),
    cte_dist_ele as
    (
      select 
        a_no_rank 
      , array_agg(a_no) as a_nos_per_enum
      from cte_ele
      group by a_no_rank
    ),
    cte_onehot as
    (
      select 
        a_no
      , array_agg(case when cte_ele.a_no = any(cte_dist_ele.a_nos_per_enum) then i_upper else i_lower end order by cte_dist_ele.a_no_rank) as a_onehot
      from cte_ele, cte_dist_ele
      group by a_no
    )
    select array_agg(a_onehot order by a_no) from cte_onehot
  );
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_onehot
--   (
--     array[1,2,3,1,4,3,5,6]
--   );

-- select sm_sc.fv_onehot
--   (
--     array[array[1]
--         , array[10]
--         , array[100]
--         , array[-1]
--         , array[10]
--         , array[-10]
--          ]
--   );

-- select sm_sc.fv_onehot
--   (
--     array[1,2,3,4,5,6]
--     ,2.0
--   );

-- select sm_sc.fv_onehot
--   (
--     array[1,2,3,4,5,6]
--     , 1.0
--     , -1.0
--   );

-- select sm_sc.fv_onehot
--   (
--     array[array[1]
--         , array[10]
--         , array[100]
--         , array[-1]
--         , array[-10]
--          ]
--     , 1.0
--     , -1.0
--   );
