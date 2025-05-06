-- drop function if exists sm_sc.fv_d_mul(float[], int[]);
create or replace function sm_sc.fv_d_mul
(
  i_co_value           float[] 
, i_indepdt_var_len    int[]  default null
)
returns float[]
as
$$
declare 
  v_co_var_len      int[]  := (select array_agg(array_length(i_co_value, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_co_value)) tb_a_cur_dim(a_cur_dim));
  v_depdt_var_len   int[]  :=  
    (
      select 
        sm_sc.__fv_mirror_y(array_agg(greatest(a_indepdt_var_len, a_co_len)))
      from unnest(sm_sc.__fv_mirror_y(i_indepdt_var_len), sm_sc.__fv_mirror_y(v_co_var_len)) tb_a_len(a_indepdt_var_len, a_co_len)
    )
  ;
  v_ret         float[];
begin
  -- 求导
  v_ret := i_co_value;
  
  -- 求导结果对齐维度至因变量
  if array_length(v_depdt_var_len, 1) - array_length(v_co_var_len, 1) = 3
  then 
    v_ret := array[[[v_ret]]];
  elsif array_length(v_depdt_var_len, 1) - array_length(v_co_var_len, 1) = 2
  then 
    v_ret := array[[v_ret]];
  elsif array_length(v_depdt_var_len, 1) - array_length(v_co_var_len, 1) = 1
  then 
    v_ret := array[v_ret];
  end if;
  
  -- 由协参规格对齐至因变量
  if v_co_var_len <> v_depdt_var_len
  then 
    -- 维度对齐
    if array_length(v_co_var_len, 1) < array_length(v_depdt_var_len, 1)
    then 
      v_co_var_len := 
        sm_sc.fv_lpad
        (
          v_co_var_len
        , array[1]
        , array_length(v_depdt_var_len, 1) - array_length(v_co_var_len, 1)
        );
    end if;
    
    -- 规格对齐
    v_ret := sm_sc.fv_new(v_ret, v_depdt_var_len / v_co_var_len);
  end if;
  
  -- 由因变量对齐至自变量
  if i_indepdt_var_len <> v_depdt_var_len
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
          i_indepdt_var_len
        , array[1]
        , array_length(v_depdt_var_len, 1) - array_length(i_indepdt_var_len, 1)
        )
      );
    
    -- 维度对齐
    if array_length(i_indepdt_var_len, 1) < array_length(v_depdt_var_len, 1)
    then 
      if array_length(v_depdt_var_len, 1) = 2 and array_length(i_indepdt_var_len, 1) = 1
      then 
        v_ret := sm_sc.fv_mx_ele_2d_2_1d(v_ret);
      elsif array_length(v_depdt_var_len, 1) = 3 and array_length(i_indepdt_var_len, 1) = 2
      then 
        v_ret := sm_sc.fv_mx_slice_3d_2_2d(v_ret[1][ : ][ : ], 1);
      elsif array_length(v_depdt_var_len, 1) = 4 and array_length(i_indepdt_var_len, 1) = 2
      then 
        v_ret := sm_sc.fv_mx_slice_4d_2_2d(v_ret[1][ : ][ : ], array[1, 1]);
      elsif array_length(v_depdt_var_len, 1) = 4 and array_length(i_indepdt_var_len, 1) = 3
      then 
        v_ret := sm_sc.fv_mx_slice_4d_2_3d(v_ret[1][ : ][ : ], 1);
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
--   sm_sc.fv_d_mul(array[2.4, -1.6])
-- select 
--   sm_sc.fv_d_mul(array[[2.8, 3.6], [2.4, -1.6]])
-- select 
--   sm_sc.fv_d_mul(array[[[2.8, 3.6], [2.4, -1.6]],[[2.8, 3.6], [2.4, -1.6]]])
-- select 
--   sm_sc.fv_d_mul(array[[[[2.8, 3.6], [2.4, -1.6]],[[2.8, 3.6], [2.4, -1.6]]],[[[2.8, 3.6], [2.4, -1.6]],[[2.8, 3.6], [2.4, -1.6]]]])
-- select 
--   sm_sc.fv_d_mul(sm_sc.fv_new_rand(array[2, 1, 3]), array[3, 3])
-- select 
--   sm_sc.fv_d_mul(sm_sc.fv_new_rand(array[3, 3]), array[2, 1, 3])