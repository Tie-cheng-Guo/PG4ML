-- drop function if exists sm_sc.fv_mx_ele_2d_2_3d(anyarray, int, int, int, boolean);
create or replace function sm_sc.fv_mx_ele_2d_2_3d
(
  i_array_2d               anyarray      
, i_cnt_per_grp            int                  -- 每个切分分组元素个数
, i_dim_from               int                  -- 被拆分维度
, i_dim_new                int                  -- 新生维度
, i_if_dim_pin_ele_on_from boolean              -- 是否在 from 维度保留元素顺序，否则在 new 维度保留元素顺序
)
returns anyarray
as
$$
declare
  v_ret    i_array_2d%type;
  v_cur_y  int     ;
  v_cur_x  int     ;
  v_cur_x3 int     ;
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
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        v_ret := array_fill(i_array_2d[0], array[i_cnt_per_grp, array_length(i_array_2d, 1) / i_cnt_per_grp, array_length(i_array_2d, 2)]);
        for v_cur_x3 in 1 .. array_length(i_array_2d, 2)
        loop 
          for v_cur_x in 1 .. array_length(i_array_2d, 1) / i_cnt_per_grp
          loop 
            v_ret[ : ][v_cur_x : v_cur_x][v_cur_x3 : v_cur_x3]
              := i_array_2d[(v_cur_x - 1) * i_cnt_per_grp + 1 : v_cur_x * i_cnt_per_grp][v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        v_ret := array_fill(i_array_2d[0], array[array_length(i_array_2d, 1) / i_cnt_per_grp, i_cnt_per_grp, array_length(i_array_2d, 2)]);
        for v_cur_x3 in 1 .. array_length(i_array_2d, 2)
        loop 
          for v_cur_y in 1 .. array_length(i_array_2d, 1) / i_cnt_per_grp
          loop 
            v_ret[v_cur_y : v_cur_y][ : ][v_cur_x3 : v_cur_x3]
              := i_array_2d[(v_cur_y - 1) * i_cnt_per_grp + 1 : v_cur_y * i_cnt_per_grp][v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dim_new = 3
    then
      if i_if_dim_pin_ele_on_from
      then 
        v_ret := array_fill(i_array_2d[0], array[i_cnt_per_grp, array_length(i_array_2d, 2), array_length(i_array_2d, 1) / i_cnt_per_grp]);
        for v_cur_x in 1 .. array_length(i_array_2d, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_2d, 1) / i_cnt_per_grp
          loop 
            v_ret[ : ][v_cur_x : v_cur_x][v_cur_x3 : v_cur_x3]
              := i_array_2d[(v_cur_x3 - 1) * i_cnt_per_grp + 1 : v_cur_x3 * i_cnt_per_grp][v_cur_x : v_cur_x]
            ;
          end loop;
        end loop;
      elsif not i_if_dim_pin_ele_on_from
      then 
        v_ret := array_fill(i_array_2d[0], array[array_length(i_array_2d, 1) / i_cnt_per_grp, array_length(i_array_2d, 2), i_cnt_per_grp]);
        for v_cur_x in 1 .. array_length(i_array_2d, 2)
        loop 
          for v_cur_y in 1 .. array_length(i_array_2d, 1) / i_cnt_per_grp
          loop 
            v_ret[v_cur_y : v_cur_y][v_cur_x : v_cur_x][ : ]
              := i_array_2d[(v_cur_y - 1) * i_cnt_per_grp + 1 : v_cur_y * i_cnt_per_grp][v_cur_x : v_cur_x]
            ;
          end loop;
        end loop;
      end if;
    end if;
    return v_ret;
  elsif i_dim_from = 2
  then 
    if i_dim_new = 1
    then
      if i_if_dim_pin_ele_on_from
      then 
        v_ret := array_fill(i_array_2d[0], array[array_length(i_array_2d, 2) / i_cnt_per_grp, array_length(i_array_2d, 1), i_cnt_per_grp]);
        for v_cur_x in 1 .. array_length(i_array_2d, 1)
        loop 
          for v_cur_y in 1 .. array_length(i_array_2d, 2) / i_cnt_per_grp
          loop 
            v_ret[v_cur_y : v_cur_y][v_cur_x : v_cur_x][ : ]
              := i_array_2d[v_cur_x : v_cur_x][(v_cur_y - 1) * i_cnt_per_grp + 1 : v_cur_y * i_cnt_per_grp]
            ;
          end loop;
        end loop;
      elsif not i_if_dim_pin_ele_on_from
      then 
        v_ret := array_fill(i_array_2d[0], array[i_cnt_per_grp, array_length(i_array_2d, 1), array_length(i_array_2d, 2) / i_cnt_per_grp]);
        for v_cur_x in 1 .. array_length(i_array_2d, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_2d, 2) / i_cnt_per_grp
          loop 
            v_ret[ : ][v_cur_x : v_cur_x][v_cur_x3 : v_cur_x3]
              := i_array_2d[v_cur_x : v_cur_x][(v_cur_x3 - 1) * i_cnt_per_grp + 1 : v_cur_x3 * i_cnt_per_grp]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dim_new in (2, 3)
    then
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        v_ret := array_fill(i_array_2d[0], array[array_length(i_array_2d, 1), i_cnt_per_grp, array_length(i_array_2d, 2) / i_cnt_per_grp]);
        for v_cur_y in 1 .. array_length(i_array_2d, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_2d, 2) / i_cnt_per_grp
          loop 
            v_ret[v_cur_y : v_cur_y][ : ][v_cur_x3 : v_cur_x3]
              := i_array_2d[v_cur_y : v_cur_y][(v_cur_x3 - 1) * i_cnt_per_grp + 1 : v_cur_x3 * i_cnt_per_grp]
            ;
          end loop;
        end loop;
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        v_ret := array_fill(i_array_2d[0], array[array_length(i_array_2d, 1), array_length(i_array_2d, 2) / i_cnt_per_grp, i_cnt_per_grp]);
        for v_cur_y in 1 .. array_length(i_array_2d, 1)
        loop 
          for v_cur_x2 in 1 .. array_length(i_array_2d, 2) / i_cnt_per_grp
          loop 
            v_ret[v_cur_y : v_cur_y][v_cur_x2 : v_cur_x2][ : ]
              := i_array_2d[v_cur_y : v_cur_y][(v_cur_x2 - 1) * i_cnt_per_grp + 1 : v_cur_x2 * i_cnt_per_grp]
            ;
          end loop;
        end loop;
      end if;
    end if;
    return v_ret;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;


-- select 
--   sm_sc.fv_mx_ele_2d_2_3d
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
-- , array_dims
--   (
--     sm_sc.fv_mx_ele_2d_2_3d
--     (
--       sm_sc.fv_new_rand(array[6,10])
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     )
--   )
-- from 
--   generate_series(1, 2) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 3) tb_a_dim_new(a_dim_new)
-- , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)
-- order by a_dim_from, a_dim_new, a_dim_pin_ele_on_from