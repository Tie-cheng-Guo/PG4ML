-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
-- (
--   anyarray
--   -- , int[2]
--   , anyarray
--   , int[]
--   , anyarray
--   , int[]
--   , anyarray
--   , int[2]
--   , int[4]
--   , anyelement
-- );
create or replace function sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
(
  i_window                anyarray           ,  -- 当 i_depdt_var 不为空，可以不传 i_window
  -- i_window_len            int[2]             ,
  i_background            anyarray           ,
  i_background_len        int[]             ,
  i_depdt_var             anyarray           ,  -- 尽量传 i_depdt_var, 节省开销
  i_depdt_var_len         int[]             ,
  i_dloss_ddepdt          anyarray           ,
  i_stride                int[2]              default  array[1, 1]             ,  -- 纵向与横向步长
  i_padding               int[4]              default  array[0, 0, 0, 0]       ,  -- 上下左右补齐行数/列数
  i_padding_value         anyelement          default  '0.0'                        -- 补齐填充元素值
)
returns anyarray
as
$$
declare 
  v_dloss_ddepdt_len      int[2]    :=   array[array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1), array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt))];
  v_background_len     -- int[2]    :=   array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
                          int[2]    :=   i_background_len[array_length(i_background_len, 1) - 1 : array_length(i_background_len, 1)];
  v_window_len            int[2]    :=   array[array_length(i_window, array_ndims(i_window) - 1), array_length(i_window, array_ndims(i_window))];
                       -- alias for i_window_len;
  v_depdt_var_len      -- int[2]    :=   array[array_length(i_depdt_var, array_ndims(i_depdt_var) - 1), array_length(i_depdt_var, array_ndims(i_depdt_var))];
                          alias for i_depdt_var_len;
begin
  if v_background_len is null
  then 
    v_background_len := array[array_length(i_background, array_ndims(i_background) - 1), array_length(i_background, array_ndims(i_background))];
  end if;
  -- if v_window_len is null
  -- then 
  --   v_window_len := array[array_length(i_window, 1), array_length(i_window, 2)];
  -- end if;
  if v_depdt_var_len is null
  then 
    v_depdt_var_len := array[array_length(i_depdt_var, array_ndims(i_depdt_var) - 1), array_length(i_depdt_var, array_ndims(i_depdt_var))];
  end if;

  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
  -- -- 审计二维长度
    if array_ndims(i_dloss_ddepdt) not between 2 and 4
      or array_ndims(i_background) not between 2 and 4 
      or array_ndims(i_dloss_ddepdt) <> array_ndims(i_background)
    then 
      raise exception 'no method for such ndims!';
    elsif i_window is not null and array_ndims(i_window) <> 2 and array_ndims(i_window) <> array_ndims(i_dloss_ddepdt)
    then 
      raise exception 'no method for such i_window length!  Dims: %;', array_dims(i_window);
    elsif v_background_len is null or v_window_len is null or v_depdt_var_len is null or i_dloss_ddepdt is null 
    then 
      raise exception 'v_background_len, v_window_len, v_depdt_var_len, i_dloss_ddepdt should be not null.';
    elsif (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) % i_stride[1] <> 0
    then 
      raise exception 'imperfect window at 1d.';
    elsif (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) % i_stride[2] <> 0
    then 
      raise exception 'imperfect window at 2d.';
    elsif (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1 <> v_dloss_ddepdt_len[1] / v_window_len[1]
    then                                                                                                                                         
      raise exception 'imperfect dloss_ddepdt at 1d.';                                                                                           
    elsif (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1 <> v_dloss_ddepdt_len[2] / v_window_len[2]
    then 
      raise exception 'imperfect dloss_ddepdt at 2d.';
    elsif v_depdt_var_len is not null and v_depdt_var_len <> v_dloss_ddepdt_len
    then 
      raise exception 'unmatched sizes of dloss_ddepdt and depdt_var_len.';
    elsif array_ndims(i_window) = 3 and array_length(i_window, 1) <> array_length(i_dloss_ddepdt, 1)
      or array_ndims(i_window) = 4 and (array_length(i_window, 1) <> array_length(i_dloss_ddepdt, 1) or array_length(i_window, 2) <> array_length(i_dloss_ddepdt, 2))
    then 
      raise exception 'unmatch length between i_window and i_dloss_ddepdt at 3d or 4d.';
    end if;
  end if;
  
  if i_depdt_var is null 
  then 
    i_background := 
      sm_sc.fv_augmented
      (
        i_background, 
        array[-i_padding[1] + 1, -i_padding[3] + 1], 
        array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
        i_padding_value
      );
  end if;
  
  if array_ndims(i_dloss_ddepdt) = 2
  then
    
    return     
    (    
      with
      -- dloss_ddepdt 的各个独立窗口
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_heigh,
          a_cur_width,
          i_dloss_ddepdt[(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
                        [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]] -- 损失函数导数的独立窗口分组
          *` 
          -- 独立窗口矩阵点算求导 ddepdt_dindepdt          
          sm_sc.fv_d_pow_2
          ( 
            case 
              when i_depdt_var is null 
                then i_background[(a_cur_heigh - 1) * i_stride[1] + 1 : (a_cur_heigh - 1) * i_stride[1] + v_window_len[1]]
                                 [(a_cur_width - 1) * i_stride[2] + 1 : (a_cur_width - 1) * i_stride[2] + v_window_len[2]]
            end,
            i_window,
            i_depdt_var[(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
                       [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]]
          )
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_width(a_cur_width)
      ),
      -- 
      cte_ele_dloss_dindepdt as
      (
        select 
          tb_a_cur_heigh.a_cur_heigh,
          tb_a_cur_width.a_cur_width,
          coalesce
          (
            sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
              [tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1])]
              [tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2])]
            )
            , 0.0
          ) as a_dloss_dindepdt_ele
        from generate_series(1, v_background_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, v_background_len[2]) tb_a_cur_width(a_cur_width)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_heigh.a_cur_heigh between (tb_a_slice.a_cur_heigh - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_heigh * i_stride[1] + v_window_len[1]
          and tb_a_cur_width.a_cur_width between (tb_a_slice.a_cur_width - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_width * i_stride[2] + v_window_len[2]
        group by tb_a_cur_heigh.a_cur_heigh, tb_a_cur_width.a_cur_width
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_heigh,
          array_agg(a_dloss_dindepdt_ele order by a_cur_width) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_heigh
      )
      select 
        sm_sc.fv_augmented
		(
		  array_agg(a_dloss_dindepdt_y_slice order by a_cur_heigh), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
		  0.0 :: float
		)
      from cte_y_slice_dloss_dindepdt
    )
    ;  
  
  elsif array_ndims(i_dloss_ddepdt) = 3
  then
    return     
    (    
      with
      -- dloss_ddepdt 的各个独立窗口
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_heigh,
          a_cur_width,
          i_dloss_ddepdt
            [ : ]
            [(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
            [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]] -- 损失函数导数的独立窗口分组
          *` 
          -- 独立窗口矩阵点算求导 ddepdt_dindepdt
          sm_sc.fv_d_pow_2
          (
            case 
              when i_depdt_var is null 
                then i_background
                       [ : ]
                       [(a_cur_heigh - 1) * i_stride[1] + 1 : (a_cur_heigh - 1) * i_stride[1] + v_window_len[1]]
                       [(a_cur_width - 1) * i_stride[2] + 1 : (a_cur_width - 1) * i_stride[2] + v_window_len[2]]
            end,
            case 
              when array_ndims(i_window) = 2 
                then 
                  sm_sc.fv_new
                  (
                    array[i_window]
                  , array[array_length(i_dloss_ddepdt, 1), 1, 1]
                  ) 
              else i_window 
            end,
            i_depdt_var
              [ : ]
              [(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
              [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]]
          )   
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_width(a_cur_width)
      ),
      -- 
      cte_ele_dloss_dindepdt as
      (
        select 
          tb_a_cur_heigh.a_cur_heigh,
          tb_a_cur_width.a_cur_width,
          coalesce
          (
            sm_sc.fa_mx_sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
                [ : ]
                [tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1]) : tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1])]
                [tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2]) : tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2])]
            )
            , array_fill(0.0, array[array_length(i_dloss_ddepdt, 1), 1, 1])
          ) as a_dloss_dindepdt_ele
        from generate_series(1, v_background_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, v_background_len[2]) tb_a_cur_width(a_cur_width)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_heigh.a_cur_heigh between (tb_a_slice.a_cur_heigh - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_heigh * i_stride[1] + v_window_len[1]
          and tb_a_cur_width.a_cur_width between (tb_a_slice.a_cur_width - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_width * i_stride[2] + v_window_len[2]
        group by tb_a_cur_heigh.a_cur_heigh, tb_a_cur_width.a_cur_width
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_heigh,
          sm_sc.fa_mx_concat_x3(a_dloss_dindepdt_ele order by a_cur_width) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_heigh
      )
      select 
        sm_sc.fv_augmented
		(
		  sm_sc.fa_mx_concat_x(a_dloss_dindepdt_y_slice order by a_cur_heigh), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
		  0.0 :: float
		)
      from cte_y_slice_dloss_dindepdt
    )
    ;
  
  elsif array_ndims(i_dloss_ddepdt) = 4
  then
    return     
    (    
      with
      -- dloss_ddepdt 的各个独立窗口
      cte_slice_dloss_dindepdt_ex as
      (
        select 
          a_cur_heigh,
          a_cur_width,
          i_dloss_ddepdt
            [ : ]
            [ : ]
            [(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
            [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]] -- 损失函数导数的独立窗口分组
          *` 
          -- 独立窗口矩阵点算求导 ddepdt_dindepdt
          sm_sc.fv_d_pow_2
          (
            case 
              when i_depdt_var is null 
                then i_background
                       [ : ]
                       [ : ]
                       [(a_cur_heigh - 1) * i_stride[1] + 1 : (a_cur_heigh - 1) * i_stride[1] + v_window_len[1]]
                       [(a_cur_width - 1) * i_stride[2] + 1 : (a_cur_width - 1) * i_stride[2] + v_window_len[2]]
            end,
            case 
              when array_ndims(i_window) = 2 
                then 
                  sm_sc.fv_new
                  (
                    array[[i_window]]
                  , array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2), 1, 1]
                  ) 
              else i_window 
            end,
            i_depdt_var
              [ : ]
              [ : ]
              [(a_cur_heigh - 1) * v_window_len[1] + 1 : a_cur_heigh * v_window_len[1]]
              [(a_cur_width - 1) * v_window_len[2] + 1 : a_cur_width * v_window_len[2]]
          )   
            as a_slice_dloss_dindepdt_ex
        from generate_series(1, (coalesce(i_padding[1], 0) + v_background_len[1] + coalesce(i_padding[2], 0) - v_window_len[1]) / i_stride[1] + 1) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, (coalesce(i_padding[3], 0) + v_background_len[2] + coalesce(i_padding[4], 0) - v_window_len[2]) / i_stride[2] + 1) tb_a_cur_width(a_cur_width)
      ),
      -- 
      cte_ele_dloss_dindepdt as
      (
        select 
          tb_a_cur_heigh.a_cur_heigh,
          tb_a_cur_width.a_cur_width,
          coalesce
          (
            sm_sc.fa_mx_sum
            (
              tb_a_slice.a_slice_dloss_dindepdt_ex
                [ : ]
                [ : ]
                [tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1]) : tb_a_cur_heigh.a_cur_heigh - ((tb_a_slice.a_cur_heigh - 1) * i_stride[1])]
                [tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2]) : tb_a_cur_width.a_cur_width - ((tb_a_slice.a_cur_width - 1) * i_stride[2])]
            )
            , array_fill(0.0, array[array_length(i_dloss_ddepdt, 1), array_length(i_dloss_ddepdt, 2), 1, 1])
          ) as a_dloss_dindepdt_ele
        from generate_series(1, v_background_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, v_background_len[2]) tb_a_cur_width(a_cur_width)
          , cte_slice_dloss_dindepdt_ex tb_a_slice
        where tb_a_cur_heigh.a_cur_heigh between (tb_a_slice.a_cur_heigh - 1) * i_stride[1] + 1 and tb_a_slice.a_cur_heigh * i_stride[1] + v_window_len[1]
          and tb_a_cur_width.a_cur_width between (tb_a_slice.a_cur_width - 1) * i_stride[2] + 1 and tb_a_slice.a_cur_width * i_stride[2] + v_window_len[2]
        group by tb_a_cur_heigh.a_cur_heigh, tb_a_cur_width.a_cur_width
      ),
      cte_y_slice_dloss_dindepdt as 
      (
        select 
          a_cur_heigh,
          sm_sc.fa_mx_concat_x4(a_dloss_dindepdt_ele order by a_cur_width) as a_dloss_dindepdt_y_slice
        from cte_ele_dloss_dindepdt
        group by a_cur_heigh
      )
      select 
        sm_sc.fv_augmented
		(
		  sm_sc.fa_mx_concat_x3(a_dloss_dindepdt_y_slice order by a_cur_heigh), 
          array[-i_padding[1] + 1, -i_padding[3] + 1], 
          array[v_background_len[1] + i_padding[2], v_background_len[2] + i_padding[4]], 
		  0.0 :: float
		)
      from cte_y_slice_dloss_dindepdt
    )
    ;
    
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
-- (
--   array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],                -- i_window                anyarray  
--   -- array[3, 3]                   ,                           -- v_window_len            int[2]    
--   array[[1.2,2,3,4,5],[3,4,5,6,7],[2,4,6,8,5],[7,5,3,4,8]] :: float[],   -- i_background            anyarray  
--   array[4, 5]                   ,                           -- v_background_len        int[2]    
--   sm_sc.fv_conv_de_pow                                         -- i_depdt_var             anyarray 
--   (
--     array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],
--     array[[1.2,2,3,4,5],[3,4,5,6,7],[2,4,6,8,5],[7,5,3,4,8]] :: float[],
--     array[1, 1]        ,           -- i_stride                int[2]    
--     array[0, 0, 0, 0]  ,           -- i_padding               int[4]    
--     0.5  :: float                  -- i_padding_value         anyelement
--   ), 
--   array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[1.2, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[1, 1]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.5  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
-- (
--   array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],                -- i_window                anyarray  
--   -- array[3, 3]                   ,                           -- v_window_len            int[2]    
--   null :: float[],  -- array[[1.2,2,3,4,5],[3,4,5,6,7],[2,4,6,8,5],[7,5,3,4,8]] :: float[],   -- i_background            anyarray  
--   array[4, 5]                   ,                           -- v_background_len        int[2]    
--   sm_sc.fv_conv_de_pow                                         -- i_depdt_var             anyarray 
--   (
--     array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],
--     array[[1.2,2,3,4,5],[3,4,5,6,7],[2,4,6,8,5],[7,5,3,4,8]] :: float[],
--     array[1, 1]        ,           -- i_stride                int[2]    
--     array[0, 0, 0, 0]  ,           -- i_padding               int[4]    
--     0.5  :: float                  -- i_padding_value         anyelement
--   ), 
--   array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[1.2, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[1, 1]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.5  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
-- (
--   array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],                        -- i_window                anyarray  
--   -- array[3, 3]                   ,                           -- v_window_len            int[2]    
--   array              
--   [[1.2, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] :: float[],     -- i_background            anyarray  
--   array[6, 9]                   ,                           -- v_background_len        int[2]    
--   null :: float[]               ,                           -- i_depdt_var             anyarray  
--   array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[1, 2, 3, 4, 5, 6, 7, 8, 9]                
--   ,[11, 12, 13, 14, 15, 16, 17, 18, 19]                
--   ,[21, 22, 23, 24, 25, 26, 27, 28, 29]                       
--   ,[31, 32, 33, 34, 35, 36, 37, 38, 39]                
--   ,[41, 42, 43, 44, 45, 46, 47, 48, 49]           
--   ,[51, 52, 53, 54, 55, 56, 57, 58, 59]] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.5  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
-- (
--   array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],                        -- i_window                anyarray  
--   -- array[3, 3]                   ,                           -- v_window_len            int[2]    
--   array              
--   [[[1.2, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1]                
--   ,[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--   ,[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--   ,[3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--   ,[4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--   ,[5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]]] :: float[],     -- i_background            anyarray  
--   array[6, 9]                   ,                           -- v_background_len        int[2]    
--   null :: float[]               ,                           -- i_depdt_var             anyarray  
--   array[6, 9]                   ,                           -- i_depdt_var_len         int[2]    
--   array              
--   [[[1.2, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1]                
--   ,[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--   ,[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--   ,[3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--   ,[4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--   ,[5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]]] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.5  :: float                                             -- i_padding_value         anyelement
-- );

-- select sm_sc.fv_d_conv_de_pow_dloss_dindepdt_2
-- (
--   array[[1.3,4,7],[2,5,8],[3,6,9]] :: float[],                 -- i_window                anyarray   -- array[[[1.3,4,7],[2,5,8],[3,6,9]],[[1.3,4,7],[2,5,8],[3,6,9]]]
--   -- array[3, 3]                   ,                           -- v_window_len            int[2]    
--   array              
--   [
--     [
--      [1.2, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1]                
--     ,[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--     ,[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--     ,[3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--     ,[4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--     ,[5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--     ]
--   , [
--      [1.2, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1]                
--     ,[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--     ,[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--     ,[3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--     ,[4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--     ,[5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--     ]
--   ] :: float[],     -- i_background            anyarray  
--   array[2, 6, 9]                   ,                           -- v_background_len        int[2]
--   null :: float[]               ,                           -- i_depdt_var             anyarray 
--   array[2, 6, 9]                   ,                           -- i_depdt_var_len         int[2]
--   array              
--   [
--     [
--      [1.2, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1]                
--     ,[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--     ,[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--     ,[3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--     ,[4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--     ,[5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--     ]
--   , [
--      [1.2, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1]                
--     ,[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]                
--     ,[2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9]                       
--     ,[3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9]                
--     ,[4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9]           
--     ,[5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9]
--     ]
--   ] :: float[],        -- i_dloss_ddepdt          anyarray  
--   array[3, 3]        ,                                      -- i_stride                int[2]    
--   array[0, 0, 0, 0]  ,                                      -- i_padding               int[4]    
--   0.5  :: float                                             -- i_padding_value         anyelement
-- );
