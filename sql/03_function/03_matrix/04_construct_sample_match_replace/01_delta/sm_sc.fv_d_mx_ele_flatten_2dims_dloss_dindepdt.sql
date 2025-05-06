-- drop function if exists sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt(anyarray, int[2], int, int[]);
create or replace function sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt
(
  i_dloss_ddepdt_nd        anyarray  
, i_dims_from_to           int[2]     -- 扁平化的维度的原来两个维度。扁平化后的新维度在 to 的顺序位置。当 from 与 to 为相邻维度时，[from, to] 等价于 [to, from]。
, i_dim_pin_ele            int        -- 被定住元素顺序的旧维度。该旧维度下的元素顺序，将保留至新维度。i_dim_pin_ele 为 from 或 to，不能为其他值。
, i_indepdt_len            int[]
)
returns anyarray
as
$$
declare
  v_ret     i_dloss_ddepdt_nd%type    := array_fill(i_dloss_ddepdt_nd[0], i_indepdt_len);
  v_cur_y   int                       ;
  v_cur_x   int                       ;
  v_cur_x3  int                       ;
  v_cur_x4  int                       ;

begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_dloss_ddepdt_nd) not between 2 and 4
    then 
      raise exception 'ndims should be between 2 and 4.';
    end if;
    
    if i_dim_pin_ele <> all(i_dims_from_to)
    then 
      raise exception 'the pin_ele dim must be one of from_to dims.';
    end if;
    
    if array_ndims(i_indepdt_len) <> 1 or array_ndims(i_dloss_ddepdt_nd) <> array_length(i_indepdt_len, 1)
    then 
      raise exception 'wrong i_indepdt_len for i_dloss_ddepdt_nd.';
    end if;
    
    if i_dims_from_to[1] not between 1 and array_ndims(i_dloss_ddepdt_nd) 
      or i_dims_from_to[2] not between 1 and array_ndims(i_dloss_ddepdt_nd) 
      or i_dims_from_to[1] = i_dims_from_to[2]
    then 
      raise exception 'unsupport this i_dims_from_to.';
    end if;
    
    if array_length(i_dloss_ddepdt_nd, i_dims_from_to[1]) <> 1
    then 
      raise exception 'array_length of i_dloss_ddepdt_nd at dims_from should be 1.';
    end if;
    
    if array_length(i_dloss_ddepdt_nd, i_dims_from_to[2]) <> i_indepdt_len[i_dims_from_to[1]] * i_indepdt_len[i_dims_from_to[2]]
    then 
      raise exception 'wrong array_length of i_dloss_ddepdt_nd at dims_to';
    end if;
  end if;
  
  if i_dloss_ddepdt_nd is null 
  then 
    return null;
  end if;  
  
  if array_length(i_indepdt_len, 1) = 2
  then 
    if i_dims_from_to = array[1, 2]
    then 
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          v_ret
            [ : ]
            [v_cur_x : v_cur_x] 
          := 
            i_dloss_ddepdt_nd
              [1 : 1]
              [(v_cur_x - 1) * i_indepdt_len[1] + 1 : v_cur_x * i_indepdt_len[1]] 
          ;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          v_ret
            [v_cur_y : v_cur_y]
            [ : ]
          := 
            i_dloss_ddepdt_nd
              [1 : 1]
              [(v_cur_y - 1) * i_indepdt_len[2] + 1 : v_cur_y * i_indepdt_len[2]] 
          ;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 1]
    then 
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          v_ret
            [v_cur_y : v_cur_y]
            [ : ]
          := 
            i_dloss_ddepdt_nd
              [(v_cur_y - 1) * i_indepdt_len[2] + 1 : v_cur_y * i_indepdt_len[2]] 
              [1 : 1]
          ;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          v_ret
            [ : ]
            [v_cur_x : v_cur_x]
          := 
            i_dloss_ddepdt_nd
              [(v_cur_x - 1) * i_indepdt_len[1] + 1 : v_cur_x * i_indepdt_len[1]] 
              [1 : 1]
          ;
        end loop;
      end if;
    end if;
  elsif array_length(i_indepdt_len, 1) = 3
  then 
    if i_dims_from_to = array[1, 2]
    then 
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [ : ]
              [v_cur_x : v_cur_x]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [1 : 1]
                [(v_cur_x - 1) * i_indepdt_len[1] + 1 : v_cur_x * i_indepdt_len[1]] 
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [ : ]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [1 : 1]
                [(v_cur_y - 1) * i_indepdt_len[2] + 1 : v_cur_y * i_indepdt_len[2]] 
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 1]
    then 
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [ : ]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [(v_cur_y - 1) * i_indepdt_len[2] + 1 : v_cur_y * i_indepdt_len[2]] 
                [1 : 1]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [ : ]
              [v_cur_x : v_cur_x]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [(v_cur_x - 1) * i_indepdt_len[1] + 1 : v_cur_x * i_indepdt_len[1]] 
                [1 : 1]
                [v_cur_x3 : v_cur_x3]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[1, 3]
    then 
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [ : ]
              [v_cur_x : v_cur_x]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [1 : 1]
                [v_cur_x : v_cur_x]
                [(v_cur_x3 - 1) * i_indepdt_len[1] + 1 : v_cur_x3 * i_indepdt_len[1]] 
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [v_cur_x : v_cur_x]
              [ : ]
            := 
              i_dloss_ddepdt_nd
                [1 : 1]
                [v_cur_x : v_cur_x]
                [(v_cur_y - 1) * i_indepdt_len[3] + 1 : v_cur_y * i_indepdt_len[3]] 
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 1]
    then 
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [v_cur_x : v_cur_x]
              [ : ]
            := 
              i_dloss_ddepdt_nd
                [(v_cur_y - 1) * i_indepdt_len[3] + 1 : v_cur_y * i_indepdt_len[3]] 
                [v_cur_x : v_cur_x]
                [1 : 1]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [ : ]
              [v_cur_x : v_cur_x]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [(v_cur_x3 - 1) * i_indepdt_len[1] + 1 : v_cur_x3 * i_indepdt_len[1]] 
                [v_cur_x : v_cur_x]
                [1 : 1]
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 3]
    then 
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [ : ]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [v_cur_y : v_cur_y]
                [1 : 1]
                [(v_cur_x3 - 1) * i_indepdt_len[2] + 1 : v_cur_x3 * i_indepdt_len[2]] 
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [v_cur_x : v_cur_x]
              [ : ]
            := 
              i_dloss_ddepdt_nd
                [v_cur_y : v_cur_y]
                [1 : 1]
                [(v_cur_x - 1) * i_indepdt_len[3] + 1 : v_cur_x * i_indepdt_len[3]] 
            ;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 2]
    then 
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [v_cur_x : v_cur_x]
              [ : ]
            := 
              i_dloss_ddepdt_nd
                [v_cur_y : v_cur_y]
                [(v_cur_x - 1) * i_indepdt_len[3] + 1 : v_cur_x * i_indepdt_len[3]] 
                [1 : 1]
            ;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            v_ret
              [v_cur_y : v_cur_y]
              [ : ]
              [v_cur_x3 : v_cur_x3]
            := 
              i_dloss_ddepdt_nd
                [v_cur_y : v_cur_y]
                [(v_cur_x3 - 1) * i_indepdt_len[2] + 1 : v_cur_x3 * i_indepdt_len[2]] 
                [1 : 1]
            ;
          end loop;
        end loop;
      end if;
    end if;
  elsif array_length(i_indepdt_len, 1) = 4
  then 
    if i_dims_from_to = array[1, 2]
    then 
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [1 : 1]
                  [(v_cur_x - 1) * i_indepdt_len[1] + 1 : v_cur_x * i_indepdt_len[1]] 
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [1 : 1]
                  [(v_cur_y - 1) * i_indepdt_len[2] + 1 : v_cur_y * i_indepdt_len[2]] 
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 1]
    then 
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [(v_cur_y - 1) * i_indepdt_len[2] + 1 : v_cur_y * i_indepdt_len[2]] 
                  [1 : 1]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [(v_cur_x - 1) * i_indepdt_len[1] + 1 : v_cur_x * i_indepdt_len[1]] 
                  [1 : 1]
                  [v_cur_x3 : v_cur_x3]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[1, 3]
    then 
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [1 : 1]
                  [v_cur_x : v_cur_x]
                  [(v_cur_x3 - 1) * i_indepdt_len[1] + 1 : v_cur_x3 * i_indepdt_len[1]] 
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [1 : 1]
                  [v_cur_x : v_cur_x]
                  [(v_cur_y - 1) * i_indepdt_len[3] + 1 : v_cur_y * i_indepdt_len[3]] 
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 1]
    then 
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [(v_cur_y - 1) * i_indepdt_len[3] + 1 : v_cur_y * i_indepdt_len[3]] 
                  [v_cur_x : v_cur_x]
                  [1 : 1]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [(v_cur_x3 - 1) * i_indepdt_len[1] + 1 : v_cur_x3 * i_indepdt_len[1]] 
                  [v_cur_x : v_cur_x]
                  [1 : 1]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[1, 4]
    then 
      if i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [1 : 1]
                  [v_cur_x : v_cur_x] 
                  [v_cur_x3 : v_cur_x3]
                  [(v_cur_x4 - 1) * i_indepdt_len[1] + 1 : v_cur_x4 * i_indepdt_len[1]]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x3 in 1 .. i_indepdt_len[3]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [ : ]
              := 
                i_dloss_ddepdt_nd
                  [1 : 1]
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [(v_cur_y - 1) * i_indepdt_len[4] + 1 : v_cur_y * i_indepdt_len[4]] 
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[4, 1]
    then 
      if i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x3 in 1 .. i_indepdt_len[3]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [ : ]
              := 
                i_dloss_ddepdt_nd
                  [(v_cur_y - 1) * i_indepdt_len[4] + 1 : v_cur_y * i_indepdt_len[4]] 
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [1 : 1]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 1
      then 
        for v_cur_x in 1 .. i_indepdt_len[2]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [ : ]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [(v_cur_x4 - 1) * i_indepdt_len[1] + 1 : v_cur_x4 * i_indepdt_len[1]] 
                  [v_cur_x : v_cur_x]
                  [v_cur_x3 : v_cur_x3]
                  [1 : 1]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 3]
    then 
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [1 : 1]
                  [(v_cur_x3 - 1) * i_indepdt_len[2] + 1 : v_cur_x3 * i_indepdt_len[2]] 
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [1 : 1]
                  [(v_cur_x - 1) * i_indepdt_len[3] + 1 : v_cur_x * i_indepdt_len[3]] 
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 2]
    then 
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [(v_cur_x - 1) * i_indepdt_len[3] + 1 : v_cur_x * i_indepdt_len[3]] 
                  [1 : 1]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [(v_cur_x3 - 1) * i_indepdt_len[2] + 1 : v_cur_x3 * i_indepdt_len[2]] 
                  [1 : 1]
                  [v_cur_x4 : v_cur_x4]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[2, 4]
    then 
      if i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y] 
                  [1 : 1]
                  [v_cur_x3 : v_cur_x3]
                  [(v_cur_x4 - 1) * i_indepdt_len[2] + 1 : v_cur_x4 * i_indepdt_len[2]]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x3 in 1 .. i_indepdt_len[3]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [ : ]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [1 : 1]
                  [v_cur_x3 : v_cur_x3]
                  [(v_cur_x - 1) * i_indepdt_len[4] + 1 : v_cur_x * i_indepdt_len[4]] 
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[4, 2]
    then 
      if i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x3 in 1 .. i_indepdt_len[3]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [ : ]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [(v_cur_x - 1) * i_indepdt_len[4] + 1 : v_cur_x * i_indepdt_len[4]] 
                  [v_cur_x3 : v_cur_x3]
                  [1 : 1]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 2
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x3 in 1 .. i_indepdt_len[3]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [ : ]
                [v_cur_x3 : v_cur_x3]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [(v_cur_x4 - 1) * i_indepdt_len[2] + 1 : v_cur_x4 * i_indepdt_len[2]] 
                  [v_cur_x3 : v_cur_x3]
                  [1 : 1]
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[3, 4]
    then 
      if i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x2 in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x2 : v_cur_x2]
                [ : ]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y] 
                  [v_cur_x2 : v_cur_x2]
                  [1 : 1]
                  [(v_cur_x4 - 1) * i_indepdt_len[3] + 1 : v_cur_x4 * i_indepdt_len[3]]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x3 in 1 .. i_indepdt_len[3]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [ : ]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [1 : 1]
                  [(v_cur_x3 - 1) * i_indepdt_len[4] + 1 : v_cur_x3 * i_indepdt_len[4]] 
              ;
            end loop;
          end loop;
        end loop;
      end if;
    elsif i_dims_from_to = array[4, 3]
    then 
      if i_dim_pin_ele = 4
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x3 in 1 .. i_indepdt_len[3]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [v_cur_x3 : v_cur_x3]
                [ : ]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [(v_cur_x3 - 1) * i_indepdt_len[4] + 1 : v_cur_x3 * i_indepdt_len[4]] 
                  [1 : 1]
              ;
            end loop;
          end loop;
        end loop;
      elsif i_dim_pin_ele = 3
      then 
        for v_cur_y in 1 .. i_indepdt_len[1]
        loop 
          for v_cur_x in 1 .. i_indepdt_len[2]
          loop 
            for v_cur_x4 in 1 .. i_indepdt_len[4]
            loop 
              v_ret
                [v_cur_y : v_cur_y]
                [v_cur_x : v_cur_x]
                [ : ]
                [v_cur_x4 : v_cur_x4]
              := 
                i_dloss_ddepdt_nd
                  [v_cur_y : v_cur_y]
                  [v_cur_x : v_cur_x]
                  [(v_cur_x4 - 1) * i_indepdt_len[3] + 1 : v_cur_x4 * i_indepdt_len[3]] 
                  [1 : 1]
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

-- with 
-- cte_mx_ele_flatten_2dims as 
-- (
--   select 
--     a_arr
--   , a_dim_from
--   , a_dim_to
--   , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx] as a_dim_pin_ele
--   , sm_sc.fv_mx_ele_flatten_2dims
--     (
--       a_arr
--     , array[a_dim_from, a_dim_to]
--     , (array[a_dim_from, a_dim_to])[a_dim_pin_ele_idx]
--     ) as a_flattened_dims
--   from 
--     (
--                 select sm_sc.fv_new_rand(array[4,3    ]) as a_arr
--       union all select sm_sc.fv_new_rand(array[4,3,5  ]) as a_arr
--       union all select sm_sc.fv_new_rand(array[4,3,5,7]) as a_arr
--     ) tb_a_arr(a_arr)
--   , generate_series(1, 4) tb_a_dim_from(a_dim_from)
--   , generate_series(1, 4) tb_a_dim_to(a_dim_to)
--   , generate_series(1, 2) tb_a_dim_pin_ele_idx(a_dim_pin_ele_idx)
--   where a_dim_from <= array_ndims(a_arr)
--     and a_dim_to <= array_ndims(a_arr)
--     and a_dim_from <> a_dim_to
--   order by array_ndims(a_arr), a_dim_from, a_dim_to, a_dim_pin_ele_idx
-- )
-- select 
--   sm_sc.fv_d_mx_ele_flatten_2dims_dloss_dindepdt
--   (
--     a_flattened_dims
--   , array[a_dim_from, a_dim_to]
--   , a_dim_pin_ele
--   , (select array_agg(array_length(a_arr, a_no) order by a_no) from generate_series(1, array_ndims(a_arr)) tb_a_no(a_no))
--   ) = a_arr
-- from cte_mx_ele_flatten_2dims