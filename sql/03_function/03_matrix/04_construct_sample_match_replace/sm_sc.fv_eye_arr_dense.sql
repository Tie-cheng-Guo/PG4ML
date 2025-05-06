-- -------------------------------------------------------------------------------------------------------------------------
-- -- -- -- 以下部分为对 float 元素类型的支持，对于其他类型，需额外定义多态类型
-- -- -- drop type if exists sm_sc.__typ_array_ex;
-- -- create type sm_sc.__typ_array_ex 
-- -- as
-- -- (
-- --   m_array    float[]
-- -- );
-- ---------------------------
-- -- drop function if exists sm_sc.fv_cast_array_ex;
-- create or replace function sm_sc.fv_cast_array_ex 
-- (
--   i_array     float[]    
-- )
-- returns sm_sc.__typ_array_ex
-- as
-- $$
-- declare -- here
--   v_rtn     sm_sc.__typ_array_ex;
-- begin
--   v_rtn.m_array = i_array;
--   return v_rtn;
-- end
-- $$
-- language plpgsql stable
-- parallel safe
-- cost 100;
-- -- select sm_sc.fv_cast_array_ex(array[1.2, 2.4])
-- -- select sm_sc.fv_cast_array_ex(array[array[1.2, 2.4], array[3.6, 4.8]])
-- -- ---------------------------
-- drop cast if exists (float[] as sm_sc.__typ_array_ex);
-- create cast (float[] as sm_sc.__typ_array_ex)   
-- with function sm_sc.fv_cast_array_ex(float[])
-- as implicit;

-- ---------------------------
-- drop function if exists sm_sc.fv_eye_arr_dense(variadic sm_sc.__typ_array_ex[]);
create or replace function sm_sc.fv_eye_arr_dense
(
  i_fill_idle_value float,
  variadic i_arrays sm_sc.__typ_array_ex[]   -- 可以不是方阵
)
  returns float[]
as
$$
declare -- here
  v_ret_arr        float[];
  v_cur_pos        int    :=  1;
  v_cur_arr        sm_sc.__typ_array_ex;
  v_cur_y          int;
  v_cur_x          int;
  v_ret_len_y      int;
  v_ret_len_x      int;
begin
  if exists (select  from generate_subscripts(i_arrays, 1) tb(col_cur) where array_ndims(i_arrays[col_cur].m_array) <> 2) 
  then
    raise exception 'no method for such ndim!';
  else

    -- 计算结果矩阵的长宽
    -- v_ret_len = (select sum(least(array_length(i_arrays[col_cur].m_array, 1), array_length(i_arrays[col_cur].m_array, 2))) from generate_subscripts(i_arrays, 1) tb(col_cur));
    -- raise notice  'v_ret_len: %', v_ret_len;

    with 
    -- 形状列表
    cte_shape as
    (
      select 
        col_cur
      , array_length(i_arrays[col_cur].m_array, 1) as len_y
      , array_length(i_arrays[col_cur].m_array, 2) as len_x 
      from generate_subscripts(i_arrays, 1) tb(col_cur)
    ),
    -- 每一层方阵大小
    cte_cur_squar as
    (
      select 
        col_cur
      , sum(least(len_y, len_x)) over(order by col_cur) as cur_squar 
      from cte_shape
    ),
    -- 每一层方阵右下角作为下一层起点
    cte_cur_start_pos as
    (
      select 
        col_cur
      , (lag(cur_squar :: int, 1, 0) over(order by col_cur)) + 1 as cur_start_pos 
      from cte_cur_squar
    ),
    -- 本层右下角 yx 坐标
    cte_cur_end_pos as
    (
      select 
        col_cur
      , cur_start_pos + array_length(i_arrays[col_cur].m_array, 1) - 1 as cur_end_pos_y
      , cur_start_pos + array_length(i_arrays[col_cur].m_array, 2) - 1 as cur_end_pos_x 
      from cte_cur_start_pos
    )
    -- 所有层坐标的最大值即返回结果矩阵的形状
    select 
      max(cur_end_pos_y), max(cur_end_pos_x) 
    into v_ret_len_y, v_ret_len_x
    from cte_cur_end_pos;

    -- 以背景元素值初始化矩阵
    v_ret_arr = array_fill(i_fill_idle_value, array[v_ret_len_y, v_ret_len_x]);

    -- 修改对角线
    foreach v_cur_arr in array i_arrays
    loop
      -- pg 13 不支持数组变量切块（二维切片）赋值的语法，也尚未支持(select [][] into [..:..][..:..])语法  -- pg 14 开始支持数组变量切块（二维切片）赋值的语法
      v_ret_arr[v_cur_pos : v_cur_pos + array_length(v_cur_arr.m_array, 1) - 1]
             [v_cur_pos : v_cur_pos + array_length(v_cur_arr.m_array, 2) - 1]
        = v_cur_arr.m_array;
      -- -- for v_cur_y in 0 .. array_length(v_cur_arr.m_array, 1) - 1 by 1
      -- -- loop
      -- --   for v_cur_x in 0 .. array_length(v_cur_arr.m_array, 2) - 1 by 1
      -- --   loop
      -- --     v_ret_arr[v_cur_pos + v_cur_y]
      -- --                [v_cur_pos + v_cur_x] 
      -- --       = v_cur_arr.m_array[v_cur_y + 1]
      -- --                             [v_cur_x + 1];
      -- --   end loop;
      -- -- end loop;

      v_cur_pos = v_cur_pos + least(array_length(v_cur_arr.m_array, 1), array_length(v_cur_arr.m_array, 2));
    end loop;

    return v_ret_arr;
  end if;

end
$$
  language plpgsql stable
parallel safe
  cost 100;
-- select sm_sc.fv_eye_arr_dense(0.5, array[[1, 1], [1, 1.0]] :: float[], array[[2, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 2]] :: float[], array[[3, 3, 3], [3, 3, 3], [3, 3, 3]] :: float[])
-- select sm_sc.fv_eye_arr_dense(0.8, array[[1.2, 2.4], [11.2, 12.4]] :: float[], array[[1.3, 2.6, 1.4, 2.8], [11.3, 12.6, 11.4, 12.8]] :: float[], array[[1.1, 2.2], [11.1, 12.2], [21.1, 22.2]] :: float[])
-- ---------------------------
-- drop function if exists sm_sc.fv_eye_arr_dense(variadic sm_sc.__typ_array_ex[]);
create or replace function sm_sc.fv_eye_arr_dense
(
  variadic i_arrays sm_sc.__typ_array_ex[]   -- 可以不是方阵
)
  returns float[]
as
$$
-- declare -- here
begin
  return sm_sc.fv_eye_arr_dense(0.0 :: float, variadic i_arrays);
end
$$
  language plpgsql stable
parallel safe
  cost 100;
-- select sm_sc.fv_eye_arr_dense(array[[1.0, 1], [1, 1]] :: float[], array[[2.0, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 2], [2, 2, 2, 2]] :: float[], array[[3.0, 3, 3], [3, 3, 3], [3, 3, 3]] :: float[])
-- select sm_sc.fv_eye_arr_dense(array[[1.2, 2.4], [11.2, 12.4]] :: float[], array[[1.3, 2.6, 1.4, 2.8], [11.3, 12.6, 11.4, 12.8]] :: float[], array[[1.1, 2.2], [11.1, 12.2], [21.1, 22.2]] :: float[])