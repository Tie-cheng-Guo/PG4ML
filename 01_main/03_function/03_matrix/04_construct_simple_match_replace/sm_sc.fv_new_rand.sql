-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new_rand(int[2]);
create or replace function sm_sc.fv_new_rand
(
  i_yx_len       int[2]
)
returns float[]
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if i_yx_len[1] < 1 or i_yx_len[2] < 1
  then
    raise exception 'unmatched length!';
  end if;

  return 	
    (
      select
        array_agg(array_x_new)
      from 
      (
        select 
          a_cur_y,
          array_agg(random()) as array_x_new
        from generate_series(1, i_yx_len[1]) tb_a_cur_y(a_cur_y)
          , generate_series(1, i_yx_len[2]) tb_a_cur_x(a_cur_x)
        group by a_cur_y
      ) t_array_x_new
    )
    ;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_rand
--   (
--     array[5, 6]
--   );

-- ------------------------------------------------------------------------

-- drop function if exists sm_sc.fv_new_rand(float, int[2]);
create or replace function sm_sc.fv_new_rand
(
  i_meta_val     float    ,
  i_yx_len       int[2]
)
returns float[]
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  if i_yx_len[1] < 1 or i_yx_len[2] < 1
  then
    raise exception 'unmatched length!';
  end if;

  return 	
    (
      select
        array_agg(array_x_new)
      from 
      (
        select 
          a_cur_y,
          array_agg(i_meta_val * random()) as array_x_new
        from generate_series(1, i_yx_len[1]) tb_a_cur_y(a_cur_y)
          , generate_series(1, i_yx_len[2]) tb_a_cur_x(a_cur_x)
        group by a_cur_y
      ) t_array_x_new
    )
    ;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_rand
--   (
--     12.3,
--     array[5, 6]
--   );
-- ------------------------------------------------------------------------

-- drop function if exists sm_sc.fv_new_rand(numrange, int[2]);
create or replace function sm_sc.fv_new_rand
(
  i_meta_range   numrange    ,
  i_yx_len       int[2]
)
returns float[]
as
$$
declare -- here
  v_meta_val float := upper(i_meta_range) - lower(i_meta_range)   ;

begin
  -- set search_path to sm_sc;
  if i_yx_len[1] < 1 or i_yx_len[2] < 1
  then
    raise exception 'unmatched length!';
  end if;

  

  return 	
    (
      select
        array_agg(array_x_new)
      from 
      (
        select 
          a_cur_y,
          array_agg(lower(i_meta_range) + v_meta_val * random()) as array_x_new
        from generate_series(1, i_yx_len[1]) tb_a_cur_x(a_cur_y)
          , generate_series(1, i_yx_len[2]) tb_a_cur_x(a_cur_x)
        group by a_cur_y
      ) t_array_x_new
    )
    ;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_rand
--   (
--     numrange(1.2, 4.5, '[]'),
--     array[5, 6]
--   );