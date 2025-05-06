-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_lpad_dloss_dindepdt_2(float[], int, int);
create or replace function sm_sc.fv_d_lpad_dloss_dindepdt_2
(
  i_dloss_ddepdt         float[]    ,
  i_indepdt_width        int      ,
  i_times                int        default  1   
)
returns float[]
as
$$
declare 
begin
  -- set search_path to sm_sc;
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_ndims(i_dloss_ddepdt) not between 2 and 4
    then 
      raise exception 'unsupport ndims.';
    end if;
  end if;
  
  if array_ndims(i_dloss_ddepdt) = 2
  then
    return 
    (
      select 
        sm_sc.fa_mx_sum(i_dloss_ddepdt[ : ][i_indepdt_width * (a_cur - 1) + 1 : i_indepdt_width * a_cur])
      from generate_series(1, i_times) tb_a(a_cur)
    );
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    return 
    (
      select 
        sm_sc.fa_mx_sum(i_dloss_ddepdt[ : ][ : ][i_indepdt_width * (a_cur - 1) + 1 : i_indepdt_width * a_cur])
      from generate_series(1, i_times) tb_a(a_cur)
    );
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    return 
    (
      select 
        sm_sc.fa_mx_sum(i_dloss_ddepdt[ : ][ : ][ : ][i_indepdt_width * (a_cur - 1) + 1 : i_indepdt_width * a_cur])
      from generate_series(1, i_times) tb_a(a_cur)
    );
  end if;
end
$$
language plpgsql stable
cost 100;

-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_lpad_dloss_dindepdt_2
--   (
--     array[1, 2, 3, 4, 5, 6],
--     array[7, 8],
--     2
--   );