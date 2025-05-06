-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_chunk_prod_mx(anyarray, anyarray, int[3]);
create or replace function sm_sc.fv_chunk_prod_mx
(
  i_left         anyarray    ,
  i_right        anyarray    ,
  i_chunk_len    int[3]      -- 三个配置分别是：i_chunk_len[1]: 分块矩阵乘法入参一的高；i_chunk_len[2]: 分块矩阵乘法入参一的宽，也即分块矩阵乘法入参二的高；i_chunk_len[3]: 分块矩阵乘法入参二的宽；
)
returns anyarray
as
$$
declare 
  v_len_left    int[]  := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
  v_len_right   int[]  := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
  v_len_depdt int[]  ;
begin
  -- set search_path to sm_sc;
  -- 审计二维长度
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_length(i_left, array_ndims(i_left) - 1) % i_chunk_len[1] <> 0
      or array_length(i_left, array_ndims(i_left)) % i_chunk_len[2] <> 0
      or array_length(i_right, array_ndims(i_right) - 1) % i_chunk_len[2] <> 0
      or array_length(i_right, array_ndims(i_right)) % i_chunk_len[3] <> 0
    then 
      raise exception 'unmatched length!';
    elsif array_length(i_left, array_ndims(i_left) - 1) / i_chunk_len[1] <> array_length(i_right, array_ndims(i_right) - 1) / i_chunk_len[2]
      or array_length(i_left, array_ndims(i_left)) / i_chunk_len[2] <> array_length(i_right, array_ndims(i_right)) / i_chunk_len[3]
    then 
      raise exception 'unperfect length for groups of chunk between i_left and i_right';
    end if;
  end if;

  v_len_depdt :=
    (
      select 
        sm_sc.__fv_mirror_y(array_agg(greatest(a_len_left, a_len_right)))
      from unnest(sm_sc.__fv_mirror_y(v_len_left), sm_sc.__fv_mirror_y(v_len_right)) tb_a_len(a_len_left, a_len_right)
    )
  ;
  
  -- 整理入参一
  if v_len_left <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 3
    then 
      i_left := array[[[i_left]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 2
    then 
      i_left := array[[i_left]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_left, 1) = 1
    then 
      i_left := array[i_left];
    end if;
    
    -- -- v_len_left := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
    -- -- 
    -- -- -- 对齐维长
    -- -- if v_len_left <> v_len_depdt
    -- -- then 
    -- --   i_left := sm_sc.fv_new(i_left, v_len_depdt / v_len_left);
    -- --   v_len_left := (select array_agg(array_length(i_left, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_left)) tb_a_cur_dim(a_cur_dim));
    -- -- end if;
  end if;
  
  -- 整理入参二
  if v_len_right <> v_len_depdt
  then 
    -- 对齐维度
    if array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 3
    then 
      i_right := array[[[i_right]]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 2
    then 
      i_right := array[[i_right]];
    elsif array_length(v_len_depdt, 1) - array_length(v_len_right, 1) = 1
    then 
      i_right := array[i_right];
    end if;
    
    -- -- v_len_right := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
    -- -- 
    -- -- -- 对齐维长
    -- -- if v_len_right <> v_len_depdt
    -- -- then 
    -- --   i_right := sm_sc.fv_new(i_right, v_len_depdt / v_len_right);
    -- --   v_len_right := (select array_agg(array_length(i_right, a_cur_dim) order by a_cur_dim) from generate_series(1, array_ndims(i_right)) tb_a_cur_dim(a_cur_dim));
    -- -- end if;
  end if;

  if array_ndims(i_left) = 2
  then
    return 
      (
        with
        cte_grp_heigh as 
        (
          select 
            a_cur_heigh,
            sm_sc.fa_mx_concat_x
            (
              i_left
                [i_chunk_len[1] * (a_cur_heigh - 1) + 1 : i_chunk_len[1] * a_cur_heigh]
                [i_chunk_len[2] * (a_cur_width - 1) + 1 : i_chunk_len[2] * a_cur_width] 
              |**| 
              i_right
                [i_chunk_len[2] * (a_cur_heigh - 1) + 1 : i_chunk_len[2] * a_cur_heigh]
                [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width] 
              order by a_cur_width
            ) as a_grp_heigh
          from generate_series(1, array_length(i_left, array_ndims(i_left) - 1) / i_chunk_len[1]) tb_a_cur_heigh(a_cur_heigh)
            , generate_series(1, array_length(i_left, array_ndims(i_left)) / i_chunk_len[2]) tb_a_cur_width(a_cur_width)
          group by a_cur_heigh
        )
        select 
          sm_sc.fa_mx_concat_y(a_grp_heigh order by a_cur_heigh)
        from cte_grp_heigh
      )
    ;
    
  elsif array_ndims(i_left) = 3
  then
    return 
      (
        with
        cte_grp_heigh as 
        (
          select 
            a_cur_heigh,
            sm_sc.fa_mx_concat_x3
            (
              i_left
                [ : ]
                [i_chunk_len[1] * (a_cur_heigh - 1) + 1 : i_chunk_len[1] * a_cur_heigh]
                [i_chunk_len[2] * (a_cur_width - 1) + 1 : i_chunk_len[2] * a_cur_width] 
              |**| 
              i_right
                [ : ]
                [i_chunk_len[2] * (a_cur_heigh - 1) + 1 : i_chunk_len[2] * a_cur_heigh]
                [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width] 
              order by a_cur_width
            ) as a_grp_heigh
          from generate_series(1, array_length(i_left, array_ndims(i_left) - 1) / i_chunk_len[1]) tb_a_cur_heigh(a_cur_heigh)
            , generate_series(1, array_length(i_left, array_ndims(i_left)) / i_chunk_len[2]) tb_a_cur_width(a_cur_width)
          group by a_cur_heigh
        )
        select 
          sm_sc.fa_mx_concat_x(a_grp_heigh order by a_cur_heigh)
        from cte_grp_heigh
      )
    ;
    
  elsif array_ndims(i_left) = 4
  then
    return 
      (
        with
        cte_grp_heigh as 
        (
          select 
            a_cur_heigh,
            sm_sc.fa_mx_concat_x4
            (
              i_left
                [ : ]
                [ : ]
                [i_chunk_len[1] * (a_cur_heigh - 1) + 1 : i_chunk_len[1] * a_cur_heigh]
                [i_chunk_len[2] * (a_cur_width - 1) + 1 : i_chunk_len[2] * a_cur_width] 
              |**| 
              i_right
                [ : ]
                [ : ]
                [i_chunk_len[2] * (a_cur_heigh - 1) + 1 : i_chunk_len[2] * a_cur_heigh]
                [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width] 
              order by a_cur_width
            ) as a_grp_heigh
          from generate_series(1, array_length(i_left, array_ndims(i_left) - 1) / i_chunk_len[1]) tb_a_cur_heigh(a_cur_heigh)
            , generate_series(1, array_length(i_left, array_ndims(i_left)) / i_chunk_len[2]) tb_a_cur_width(a_cur_width)
          group by a_cur_heigh
        )
        select 
          sm_sc.fa_mx_concat_x3(a_grp_heigh order by a_cur_heigh)
        from cte_grp_heigh
      )
    ;
    
  -- 审计二维长度
  else
    raise exception 'no method for such length!  L_Dim: %; R_Dim: %;', array_dims(i_left), array_dims(i_right);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_chunk_prod_mx
--   (
--     array_fill(random(), array[2 * 7, 3 * 11])
--   , array_fill(random(), array[3 * 7, 5 * 11])
--   , array[2, 3, 5]
--   );  -- 期望规格：array[2 * 7, 5 * 11]
-- select sm_sc.fv_chunk_prod_mx
--   (
--     array_fill(random(), array[3, 2 * 7, 3 * 11])
--   , array_fill(random(), array[3, 3 * 7, 5 * 11])
--   , array[2, 3, 5]
--   );  -- 期望规格：array[3, 2 * 7, 5 * 11]
-- select sm_sc.fv_chunk_prod_mx
--   (
--     array_fill(random(), array[2, 3, 2 * 7, 3 * 11])
--   , array_fill(random(), array[2, 3, 3 * 7, 5 * 11])
--   , array[2, 3, 5]
--   );  -- 期望规格：array[2, 3, 2 * 7, 5 * 11]