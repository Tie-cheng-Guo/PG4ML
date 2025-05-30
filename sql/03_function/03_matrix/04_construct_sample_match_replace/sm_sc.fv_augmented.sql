-- drop function if exists sm_sc.fv_augmented(anyarray, int[2], int[2], anyelement);
create or replace function sm_sc.fv_augmented
(
  in i_arr                 anyarray, 
  in i_begin_pos           int[2],   -- 允许为负数
  in i_end_pos             int[2],   -- 不小于 begin_pos
  in i_augmented_val       anyelement   default null
)
  returns anyarray
as
$$
declare -- here
  v_arr_len_heigh      int          :=   array_length(i_arr, array_ndims(i_arr) - 1)    ;
  v_arr_len_width      int          :=   array_length(i_arr, array_ndims(i_arr))        ;
  v_range_arr_heigh    int4range    :=   int4range(1, v_arr_len_heigh + 1, '[)')            ;
  v_range_arr_width    int4range    :=   int4range(1, v_arr_len_width + 1, '[)')            ;
  v_range_tar_heigh    int4range    :=   int4range(i_begin_pos[1], i_end_pos[1] + 1, '[)')  ;
  v_range_tar_width    int4range    :=   int4range(i_begin_pos[2], i_end_pos[2] + 1, '[)')  ;
  v_range_shadow_heigh int4range    :=   v_range_arr_heigh * v_range_tar_heigh          ;
  v_range_shadow_width int4range    :=   v_range_arr_width * v_range_tar_width          ;
  v_ret                i_arr%type   ;
  -- -- v_cur_y          int;
  -- -- v_cur_x          int;

begin
  if array_ndims(i_arr) = 2
  then
    if not (isempty(v_range_shadow_heigh) or isempty(v_range_shadow_heigh))
    then
      -- -- pg 13 不支持数组变量切块（二维切片）赋值的语法，也尚未支持(select [][] into [..:..][..:..])语法  -- pg 14 开始支持数组变量切块（二维切片）赋值的语法
      v_ret := sm_sc.fv_new(i_augmented_val, array[i_end_pos[1] - i_begin_pos[1] + 1, i_end_pos[2] - i_begin_pos[2] + 1]);
      
      v_ret[greatest(1, 1 - i_begin_pos[1] + 1) : least(i_end_pos[1], v_arr_len_heigh) - i_begin_pos[1] + 1]
           [greatest(1, 1 - i_begin_pos[2] + 1) : least(i_end_pos[2], v_arr_len_width) - i_begin_pos[2] + 1]  
        := i_arr[lower(v_range_shadow_heigh) : upper(v_range_shadow_heigh) - 1]
                [lower(v_range_shadow_width) : upper(v_range_shadow_width) - 1];

      -- -- -- -- 使用临时表是pg11的临时方案，有代价：消耗表描述符，消耗oid，多了一次堆栈调用，至少多一次复制；期待未来pg版本对数组变量切块（二维切片）赋值的语法支持。
      -- -- create temp table t_tmp(col_tmp anyarray);
      -- -- insert into t_tmp(col_tmp) select v_ret;
      -- -- 
      -- -- update t_tmp
      -- -- set col_tmp[greatest(1, 1 - i_begin_pos[1] + 1) : least(i_end_pos[1], v_arr_len_heigh) - i_begin_pos[1] + 1]
      -- --            [greatest(1, 1 - i_begin_pos[2] + 1) : least(i_end_pos[2], v_arr_len_width) - i_begin_pos[2] + 1] 
      -- --   = i_arr[lower(v_range_shadow_heigh) : upper(v_range_shadow_heigh) - 1]
      -- --          [lower(v_range_shadow_width) : upper(v_range_shadow_width) - 1];
      -- -- v_ret := (select col_tmp from t_tmp limit 1);
      -- -- drop table if exists t_tmp;
      -- -- -- -- 

      -- for v_cur_y in 0 .. upper(v_range_shadow_heigh) - lower(v_range_shadow_heigh) - 1 by 1
      -- loop
      --   for v_cur_x in 0 .. upper(v_range_shadow_width) - lower(v_range_shadow_width) - 1 by 1
      --   loop
      --     v_ret[greatest(1, 1 - i_begin_pos[1] + 1) + v_cur_y]
      --                [greatest(1, 1 - i_begin_pos[2] + 1) + v_cur_x] 
      --       = i_arr[lower(v_range_shadow_heigh) + v_cur_y]
      --              [lower(v_range_shadow_width) + v_cur_x];
      --   end loop;
      -- end loop;

    end if;
    return v_ret;
  elsif array_ndims(i_arr) = 3
  then
    if not (isempty(v_range_shadow_heigh) or isempty(v_range_shadow_heigh))
    then
      v_ret := sm_sc.fv_new(i_augmented_val, array[array_length(i_arr, 1), i_end_pos[1] - i_begin_pos[1] + 1, i_end_pos[2] - i_begin_pos[2] + 1]);
      
      v_ret[ : ]
           [greatest(1, 1 - i_begin_pos[1] + 1) : least(i_end_pos[1], v_arr_len_heigh) - i_begin_pos[1] + 1]
           [greatest(1, 1 - i_begin_pos[2] + 1) : least(i_end_pos[2], v_arr_len_width) - i_begin_pos[2] + 1]  
        := i_arr[ : ]
                [lower(v_range_shadow_heigh) : upper(v_range_shadow_heigh) - 1]
                [lower(v_range_shadow_width) : upper(v_range_shadow_width) - 1];
    end if;
    return v_ret;
  elsif array_ndims(i_arr) = 4
  then
    if not (isempty(v_range_shadow_heigh) or isempty(v_range_shadow_heigh))
    then
      v_ret := sm_sc.fv_new(i_augmented_val, array[array_length(i_arr, 1), array_length(i_arr, 2), i_end_pos[1] - i_begin_pos[1] + 1, i_end_pos[2] - i_begin_pos[2] + 1]);
      
      v_ret[ : ]
           [ : ]
           [greatest(1, 1 - i_begin_pos[1] + 1) : least(i_end_pos[1], v_arr_len_heigh) - i_begin_pos[1] + 1]
           [greatest(1, 1 - i_begin_pos[2] + 1) : least(i_end_pos[2], v_arr_len_width) - i_begin_pos[2] + 1]  
        := i_arr[ : ]
                [ : ]
                [lower(v_range_shadow_heigh) : upper(v_range_shadow_heigh) - 1]
                [lower(v_range_shadow_width) : upper(v_range_shadow_width) - 1];
    end if;
    return v_ret;
  else
    raise exception 'no method for such range!';
  end if;
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- -- 子集
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, 2], array[4, 4], 0)
-- -- 超集
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, -1], array[8, 8], 0)

-- -- 左上相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, -1], array[4, 4], 0)
-- -- 右下相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, 2], array[8, 8], 0)

-- -- 正上相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, 2], array[4, 4], 0)
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, -1], array[4, 8], 0)
-- -- 正下相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, 2], array[8, 4], 0)
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, -1], array[8, 8], 0)

-- -- 正左相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, -1], array[4, 4], 0)
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, 2], array[8, 8], 0)
-- -- 正右相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, 2], array[4, 8], 0)
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, -1], array[8, 8], 0)

-- -- 左下相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[2, -1], array[8, 4], 0)
-- -- 右上相交
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, 2], array[4, 8], 0)

-- -- 左上相离
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, -1], array[0, 0], 0)
-- -- 右下相离
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[8, 8], array[10, 10], 0)

-- -- 左下相离
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[8, -1], array[10, 2], 0)
-- -- 右上相离
-- select sm_sc.fv_augmented(array[array[1, 2, 3, 4, 5], array[6, 7, 8, 9, 10], array[11, 12, 13, 14, 15], array[16, 17, 18, 19, 20], array[21, 22, 23, 24, 25]], array[-1, 8], array[2, 10], 0)

-- -- 左上相交 3d 延拓
-- select sm_sc.fv_augmented(array[[[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21, 22, 23, 24, 25]], [[-1, -2, -3, -4, -5], [-6, -7, -8, -9, -10], [-11, -12, -13, -14, -15], [-16, -17, -18, -19, -20], [-21, -22, -23, -24, -25]]], array[-1, -1], array[4, 4], 0)

-- -- 左上相交 4d 延拓
-- select sm_sc.fv_augmented(array[[[[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21, 22, 23, 24, 25]], [[-1, -2, -3, -4, -5], [-6, -7, -8, -9, -10], [-11, -12, -13, -14, -15], [-16, -17, -18, -19, -20], [-21, -22, -23, -24, -25]]], [[[31, 32, 33, 34, 35], [36, 37, 38, 39, 40], [41, 42, 43, 44, 45], [46, 47, 48, 49, 50], [51, 52, 53, 54, 55]], [[-31, -32, -33, -34, -35], [-36, -37, -38, -39, -40], [-41, -42, -43, -44, -45], [-46, -47, -48, -49, -50], [-51, -52, -53, -54, -55]]]], array[-1, -1], array[4, 4], 0)