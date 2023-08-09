-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new_randn(float, int[2]);
create or replace function sm_sc.fv_new_randn
(
  i_meta_val_mean     float    ,
  i_meta_val_stddev   float    ,
  i_yx_len            int[2]
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
      array_agg(v_vec)
    from
    (
      select
        array_agg(v_val::float) as v_vec
      from 
      (
        select  
          (row_number() over() - 1) % i_yx_len[1] as v_num_y,
          v_val
        from normal_rand(i_yx_len[1] * i_yx_len[2], i_meta_val_mean, i_meta_val_stddev) v_val
      ) v_vals
      group by v_num_y
    ) v_x_rows
    limit 1
  )
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_randn
--   (
--     12.3,
--     2.0 :: float,
--     array[5, 6]
--   );