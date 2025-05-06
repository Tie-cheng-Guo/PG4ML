-- set search_path to sm_sc;
-- drop function if exists sm_sc.ft_onehot_dic(anyarray, float, float);
create or replace function sm_sc.ft_onehot_dic
(
  i_array              anyarray
, i_upper              float    default    1.0 :: float
, i_lower              float    default    0.0
)
returns table 
(
  o_ele     anyelement
, o_onehot  float[]    
)
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
  
  return query
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
      , row_number() over(order by a_no_rank) :: int as a_no_x
      , i_array[min(a_no)]    as a_ele
      from cte_ele
      group by a_no_rank
    ), 
    cte_dist_cnt as 
    (
      select 
        count(a_no_x) :: int as a_dist_cnt
      from cte_dist_ele
    )
    select 
      a_ele
    , array_fill(i_lower, array[a_no_x - 1]) || i_upper || array_fill(i_lower, array[a_dist_cnt - a_no_x])
    from cte_dist_ele, cte_dist_cnt
    order by a_no_rank
  ;

end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select * 
-- from 
--   sm_sc.ft_onehot_dic
--   (
--     array[1,2,3,1,4,3,5,6]
--   );

-- select  * 
-- from 
--   sm_sc.ft_onehot_dic
--   (
--     array[array[1]
--         , array[10]
--         , array[100]
--         , array[-1]
--         , array[10]
--         , array[-10]
--          ]
--   );

-- select  * 
-- from 
--   sm_sc.ft_onehot_dic
--   (
--     array[1,2,3,4,5,6]
--     ,2.0
--   );

-- select  * 
-- from 
--   sm_sc.ft_onehot_dic
--   (
--     array[1,2,3,4,5,6]
--     , 1.0
--     , -1.0
--   );

-- select  * 
-- from 
--   sm_sc.ft_onehot_dic
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
