-- drop function if exists sm_sc.fv_mx_ele_flatten_2dims(anyarray, int[2], int);
create or replace function sm_sc.fv_mx_ele_flatten_2dims
(
  i_array_nd        anyarray,  
  i_dims_from_to    int[2]  ,  -- 扁平化的维度的原来两个维度。扁平化后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
  i_dim_pin_ele     int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
)
returns anyarray
as
$$
declare
  v_ret     i_array_nd%type;
  v_cur_y   int            ;
  v_cur_x   int            ;
  v_cur_x3  int            ;
  v_cur_x4  int            ;

begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array_nd) not between 2 and 4
    then 
      raise exception 'unsupport ndims outof range [2,4]';
    end if;
    
    if i_dim_pin_ele <> all(i_dims_from_to)
    then 
      raise exception 'the pin_ele dim must be one of from_to dims.';
    end if;
    
    if i_dims_from_to[1] not between 1 and array_ndims(i_array_nd) 
      or i_dims_from_to[2] not between 1 and array_ndims(i_array_nd) 
      or i_dims_from_to[1] = i_dims_from_to[2]
    then 
      raise exception 'unsupport this i_dims_from_to.';
    end if;
  end if;

  if i_array_nd is null 
  then 
    return null;
  end if;  
  
  if array_ndims(i_array_nd) = 2
  then 
    if i_dims_from_to = array[1, 2]
    then
      v_ret := array_fill(i_array_nd[0], array[1, array_length(i_array_nd, 1) * array_length(i_array_nd, 2)]);
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          v_ret
            [1 : 1]
            [(v_cur_x - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x * array_length(i_array_nd, 1)] 
          := 
            i_array_nd
              [ : ]
              [v_cur_x : v_cur_x]
          ;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret
            [1 : 1]
            [(v_cur_y - 1) * array_length(i_array_nd, 2) + 1 : v_cur_y * array_length(i_array_nd, 2)] 
          := 
            i_array_nd
              [v_cur_y : v_cur_y]
              [ : ]
          ;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 1]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1) * array_length(i_array_nd, 2), 1]);
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          v_ret
            [(v_cur_y - 1) * array_length(i_array_nd, 2) + 1 : v_cur_y * array_length(i_array_nd, 2)] 
            [1 : 1]
          := 
            i_array_nd
              [v_cur_y : v_cur_y]
              [ : ]
          ;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          v_ret
            [(v_cur_x - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x * array_length(i_array_nd, 1)] 
            [1 : 1]
          := 
            i_array_nd
              [ : ]
              [v_cur_x : v_cur_x]
          ;
        end loop;
      end if;
    end if;
  elsif array_ndims(i_array_nd) = 3
  then 
    if i_dims_from_to = array[1, 2]
    then
      v_ret := array_fill(i_array_nd[0], array[1, array_length(i_array_nd, 1) * array_length(i_array_nd, 2), array_length(i_array_nd, 3)]);
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [1 : 1]
              [(v_cur_x - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x * array_length(i_array_nd, 1)] 
              [v_cur_x3 : v_cur_x3]
            := 
              i_array_nd
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [1 : 1]
              [(v_cur_y - 1) * array_length(i_array_nd, 2) + 1 : v_cur_y * array_length(i_array_nd, 2)] 
              [v_cur_x3 : v_cur_x3]
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 1]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1) * array_length(i_array_nd, 2), 1, array_length(i_array_nd, 3)]);
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [(v_cur_y - 1) * array_length(i_array_nd, 2) + 1 : v_cur_y * array_length(i_array_nd, 2)] 
              [1 : 1]
              [v_cur_x3 : v_cur_x3]
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [(v_cur_x - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x * array_length(i_array_nd, 1)] 
              [1 : 1]
              [v_cur_x3 : v_cur_x3]
            := 
              i_array_nd
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[1, 3]
    then 
      v_ret := array_fill(i_array_nd[0], array[1, array_length(i_array_nd, 2), array_length(i_array_nd, 1) * array_length(i_array_nd, 3)]);
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [1 : 1]
              [v_cur_x : v_cur_x]
              [(v_cur_x3 - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x3 * array_length(i_array_nd, 1)] 
            := 
              i_array_nd
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            v_ret
              [1 : 1]
              [v_cur_x : v_cur_x]
              [(v_cur_y - 1) * array_length(i_array_nd, 3) + 1 : v_cur_y * array_length(i_array_nd, 3)] 
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 1]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1) * array_length(i_array_nd, 3), array_length(i_array_nd, 2), 1]);
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            v_ret
              [(v_cur_y - 1) * array_length(i_array_nd, 3) + 1 : v_cur_y * array_length(i_array_nd, 3)] 
              [v_cur_x : v_cur_x]
              [1 : 1]
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [(v_cur_x3 - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x3 * array_length(i_array_nd, 1)] 
              [v_cur_x : v_cur_x]
              [1 : 1]
            := 
              i_array_nd
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 3]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), 1, array_length(i_array_nd, 2) * array_length(i_array_nd, 3)]);
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [1 : 1]
              [(v_cur_x3 - 1) * array_length(i_array_nd, 2) + 1 : v_cur_x3 * array_length(i_array_nd, 2)] 
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [1 : 1]
              [(v_cur_x - 1) * array_length(i_array_nd, 3) + 1 : v_cur_x * array_length(i_array_nd, 3)] 
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 2]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), array_length(i_array_nd, 2) * array_length(i_array_nd, 3), 1]);
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [(v_cur_x - 1) * array_length(i_array_nd, 3) + 1 : v_cur_x * array_length(i_array_nd, 3)] 
              [1 : 1]
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [(v_cur_x3 - 1) * array_length(i_array_nd, 2) + 1 : v_cur_x3 * array_length(i_array_nd, 2)] 
              [1 : 1]
            := 
              i_array_nd
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    end if;
  elsif array_ndims(i_array_nd) = 4
  then 
    if i_dims_from_to = array[1, 2]
    then
      v_ret := array_fill(i_array_nd[0], array[1, array_length(i_array_nd, 1) * array_length(i_array_nd, 2), array_length(i_array_nd, 3), array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [1 : 1]
                [(v_cur_x - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x * array_length(i_array_nd, 1)] 
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [ : ]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [1 : 1]
                [(v_cur_y - 1) * array_length(i_array_nd, 2) + 1 : v_cur_y * array_length(i_array_nd, 2)] 
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [ : ]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 1]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1) * array_length(i_array_nd, 2), 1, array_length(i_array_nd, 3), array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [(v_cur_y - 1) * array_length(i_array_nd, 2) + 1 : v_cur_y * array_length(i_array_nd, 2)] 
                [1 : 1]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [ : ]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [(v_cur_x - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x * array_length(i_array_nd, 1)] 
                [1 : 1]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [ : ]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[1, 3]
    then 
      v_ret := array_fill(i_array_nd[0], array[1, array_length(i_array_nd, 2), array_length(i_array_nd, 1) * array_length(i_array_nd, 3), array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [1 : 1]
                [v_cur_x : v_cur_x]
                [(v_cur_x3 - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x3 * array_length(i_array_nd, 1)] 
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [ : ]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [1 : 1]
                [v_cur_x : v_cur_x]
                [(v_cur_y - 1) * array_length(i_array_nd, 3) + 1 : v_cur_y * array_length(i_array_nd, 3)] 
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [ : ]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 1]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1) * array_length(i_array_nd, 3), array_length(i_array_nd, 2), 1, array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [(v_cur_y - 1) * array_length(i_array_nd, 3) + 1 : v_cur_y * array_length(i_array_nd, 3)] 
                [v_cur_x : v_cur_x]
                [1 : 1]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [ : ]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [(v_cur_x3 - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x3 * array_length(i_array_nd, 1)] 
                [v_cur_x : v_cur_x]
                [1 : 1]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [ : ]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[1, 4]
    then 
      v_ret := array_fill(i_array_nd[0], array[1, array_length(i_array_nd, 2), array_length(i_array_nd, 3), array_length(i_array_nd, 1) * array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [1 : 1]
                [v_cur_x : v_cur_x] 
                [v_cur_x3 : v_cur_x3]
                [(v_cur_x4 - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x4 * array_length(i_array_nd, 1)]
              := 
                i_array_nd
                  [ : ]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
            loop 
              v_ret
                [1 : 1]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [(v_cur_y - 1) * array_length(i_array_nd, 4) + 1 : v_cur_y * array_length(i_array_nd, 4)] 
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [ : ]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[4, 1]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1) * array_length(i_array_nd, 4), array_length(i_array_nd, 2), array_length(i_array_nd, 3), 1]);
      if i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
            loop 
              v_ret
                [(v_cur_y - 1) * array_length(i_array_nd, 4) + 1 : v_cur_y * array_length(i_array_nd, 4)] 
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [1 : 1]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [ : ]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. array_length(i_array_nd, 2)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [(v_cur_x4 - 1) * array_length(i_array_nd, 1) + 1 : v_cur_x4 * array_length(i_array_nd, 1)] 
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [1 : 1]
              := 
                i_array_nd
                  [ : ]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 3]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), 1, array_length(i_array_nd, 2) * array_length(i_array_nd, 3), array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [1 : 1]
                [(v_cur_x3 - 1) * array_length(i_array_nd, 2) + 1 : v_cur_x3 * array_length(i_array_nd, 2)] 
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [ : ]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [1 : 1]
                [(v_cur_x - 1) * array_length(i_array_nd, 3) + 1 : v_cur_x * array_length(i_array_nd, 3)] 
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [ : ]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 2]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), array_length(i_array_nd, 2) * array_length(i_array_nd, 3), 1, array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [(v_cur_x - 1) * array_length(i_array_nd, 3) + 1 : v_cur_x * array_length(i_array_nd, 3)] 
                [1 : 1]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [ : ]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [(v_cur_x3 - 1) * array_length(i_array_nd, 2) + 1 : v_cur_x3 * array_length(i_array_nd, 2)] 
                [1 : 1]
                [v_cur_x4 : v_cur_x4]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [ : ]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 4]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), 1, array_length(i_array_nd, 3), array_length(i_array_nd, 2) * array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y] 
                [1 : 1]
                [v_cur_x3 : v_cur_x3]
                [(v_cur_x4 - 1) * array_length(i_array_nd, 2) + 1 : v_cur_x4 * array_length(i_array_nd, 2)]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [ : ]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [1 : 1]
                [v_cur_x3 : v_cur_x3]
                [(v_cur_x - 1) * array_length(i_array_nd, 4) + 1 : v_cur_x * array_length(i_array_nd, 4)] 
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [ : ]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[4, 2]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), array_length(i_array_nd, 2) * array_length(i_array_nd, 4), array_length(i_array_nd, 3), 1]);
      if i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [(v_cur_x - 1) * array_length(i_array_nd, 4) + 1 : v_cur_x * array_length(i_array_nd, 4)] 
                [v_cur_x3 : v_cur_x3]
                [1 : 1]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [ : ]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [(v_cur_x4 - 1) * array_length(i_array_nd, 2) + 1 : v_cur_x4 * array_length(i_array_nd, 2)] 
                [v_cur_x3 : v_cur_x3]
                [1 : 1]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [ : ]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 4]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), array_length(i_array_nd, 2), 1, array_length(i_array_nd, 3) * array_length(i_array_nd, 4)]);
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x2 in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y] 
                [v_cur_x2 : v_cur_x2]
                [1 : 1]
                [(v_cur_x4 - 1) * array_length(i_array_nd, 3) + 1 : v_cur_x4 * array_length(i_array_nd, 3)]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x2 : v_cur_x2]
                  [ : ]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [1 : 1]
                [(v_cur_x3 - 1) * array_length(i_array_nd, 4) + 1 : v_cur_x3 * array_length(i_array_nd, 4)] 
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [ : ]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[4, 3]
    then 
      v_ret := array_fill(i_array_nd[0], array[array_length(i_array_nd, 1), array_length(i_array_nd, 2), array_length(i_array_nd, 3) * array_length(i_array_nd, 4), 1]);
      if i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x3 in 1 .. array_length(i_array_nd, 3)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [(v_cur_x3 - 1) * array_length(i_array_nd, 4) + 1 : v_cur_x3 * array_length(i_array_nd, 4)] 
                [1 : 1]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [ : ]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. array_length(i_array_nd, 1)
        loop 
          for v_cur_x in 1 .. array_length(i_array_nd, 2)
          loop 
            for v_cur_x4 in 1 .. array_length(i_array_nd, 4)
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [(v_cur_x4 - 1) * array_length(i_array_nd, 3) + 1 : v_cur_x4 * array_length(i_array_nd, 3)] 
                [1 : 1]
              := 
                i_array_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [ : ]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    end if;
  end if;
  
  return v_ret; 
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- with cte_arr as
-- (
--   select 
--     array
--     [
--       [
--         [1, 2, 3, 4]
--       , [5, 6, 7, 8]
--       , [9, 10, 11, 12]
--       ]
--     , [
--         [21, 22, 23, 24]
--       , [25, 26, 27, 28]
--       , [29, 30, 31, 32]
--       ]
--     ]
--     as a_arr
-- )
-- select 
--   a_dims_from_to, a_dim_pin_ele,
--   sm_sc.fv_mx_ele_flatten_2dims(a_arr, a_dims_from_to, a_dim_pin_ele) as a_out
-- from cte_arr
--   , (
--                 select array[1, 2]  
--       union all select array[2, 3] 
--       union all select array[2, 1]  
--       union all select array[3, 2] 
--       union all select array[1, 3] 
--       union all select array[3, 1]
--     ) tb_a_dims_from_to(a_dims_from_to)
--   , generate_series(1, 3) tb_a_dim_pin_ele(a_dim_pin_ele)
-- where a_dim_pin_ele = any(a_dims_from_to)
-- order by least(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dims_from_to[1]
--   , greatest(|@<| a_dims_from_to, |@>| a_dims_from_to)
--   , a_dim_pin_ele

-- select 
--   a_dim_from
-- , a_dim_to
-- , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx] as a_dim_pin_ele
-- , array_dims(
--   sm_sc.fv_mx_ele_flatten_2dims
--   (
--     a_arr
--   , array[a_dim_from, a_dim_to]
--   , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx]
--   )) as a_flattened_dims
-- , array_dims(a_arr) as a_arr_dims
-- from 
--   (
--               select sm_sc.fv_new_rand(array[4,3    ]) as a_arr
--     union all select sm_sc.fv_new_rand(array[4,3,5  ]) as a_arr
--     union all select sm_sc.fv_new_rand(array[4,3,5,7]) as a_arr
--   ) tb_a_arr(a_arr)
-- , generate_series(1, 4) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 4) tb_a_dim_to(a_dim_to)
-- , generate_series(1, 2) tb_a_dim_pin_ele_idx(a_dim_pin_ele_idx)
-- where a_dim_from <= array_ndims(a_arr)
--   and a_dim_to <= array_ndims(a_arr)
--   and a_dim_from <> a_dim_to
-- order by array_ndims(a_arr), a_dim_from, a_dim_to, a_dim_pin_ele_idx
