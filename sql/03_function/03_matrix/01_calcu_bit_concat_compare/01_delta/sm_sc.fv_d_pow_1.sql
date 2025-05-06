-- drop function if exists sm_sc.fv_d_pow_1(float[], float[], float[]);
create or replace function sm_sc.fv_d_pow_1
(
  i_indepdt_var float[] , 
  i_co_value    float[] ,
  i_depdt_var   float[] default null
)
returns float[]
as
$$
declare 
  v_ret               float[]    ;
  v_depdt_var_len     int[]      ;
  v_indepdt_var_len   int[]      :=
    (
      select 
        array_agg(array_length(i_indepdt_var, a_dim_cur) order by a_dim_cur)
      from generate_series(1, array_ndims(i_indepdt_var)) tb_a_dim_cur(a_dim_cur)
    )
  ;
begin
  v_ret           :=  
    case 
      when i_depdt_var is not null 
        then i_co_value *` i_depdt_var /` i_indepdt_var      -- -- sm_sc.fv_nullif(... , 0.0 :: float)
      else i_co_value *` (i_indepdt_var ^` (i_co_value -` 1.0 :: float)) 
    end      -- 优先使用 i_depdt_var
  ;
  
  v_depdt_var_len := 
    (
      select 
        array_agg(array_length(v_ret, a_dim_cur) order by a_dim_cur)
      from generate_series(1, array_ndims(v_ret)) tb_a_dim_cur(a_dim_cur)
    )
  ;

  -- 由因变量对齐至自变量
  if v_indepdt_var_len <> v_depdt_var_len
  then 
    -- 规格对齐
    v_ret := 
      sm_sc.fv_aggr_slice_sum
      (
        v_ret
      , v_depdt_var_len 
        / 
        sm_sc.fv_lpad
        (
          v_indepdt_var_len
        , array[1]
        , array_length(v_depdt_var_len, 1) - array_length(v_indepdt_var_len, 1)
        )
      );
    
    -- 维度对齐
    if array_length(v_indepdt_var_len, 1) < array_length(v_depdt_var_len, 1)
    then 
      if array_length(v_depdt_var_len, 1) = 2 and array_length(v_indepdt_var_len, 1) = 1
      then 
        v_ret := sm_sc.fv_mx_ele_2d_2_1d(v_ret);
      elsif array_length(v_depdt_var_len, 1) = 3 and array_length(v_indepdt_var_len, 1) = 2
      then 
        v_ret := sm_sc.fv_mx_slice_3d_2_2d(v_ret[1][ : ][ : ], 1);
      elsif array_length(v_depdt_var_len, 1) = 4 and array_length(v_indepdt_var_len, 1) = 2
      then 
        v_ret := sm_sc.fv_mx_slice_4d_2_2d(v_ret[1][1][ : ][ : ], array[1, 2], array[1, 1]);
      elsif array_length(v_depdt_var_len, 1) = 4 and array_length(v_indepdt_var_len, 1) = 3
      then 
        v_ret := sm_sc.fv_mx_slice_4d_2_3d(v_ret[1][ : ][ : ][ : ], 1);
      end if;
    end if;
  end if;
  
  return v_ret;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_pow_1(array[2.8, 3.6]
--                  , array[1.8, 4.6])
-- select 
--   sm_sc.fv_d_pow_1(array[[2.8, 3.6], [2.4, 1.6]]
--                  , array[[1.8, 4.6], [1.4, 3.6]])
-- select 
--   sm_sc.fv_d_pow_1(array[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]]
--                  , array[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]])
-- select 
--   sm_sc.fv_d_pow_1(array[[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]],[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]]]
--                  , array[[[[1.8, 4.6], [1.4, 3.6]],[[2.8, 3.6], [2.4, 1.6]]],[[[2.8, 3.6], [2.4, 1.6]],[[1.8, 4.6], [1.4, 3.6]]]])

-- select 
--   sm_sc.fv_d_pow_1
--   (
--     array[[2.8, 3.6], [2.4, 1.6]], 
--     array[[1.8, -4.6], [1.4, 3.6]],
--     array[[2.8, 3.6], [2.4, 1.6]] ^` array[[1.8, -4.6], [1.4, 3.6]]
--   )

-- select 
--   sm_sc.fv_d_pow_1(sm_sc.fv_new_rand(array[2, 1, 3]), sm_sc.fv_new_rand(array[3, 3]))
-- select 
--   sm_sc.fv_d_pow_1(sm_sc.fv_new_rand(array[3, 3]), sm_sc.fv_new_rand(array[2, 1, 3]))
-- select 
--   sm_sc.fv_d_pow_1(sm_sc.fv_new_rand(array[2, 1, 3, 5]), sm_sc.fv_new_rand(array[3, 3, 5]))
-- select 
--   sm_sc.fv_d_pow_1(sm_sc.fv_new_rand(array[3, 3, 5]), sm_sc.fv_new_rand(array[2, 1, 3, 5]))
-- select 
--   sm_sc.fv_d_pow_1(sm_sc.fv_new_rand(array[4, 2, 1, 3]), sm_sc.fv_new_rand(array[3, 3]))
-- select 
--   sm_sc.fv_d_pow_1(sm_sc.fv_new_rand(array[3, 3]), sm_sc.fv_new_rand(array[4, 2, 1, 3]))
