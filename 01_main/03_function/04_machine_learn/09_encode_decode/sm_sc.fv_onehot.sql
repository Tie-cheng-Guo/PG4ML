-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_onehot(anyarray, float, float);
create or replace function sm_sc.fv_onehot
(
  i_array              anyarray,
  i_upper               float    default    1.0 :: float  ,
  i_lower                float    default    0.0
)
returns float[]     -- 输出列序与 i_array 枚举值字母序一致
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2 and array_length(i_array, 2) = 1
    or array_ndims(i_array) = 1
  then
    return 
    (
      with 
      cte_dist_ele as
      (
        select 
          row_number() over() as a_no_x,
          a_ele 
        from unnest(i_array) tb_a_dist_ele(a_ele) 
        group by a_ele
        order by a_ele
      ),
      cte_ele as
      (
        select 
          row_number() over() as a_no_y,
          a_ele
        from unnest(i_array) tb_a_ele(a_ele)
      ),
      cte_onehot as
      (
        select 
          a_no_y,
          array_agg(case when cte_ele.a_ele = cte_dist_ele.a_ele then i_upper else i_lower end order by a_no_x) as a_onehot
        from cte_ele, cte_dist_ele
        group by a_no_y
      )
      select array_agg(a_onehot order by a_no_y) from cte_onehot
    );
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
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
