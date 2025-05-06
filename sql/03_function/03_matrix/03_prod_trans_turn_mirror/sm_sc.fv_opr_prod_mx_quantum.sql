-- -- -- drop function if exists sm_sc.fv_opr_prod_mx_quantum(float[], float[]);
-- -- create or replace function sm_sc.fv_opr_prod_mx_quantum
-- -- (
-- --   i_left      float[]  ,
-- --   i_right     float[]
-- -- )
-- -- returns float[]
-- -- as
-- -- $$
-- -- declare
-- --   v_quantum_antilogarithm   float  := 2.0 ^ (1.0 / 65536.0);
-- -- begin
-- --   return 
-- --     ((<>` i_left) *` (v_quantum_antilogarithm ^` ((v_quantum_antilogarithm ^!` (@` i_left)) ~=` 0)))
-- --     |**|
-- --     ((<>` i_right) *` (v_quantum_antilogarithm ^` ((v_quantum_antilogarithm ^!` (@` i_right)) ~=` 0)))
-- --   ;
-- -- end
-- -- $$
-- -- language plpgsql stable
-- -- parallel safe
-- -- ;
-- -- 
-- -- -- select sm_sc.fv_opr_prod_mx_quantum(sm_sc.fv_new_rand(array[3,4]), sm_sc.fv_new_rand(array[4,5]))



-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_mx_quantum(float[], float[]);
create or replace function sm_sc.fv_opr_prod_mx_quantum
(
  i_left     float[]    ,
  i_right    float[]
)
returns float[]
as
$$
declare 
  v_quantum_antilogarithm         float     ;
  v_quantum_range_abs             int       ;
  v_quantum_dic                   float[]   ;
  v_left_log                      float[]   ;
  v_right_log                     float[]   ;
  v_left_sign                     int[]     ;
  v_right_sign                    int[]     ;
  v_ret_logarithm                 float[]   ;
  v_ret_logarithm_sign            boolean[] ;
  v_ret                           float[]   ;
  v_heigh                         int       := array_length(i_left, array_ndims(i_left) - 1);
  v_width                         int       := array_length(i_right, array_ndims(i_right));
  v_thick                         int       := array_length(i_left, array_ndims(i_left));
  v_cur_heigh                     int       ;
  v_cur_width                     int       ;
  v_cur_thick                     int       ;
  v_buff_log_sum                  int       ;
begin
  select 
    sign_reciprocal_quantum_arr
  , 2.0 ^ (1.0 / sign_reciprocal_quantum_arr_desc[1]) 
  , sign_reciprocal_quantum_arr_desc[1] * sign_reciprocal_quantum_arr_desc[2]
  into 
    v_quantum_dic
  , v_quantum_antilogarithm
  , v_quantum_range_abs
  from sm_sc.__vt_prod_mx_quantum_dic_arr
  limit 1
  ;

  -- 四舍五入放在 log 加法位置做会让精度提高一点点，
  -- 但代价是此后的四舍五入操作复杂度变为三次方，且三次方复杂度的点加法只能使用 float[] 而不是 int[]。
  v_left_log                :=  v_quantum_antilogarithm ^!` (@` i_left)    ;   --   ~=` 0    ;
  v_right_log               :=  (v_quantum_antilogarithm ^!` (@` i_right)) ;   --  ~=` 0     ;
  v_left_sign               :=  <>` i_left    ;
  v_right_sign              :=  <>` i_right   ;

  -- set search_path to sm_sc;
  if v_thick <> array_length(i_right, array_ndims(i_right) - 1)
  then
    raise exception 'unmatched length!';
  end if;

  if array_ndims(i_left) = 2 and array_ndims(i_right) = 2
  then
    v_ret := array_fill(0.0 :: float, array[v_heigh, v_width]);
    for v_cur_thick in 1 .. v_thick
    loop 
      for v_cur_heigh in 1 .. v_heigh
      loop 
        for v_cur_width in 1 .. v_width
        loop 
          v_buff_log_sum := round(v_left_log[v_cur_heigh][v_cur_thick] + v_right_log[v_cur_thick][v_cur_width]);
          v_ret[v_cur_heigh][v_cur_width] 
          :=
            v_ret[v_cur_heigh][v_cur_width]
            +
            case 
              when v_left_log[v_cur_heigh][v_cur_thick] = '-inf' :: float or v_right_log[v_cur_thick][v_cur_width] = '-inf' :: float
                then 0.0
              when abs(v_buff_log_sum) > v_quantum_range_abs
                then i_left[v_cur_heigh][v_cur_thick] * i_right[v_cur_thick][v_cur_width]
              when v_left_sign[v_cur_heigh][v_cur_thick] = v_right_sign[v_cur_thick][v_cur_width]
                then v_quantum_dic[v_buff_log_sum]     -- ] :: int]
              when v_left_sign[v_cur_heigh][v_cur_thick] <> v_right_sign[v_cur_thick][v_cur_width]
                then - v_quantum_dic[v_buff_log_sum]   -- ] :: int]
            end
          ;
        end loop;
      end loop;
    end loop;
    
    return v_ret;
    
    -- v_ret_logarithm := 
    --   sm_sc.fv_repeat_axis_py
    --   (
    --     v_left_log |><| array[v_heigh, v_thick, 1]
    --   , 3
    --   , v_width
    --   )
    --   +`
    --   sm_sc.fv_repeat_axis_py
    --   (
    --     array[v_right_log]
    --   , 1
    --   , v_heigh
    --   )
    -- ;
    -- 
    -- v_ret_logarithm_sign := 
    --   sm_sc.fv_repeat_axis_py
    --   (
    --     v_left_sign |><| array[v_heigh, v_thick, 1]
    --   , 3
    --   , v_width
    --   )
    --   ==`
    --   sm_sc.fv_repeat_axis_py
    --   (
    --     array[v_right_sign]
    --   , 1
    --   , v_heigh
    --   )
    -- ;
    -- 
    -- v_ret := array_fill(null :: float, array[v_heigh, v_thick, v_width]);
    -- 
    -- for v_cur_heigh in 1 .. v_heigh
    -- loop 
    --   for v_cur_thick in 1 .. v_thick
    --   loop 
    --     for v_cur_width in 1 .. v_width
    --     loop 
    --       v_ret[v_cur_heigh][v_cur_thick][v_cur_width] 
    --       :=
    --         case 
    --           when v_ret_logarithm[v_cur_heigh][v_cur_thick][v_cur_width] = '-inf' :: float
    --             then 0.0
    --           when abs(v_ret_logarithm[v_cur_heigh][v_cur_thick][v_cur_width]) > v_quantum_range_abs
    --             then i_left[v_cur_heigh][v_cur_thick] * i_right[v_cur_thick][v_cur_width]
    --           when v_ret_logarithm_sign[v_cur_heigh][v_cur_thick][v_cur_width]
    --             then v_quantum_dic[v_ret_logarithm[v_cur_heigh][v_cur_thick][v_cur_width]]     -- ] :: int]
    --           when not v_ret_logarithm_sign[v_cur_heigh][v_cur_thick][v_cur_width] 
    --             then - v_quantum_dic[v_ret_logarithm[v_cur_heigh][v_cur_thick][v_cur_width]]   -- ] :: int]
    --         end
    --       ;
    --     end loop;
    --   end loop;
    -- end loop;
    -- 
    -- return 
    --   (
    --     v_ret 
    --     |@+| 
    --     array[1, v_thick, 1]
    --   )
    --   |><|
    --   array[v_heigh, v_width]
    -- ;
  else
    raise exception 'no method for such length!  L_Dim: %; R_Dim: %;', array_dims(i_left), array_dims(i_right);
  end if;
  
  return v_quantum_antilogarithm;

end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_prod_mx_quantum
--   (
--     array[array[1.,2.,3.], array[4.,5.,6.]],
--     array[array[1.,3.,5.,7. ], array[5.,7.,9.,11.], array[9.,11.,13.,15.]]
--   ) :: decimal[] ~=` 5; -- {{38,50,62,74},{83,113,143,173}};
-- select sm_sc.fv_opr_prod_mx_quantum
--   (
--     array[array[0.,0.,0.], array[4.,5.,6.]],
--     array[array[1.,3.,5.,7. ], array[0.,0.,0.,0.], array[9.,11.,13.,15.]]
--   );

-- with 
-- cte_arr as 
-- (
--   select
--     sm_sc.fv_new_rand(array[3,4]) as a_1
--   , sm_sc.fv_new_rand(array[4,2]) as a_2
-- )
-- select 
--   sm_sc.fv_opr_prod_mx_quantum
--   (
--     a_1
--   , a_2
--   )
-- , sm_sc.fv_opr_prod_mx_py
--   (
--     a_1
--   , a_2
--   )
-- from cte_arr