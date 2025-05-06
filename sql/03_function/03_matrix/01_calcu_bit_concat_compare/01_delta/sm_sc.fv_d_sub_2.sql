-- drop function if exists sm_sc.fv_d_sub_2(int[], int[]);
create or replace function sm_sc.fv_d_sub_2
(
  i_depdt_var_len      int[]
, i_indepdt_var_len    int[]   default null
)
returns float[]
as
$$
declare 
begin
  if i_indepdt_var_len <> i_depdt_var_len
  then 
    return 
      array_fill
      (
        -
        sm_sc.fv_aggr_slice_prod
        (
          i_depdt_var_len 
          / 
          sm_sc.fv_lpad
          (
            i_indepdt_var_len
          , array[1]
          , array_length(i_depdt_var_len, 1) - array_length(i_indepdt_var_len, 1)
          )
        ) :: float
      , i_indepdt_var_len
      )
    ;
  else 
    return array_fill(-1.0 :: float, i_depdt_var_len);
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_sub_2(array[2, 3])
-- select 
--   sm_sc.fv_d_sub_2(array[2, 3, 4])
-- select 
--   sm_sc.fv_d_sub_2(array[2, 3, 4, 5])
-- select 
--   sm_sc.fv_d_sub_2(array[   3, 1, 5], array[2, 3, 4, 5])