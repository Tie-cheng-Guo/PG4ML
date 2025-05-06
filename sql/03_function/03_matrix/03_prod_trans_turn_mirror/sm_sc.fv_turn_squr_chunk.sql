-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_turn_squr_chunk(anyarray, int8range[], int[2], varchar(8));
create or replace function sm_sc.fv_turn_squr_chunk
(
  i_arr            anyarray
, i_chunk_pos      int8range[]
, i_turn_dims      int[2]
, i_turn_angle     varchar(8)          -- 旋转角度，枚举: '90', '180', '270'.  规约旋转方向描述为从 i_turn_dims[1] 正半轴方向 到 i_turn_dims[2] 正半轴方向
)
returns anyarray
as
$$
declare 
  v_ndims   int   := array_length(i_chunk_pos, 1);
begin
  -- set search_path to sm_sc;
  -- 审计维度、长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_arr) not between 2 and 4
    then
      raise exception 'unsupport ndims: %.', array_ndims(i_arr);
    elsif v_ndims <> array_ndims(i_arr)
    then 
      raise exception 'unmatch length of i_chunk_pos: %.', v_ndims;
    elsif exists(select  from generate_series(1, v_ndims) tb_a(a_no) 
                 where lower(i_chunk_pos[a_no]) <= 0 or upper(i_chunk_pos[a_no]) > array_length(i_arr, a_no))
    then 
      raise exception 'overflow length of i_chunk_pos.';
    elsif i_turn_dims[1] = i_turn_dims[2]
      or exists(select  from unnest(i_turn_dims) tb_a(a_dim) where a_dim not between 1 and array_ndims(i_arr))
    then 
      raise exception 'unsupport turn_dims.';
    elsif i_turn_angle not in ('90', '180', '270')
    then 
      raise exception 'unsupport turn_angle.';
    end if;
  end if;
  
  -- 调整优直角为负直角
  if i_turn_angle = '270'
  then 
    i_turn_dims := i_turn_dims[2 : 2] || i_turn_dims[1 : 1];
    i_turn_angle := '90';
  end if;
  
  -- 填充 i_chunk_pos 空值的默认值
  i_chunk_pos :=
    (
      select 
        array_agg
        (
          int8range
          (
            coalesce(lower(i_chunk_pos[a_no]), 1)
          , coalesce(upper(i_chunk_pos[a_no]), array_length(i_arr, a_no) + 1)
          ) 
          order by a_no
        ) 
      from generate_series(1, v_ndims) tb_a(a_no)
    )
  ;
  
  -- 旋转切片
  if i_turn_angle = '180'
  then 
    i_turn_dims := (select array_agg(a_ele order by a_ele) from unnest(i_turn_dims) tb_a(a_ele));
    if i_turn_dims = array[1, 2]
    then 
      if v_ndims = 2
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1] 
          := sm_sc.__fv_turn_y_x_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1]);  
      elsif v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1] 
          := sm_sc.__fv_turn_y_x_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]); 
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]
          := sm_sc.__fv_turn_y_x_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]); 
      end if;      
    elsif i_turn_dims = array[1, 3]
    then
      if v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1] 
          := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
          := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]); 
      end if;      
    elsif i_turn_dims = array[1, 4]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
    elsif i_turn_dims = array[2, 3]
    then
      if v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1] 
          := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
          := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);
      end if;
    elsif i_turn_dims = array[2, 4]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);
    elsif i_turn_dims = array[3, 4]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_y_x3_180(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);
    end if;  
  elsif i_turn_angle = '90'
  then 
    if i_turn_dims = array[1, 2]
    then 
      if v_ndims = 2
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1]
          := sm_sc.__fv_turn_y_x_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1]);    
      elsif v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]
          := sm_sc.__fv_turn_y_x_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]
          := sm_sc.__fv_turn_y_x_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);      
      end if;
    elsif i_turn_dims = array[1, 3]
    then
      if v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]
          := sm_sc.__fv_turn_y_x3_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]
          := sm_sc.__fv_turn_y_x3_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
      end if;
    elsif i_turn_dims = array[1, 4]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_y_x4_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
    elsif i_turn_dims = array[2, 3]
    then
      if v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1] 
          := sm_sc.__fv_turn_x_x3_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
          := sm_sc.__fv_turn_x_x3_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
      end if;
    elsif i_turn_dims = array[2, 4]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_x_x4_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
    elsif i_turn_dims = array[3, 4]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_x3_x4_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
    elsif i_turn_dims = array[2, 1]
    then 
      if v_ndims = 2
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1]
          := sm_sc.__fv_turn_x_y_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1]);    
      elsif v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]
          := sm_sc.__fv_turn_x_y_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]
          := sm_sc.__fv_turn_x_y_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);      
      end if;
    elsif i_turn_dims = array[3, 1]
    then
      if v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]
          := sm_sc.__fv_turn_x3_y_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]
          := sm_sc.__fv_turn_x3_y_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
      end if;
    elsif i_turn_dims = array[4, 1]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_x4_y_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
    elsif i_turn_dims = array[3, 2]
    then
      if v_ndims = 3
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1] 
          := sm_sc.__fv_turn_x3_x_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1]);   
      elsif v_ndims = 4
      then 
        i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
          := sm_sc.__fv_turn_x3_x_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
      end if;
    elsif i_turn_dims = array[4, 2]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_x4_x_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);   
    elsif i_turn_dims = array[4, 3]
    then
      i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1] 
        := sm_sc.__fv_turn_x4_x3_90(i_arr[lower(i_chunk_pos[1]) : upper(i_chunk_pos[1]) - 1][lower(i_chunk_pos[2]) : upper(i_chunk_pos[2]) - 1][lower(i_chunk_pos[3]) : upper(i_chunk_pos[3]) - 1][lower(i_chunk_pos[4]) : upper(i_chunk_pos[4]) - 1]);  
    end if;
  end if;
  
  -- 返回
  return i_arr;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 3]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 4]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 3]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 4]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[3, 4]
--   , '90'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 3]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 4]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 3]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 4]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[3, 4]
--   , '180'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 3]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 4]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 3]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 4]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]],[[[21,22,23,24],[31,32,33,34]],[[25,26,27,28],[35,36,37,38]]]]
--   , array[int8range(1,3), int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[3, 4]
--   , '270'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 3]
--   , '90'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 3]
--   , '90'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 3]
--   , '180'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 3]
--   , '180'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[1, 3]
--   , '270'
--   );
-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[[1,2,3,4],[11,12,13,14]],[[5,6,7,8],[15,16,17,18]]]
--   , array[int8range(1,3), int8range(1,3), int8range(2,4)]
--   , array[2, 3]
--   , '270'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[1,2,3,4],[11,12,13,14]]
--   , array[int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '90'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[1,2,3,4],[11,12,13,14]]
--   , array[int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '180'
--   );

-- select 
--   sm_sc.fv_turn_squr_chunk
--   (
--     array[[1,2,3,4],[11,12,13,14]]
--   , array[int8range(1,3), int8range(2,4)]
--   , array[1, 2]
--   , '270'
--   );