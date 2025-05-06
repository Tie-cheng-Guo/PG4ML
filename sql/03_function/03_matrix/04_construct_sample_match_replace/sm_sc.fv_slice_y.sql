-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_slice_y(anyarray, int4range[]);
create or replace function sm_sc.fv_slice_y
(
  i_arr            anyarray,
  i_slice_range    int4range[]
)
returns anyarray
as
$$
-- declare 
begin
  -- set search_path to sm_sc;
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then 
    if array_length(i_arr, 1) < (select max(upper(a_range)) - 1 from unnest(i_slice_range) tb_a_range(a_range))
      or 1 > (select min(lower(a_range)) from unnest(i_slice_range) tb_a_range(a_range))
    then
      raise exception 'overflow range for 1d len of i_arr.';
    end if;
  end if;
  
  return 
  (
    select 
      sm_sc.fa_mx_concat_y
      (
        i_arr[lower(a_range) : upper(a_range) - 1]
      )
    from unnest(i_slice_range) tb_a_range(a_range)
  );
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select sm_sc.fv_slice_y
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--          ,[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]
--          ,[[[41,42,43,44],[61,62,63,64]],[[45,46,47,48],[65,66,67,68]]]
--          ,[[[51,52,53,54],[71,72,73,74]],[[55,56,57,58],[75,76,77,78]]]
--          ]
--   , array[int4range(1, 3, '[]'), int4range(2, 3, '[]')]
--   );