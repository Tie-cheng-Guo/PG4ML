-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_ord_by_col(anyarray, int, boolean);
create or replace function sm_sc.fv_ord_by_col
(
  i_array          anyarray, 
  i_ord_col_no     int,
  i_is_desc        boolean   default  null
)
returns anyarray
as
$$
-- declare 
begin
  -- 审计二维长度
  if array_ndims(i_array) = 2
  then
    if i_is_desc
    then
      return 
      (
        select 
          array_agg
          (
            (select array_agg(a_ele) from unnest( i_array[a_y : a_y][:] ) tb_a(a_ele))
            order by i_array[a_y][i_ord_col_no] desc
          )
        from generate_subscripts(i_array, 1) a_y
      );
    else
      return 
      (
        select 
          array_agg
          (
            (select array_agg(a_ele) from unnest( i_array[a_y : a_y][:] ) tb_a(a_ele))
            order by i_array[a_y][i_ord_col_no]
          )
        from generate_subscripts(i_array, 1) a_y
      );
    end if;
  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_ord_by_col
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]
--     , 4
--     -- , true
--   );

-- select sm_sc.fv_ord_by_col
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]
--     , 4
--     , true
--   );


-- select sm_sc.fv_ord_by_col
--   (
--     array[array[1,2,3,4,5,6]
--         , array[10,20,30,40,50,60]
--         , array[100,200,300,400,500,600]
--         , array[-1,-2,-3,-4,-5,-6]
--         , array[-10,-20,-30,-40,-50,-60]
--         , array[-100,-200,-300,-400,-500,-600]
--          ]
--     , 4
--     , false
--   );

