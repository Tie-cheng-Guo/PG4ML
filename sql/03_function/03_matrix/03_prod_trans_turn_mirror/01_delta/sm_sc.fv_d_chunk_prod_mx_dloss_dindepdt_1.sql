-- drop function if exists sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1(float[], float[], int[], int[3]);
create or replace function sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1
(
  i_dloss_ddepdt   float[]
, i_co_value       float[]
, i_indepdt_len    int[]
, i_chunk_len      int[3]
)
returns float[]
as
$$
declare 
  v_ret  float[];
begin
  -- 对齐维度
  if array_ndims(i_dloss_ddepdt) - array_ndims(i_co_value) = 1
  then 
    i_co_value := array[i_co_value];
  elsif array_ndims(i_dloss_ddepdt) - array_ndims(i_co_value) = 2
  then 
    i_co_value := array[[i_co_value]];
  end if;
  
  if array_ndims(i_dloss_ddepdt) = 2
  then 
    v_ret :=  
    (
      with 
      cte_chunk_width as 
      (
        select 
          a_cur_heigh
        , sm_sc.fa_mx_concat_x
          (
            i_dloss_ddepdt
              [i_chunk_len[1] * (a_cur_heigh - 1) + 1 : i_chunk_len[1] * a_cur_heigh]
              [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width]
            |**| 
            (
              |^~| 
              (
                i_co_value
                  [i_chunk_len[2] * (a_cur_heigh - 1) + 1 : i_chunk_len[2] * a_cur_heigh]
                  [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width]
              )
            )
            order by a_cur_width
          ) as a_chunk_width
        from generate_series(1, array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) / i_chunk_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) / i_chunk_len[3]) tb_a_cur_width(a_cur_width)
        group by a_cur_heigh
      )
      select 
        sm_sc.fa_mx_concat_y
        (
          a_chunk_width
          order by a_cur_heigh
        )
      from cte_chunk_width
    )
    ;
  elsif array_ndims(i_dloss_ddepdt) = 3
  then 
    v_ret :=  
    (
      with 
      cte_chunk_width as 
      (
        select 
          a_cur_heigh
        , sm_sc.fa_mx_concat_x3
          (
            i_dloss_ddepdt
              [ : ]
              [i_chunk_len[1] * (a_cur_heigh - 1) + 1 : i_chunk_len[1] * a_cur_heigh]
              [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width]
            |**| 
            (
              |^~| 
              (
                i_co_value
                  [ : ]
                  [i_chunk_len[2] * (a_cur_heigh - 1) + 1 : i_chunk_len[2] * a_cur_heigh]
                  [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width]
              )
            )
            order by a_cur_width
          ) as a_chunk_width
        from generate_series(1, array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) / i_chunk_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) / i_chunk_len[3]) tb_a_cur_width(a_cur_width)
        group by a_cur_heigh
      )
      select 
        sm_sc.fa_mx_concat_x
        (
          a_chunk_width
          order by a_cur_heigh
        )
      from cte_chunk_width
    )
    ;
  elsif array_ndims(i_dloss_ddepdt) = 4
  then 
    v_ret :=  
    (
      with 
      cte_chunk_width as 
      (
        select 
          a_cur_heigh
        , sm_sc.fa_mx_concat_x4
          (
            i_dloss_ddepdt
              [ : ]
              [ : ]
              [i_chunk_len[1] * (a_cur_heigh - 1) + 1 : i_chunk_len[1] * a_cur_heigh]
              [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width]
            |**| 
            (
              |^~| 
              (
                i_co_value
                  [ : ]
                  [ : ]
                  [i_chunk_len[2] * (a_cur_heigh - 1) + 1 : i_chunk_len[2] * a_cur_heigh]
                  [i_chunk_len[3] * (a_cur_width - 1) + 1 : i_chunk_len[3] * a_cur_width]
              )
            )
            order by a_cur_width
          ) as a_chunk_width
        from generate_series(1, array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt) - 1) / i_chunk_len[1]) tb_a_cur_heigh(a_cur_heigh)
          , generate_series(1, array_length(i_dloss_ddepdt, array_ndims(i_dloss_ddepdt)) / i_chunk_len[3]) tb_a_cur_width(a_cur_width)
        group by a_cur_heigh
      )
      select 
        sm_sc.fa_mx_concat_x3
        (
          a_chunk_width
          order by a_cur_heigh
        )
      from cte_chunk_width
    )
    ;
  else
    raise exception 'unsupport ndims of i_dloss_ddepdt';
  end if;
  
  -- return
  if array_ndims(i_dloss_ddepdt) - array_length(i_indepdt_len, 1) = 1
  then 
    return sm_sc.fv_mx_descend_dim(sm_sc.fv_aggr_chunk_sum(v_ret, array[1] || i_indepdt_len), 1);
  elsif array_ndims(i_dloss_ddepdt) - array_length(i_indepdt_len, 1) = 2
  then 
    return sm_sc.fv_mx_descend_dim(sm_sc.fv_aggr_chunk_sum(v_ret, array[1, 1] || i_indepdt_len), 2);
  elsif array_ndims(i_dloss_ddepdt) = array_length(i_indepdt_len, 1)
  then 
    return v_ret;
  end if;
  
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select 
--   sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[2 * 7, 5 * 11])
--   , sm_sc.fv_new_rand(array[3 * 7, 5 * 11])
--   , array[2 * 7, 3 * 11]
--   , array[2, 3, 5]
--   )

-- select 
--   sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[3, 2 * 7, 5 * 11])
--   , sm_sc.fv_new_rand(array[3, 3 * 7, 5 * 11])
--   , array[2 * 7, 3 * 11]
--   , array[2, 3, 5]
--   )

-- select 
--   sm_sc.fv_d_chunk_prod_mx_dloss_dindepdt_1
--   (
--     sm_sc.fv_new_rand(array[2, 3, 2 * 7, 5 * 11])
--   , sm_sc.fv_new_rand(array[2, 3, 3 * 7, 5 * 11])
--   , array[2 * 7, 3 * 11]
--   , array[2, 3, 5]
--   )