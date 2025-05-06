-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt(float[], float[], float[]);
create or replace function sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt
(
  i_depdt                  float[]                  ,                     -- zscore 输出
  i_dloss_ddepdt           float[]                  ,                     -- 此入参传入 dloss/dindepdt, 用于 zscore 直接求取 dloss/ddepdt
  i_indepdt                  float[]                                        -- zscore 算子的输入，来自上一层算子的输出
)
returns float[]     -- 输出列序与 i_indepdt 枚举值 one_hot 序一致
as
$$
declare 
  v_y_length_1d   int   :=  array_length(i_depdt, 1);
begin
  -- 审计维度
  if array_ndims(i_indepdt) <> 2
    or array_ndims(i_depdt) <> 2
  then 
    raise exception 'array_ndims should be 2';
  end if;

  if i_depdt is null
  then
    i_depdt := sm_sc.fv_standlize_mx_zscore(i_indepdt);
  end if;
  
  return
    sm_sc.fv_mx_ele_1d_2_2d
    (
      sm_sc.fv_d_standlize_zscore_dloss_dindepdt
      (
        array[sm_sc.fv_mx_ele_2d_2_1d(i_depdt)], 
        array[sm_sc.fv_mx_ele_2d_2_1d(i_dloss_ddepdt)],
        array[sm_sc.fv_mx_ele_2d_2_1d(i_indepdt)]
      )
      , v_y_length_1d
    ) 
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_zscore(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]),
--     (-` array[array[0.0 :: float, 1.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[0.0 :: float, 0.0], array[1.0 :: float, 0.0]] /` sm_sc.fv_standlize_mx_zscore(array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]])),
--     array[array[1, 5], array[2, 4], array[3, 3], array[4, 2], array[5, 1]]
--   );

-- ------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt(float[], float[], float[], int[2]);
create or replace function sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt
(
  i_depdt                  float[]                  ,                     -- zscore 输出
  i_dloss_ddepdt           float[]                  ,                     -- 此入参传入 dloss/dindepdt, 用于 zscore 直接求取 dloss/ddepdt
  i_indepdt                  float[]                  ,                     -- zscore 算子的输入，来自上一层算子的输出
  i_cnt_per_grp    int[]
)
returns float[]
as
$$
-- declare 
begin
  if array_length(i_dloss_ddepdt, 1) % i_cnt_per_grp[1] <> 0 
    or i_cnt_per_grp[1] <= 0
  then 
    raise exception 'imperfect length_1 of i_dloss_ddepdt of this cnt_per_grp';
  elsif array_length(i_dloss_ddepdt, 2) % i_cnt_per_grp[2] <> 0 
    or i_cnt_per_grp[2] <= 0
  then 
    raise exception 'imperfect length_2 of i_dloss_ddepdt of this cnt_per_grp';
  end if;
  
  return 
  (
    with
    cte_slice_x as 
    (
      select 
        a_cur_y,
        sm_sc.fa_mx_concat_x
        (
          sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt
          (
            i_depdt[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]             ,
            i_dloss_ddepdt[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]      ,
            i_indepdt[a_cur_y : a_cur_y + i_cnt_per_grp[1] - 1][a_cur_x : a_cur_x + i_cnt_per_grp[2] - 1]            
          ) 
          order by a_cur_x
        ) as a_slice_x
      from generate_series(1, array_length(i_dloss_ddepdt, 1), i_cnt_per_grp[1]) tb_a_cur_y(a_cur_y)
        , generate_series(1, array_length(i_dloss_ddepdt, 2), i_cnt_per_grp[2]) tb_a_cur_x(a_cur_x)
      group by a_cur_y
    )
    select 
      sm_sc.fa_mx_concat_y(a_slice_x order by a_cur_y)
    from cte_slice_x
  )
  ;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select 
--   sm_sc.fv_d_standlize_mx_zscore_dloss_dindepdt
--   (
--     sm_sc.fv_standlize_mx_zscore
--     (
--       array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--            ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--            ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--            ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]],
--      array[2, 3]
--     ),
--     array[[0.3, 0.1, 0.2, 0.56, 0.33, -0.9]
--          ,[0.25, 0.4, 0.6, 0.4, -0.65, -0.6]
--          ,[0.25, 0.4, -0.6, 0.4, -0.65, 0.6]
--          ,[0.25, 0.4, 0.6, 0.4, -0.65, 0.6]], 
--     array[[2.3, 5.1, 8.2, 2.56, 3.33, -1.9]
--          ,[3.25, 6.4, 6.6, 6.9, -2.65, -4.6]
--          ,[-2.3, 5.1, -8.2, 2.56, -3.33, -1.9]
--          ,[3.25, -6.4, -6.6, 6.9, -2.65, -4.6]], 
--     array[2, 3]
--   ) :: decimal[] ~=` 6
