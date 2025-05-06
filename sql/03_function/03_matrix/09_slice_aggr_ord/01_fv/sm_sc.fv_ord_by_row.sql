-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_ord_by_row(anyarray, int, boolean);
create or replace function sm_sc.fv_ord_by_row
(
  i_array          anyarray, 
  i_ord_row_no     int,
  i_is_desc        boolean  default null
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
        -- -- select  
        -- --   i_array[a_y][a_x]
        -- -- from generate_subscripts(i_array, 1) tb_a_y(a_y)
        -- --   , generate_subscripts(i_array, 2) tb_a_x(a_x)
        -- -- order by a_y, i_array[i_ord_row_no][a_x] desc

        select
          array_agg(a_row order by a_y)
        from generate_subscripts(i_array, 1) tb_a_y(a_y)
          , lateral (select array_agg(i_array[tb_a_y.a_y][a_x] order by i_array[i_ord_row_no][a_x] desc) as a_row from generate_subscripts(i_array, 2) tb_a_x(a_x)) tb_a_x_row
      );
    else
      return 
      (
        -- -- select  
        -- --   i_array[a_y][a_x]
        -- -- from generate_subscripts(i_array, 1) tb_a_y(a_y)
        -- --   , generate_subscripts(i_array, 2) tb_a_x(a_x)
        -- -- order by a_y, i_array[i_ord_row_no][a_x]

        select
          array_agg(a_row order by a_y)
        from generate_subscripts(i_array, 1) tb_a_y(a_y)
          , lateral (select array_agg(i_array[tb_a_y.a_y][a_x] order by i_array[i_ord_row_no][a_x]) as a_row from generate_subscripts(i_array, 2) tb_a_x(a_x)) tb_a_x_row
      );
    end if;
  else
    raise exception 'no method for such length!  Dims: %;', array_dims(i_array);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_ord_by_row
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

-- select sm_sc.fv_ord_by_row
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


-- select sm_sc.fv_ord_by_row
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

