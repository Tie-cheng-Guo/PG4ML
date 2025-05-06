-- drop function if exists sm_sc.fv_mx_ele_2d_2_3d_py(float[], int, int, int, boolean);
create or replace function sm_sc.fv_mx_ele_2d_2_3d_py
(
  i_array_2d               float[]      
, i_cnt_per_grp            int                  -- 每个切分分组元素个数
, i_dim_from               int                  -- 被拆分维度
, i_dim_new                int                  -- 新生维度
, i_if_dim_pin_ele_on_from boolean              -- 是否在 from 维度保留元素顺序，否则在 new 维度保留元素顺序
)
returns float[]
as
$$
-- declare
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array_2d) <> 2
    then 
      raise exception 'ndims should be 2.';
    end if;
    
    if array_length(i_array_2d, i_dim_from) % i_cnt_per_grp > 0
      or i_cnt_per_grp not between 1 and array_length(i_array_2d, i_dim_from)
    then 
      raise exception 'unperfect such i_cnt_per_grp.';
    end if;
    
    if i_dim_new not between 1 and 3
    then 
      raise exception 'unsupport such i_dim_new.';
    end if;
  end if;
 
  if i_array_2d is null 
  then 
    return null;
  elsif i_dim_from = 1
  then 
    if i_dim_new in (1, 2)
    then
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from      -- i_dim_new = 2
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from -- i_dim_new = 1
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1) / i_cnt_per_grp, i_cnt_per_grp, array_length(i_array_2d, 2)]
          )
          |^~| array[1, 2]
        ;
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1) / i_cnt_per_grp, i_cnt_per_grp, array_length(i_array_2d, 2)]
          )
        ;
      end if;
    elsif i_dim_new = 3
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d |^~| array[1, 2]
          , array[array_length(i_array_2d, 2), array_length(i_array_2d, 1) / i_cnt_per_grp, i_cnt_per_grp]
          )
          |^~| array[3, 2] |^~| array[2, 1]
        ;
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1) / i_cnt_per_grp, i_cnt_per_grp, array_length(i_array_2d, 2)]
          )
          |^~| array[3, 2]
        ;
      end if;
    end if;
  elsif i_dim_from = 2
  then 
    if i_dim_new = 1
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1), array_length(i_array_2d, 2) / i_cnt_per_grp, i_cnt_per_grp]
          )
          |^~| array[1, 2]
        ;
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1), array_length(i_array_2d, 2) / i_cnt_per_grp, i_cnt_per_grp]
          )
          |^~| array[2, 3] |^~| array[1, 2]
        ;
      end if;
    elsif i_dim_new in (2, 3)
    then
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from      -- i_dim_new = 3
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from -- i_dim_new = 2
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1), array_length(i_array_2d, 2) / i_cnt_per_grp, i_cnt_per_grp]
          )
          |^~| array[2, 3]
        ;
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from -- i_dim_new = 3
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from       -- i_dim_new = 2
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_2d
          , array[array_length(i_array_2d, 1), array_length(i_array_2d, 2) / i_cnt_per_grp, i_cnt_per_grp]
          )
        ;
      end if;
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;


-- select 
--   sm_sc.fv_mx_ele_2d_2_3d_py
--   (
--     array
--     [[1,2,3,4,5,6],[11,12,13,14,15,16],[21,22,23,24,25,26],[31,32,33,34,35,36]]
--   , 2
--   , 2   -- a_dim_from
--   , 1   -- a_dim_new
--   , true   -- a_dim_pin_ele_on_from
--   )
-- from 
--   generate_series(1, 2) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 3) tb_a_dim_new(a_dim_new)
-- , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)

-- select 
--   a_dim_from
-- , a_dim_new
-- , a_dim_pin_ele_on_from
-- , -- array_dims(
--     sm_sc.fv_mx_ele_2d_2_3d_py
--     (
--       a_arr
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     )
--   -- )
-- = -- array_dims(
--     sm_sc.fv_mx_ele_2d_2_3d
--     (
--       a_arr
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     )
--   -- )
-- , sm_sc.fv_mx_ele_2d_2_3d_py
--     (
--       a_arr
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     )
-- , sm_sc.fv_mx_ele_2d_2_3d
--     (
--       a_arr
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     )
-- from 
--   (select 
--       array 
--       [[ 0, 1, 2, 3, 4, 5]
--       ,[ 6, 7, 8, 9,10,11]
--       ,[12,13,14,15,16,17]
--       ,[18,19,20,21,22,23]
--       ,[24,25,26,27,28,29]
--       ,[30,31,32,33,34,35]] :: float[] as a_arr
--   ) tb_a_arr
-- , generate_series(1, 2) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 3) tb_a_dim_new(a_dim_new)
-- , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)
-- order by a_dim_from, a_dim_new, a_dim_pin_ele_on_from
