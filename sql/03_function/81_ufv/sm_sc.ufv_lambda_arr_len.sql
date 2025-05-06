-- drop function if exists sm_sc.ufv_lambda_arr_len(bigint, varchar(64), int[], int[], float[], int[]);
create or replace function sm_sc.ufv_lambda_arr_len
(
  i_node_no                   bigint                          ,
  i_lambda                    varchar(64)                     ,
  i_input_p1_len              int[]                           ,
  i_input_p2_len              int[]             default null  ,      -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立
  i_input_arr_asso            float[]           default null  ,    
  i_input_p3_len              int[]             default null  
)
returns int[]
as
$$
declare 
  v_arr_asso       int[]     := i_input_arr_asso ;
  v_p1_ndims       int       := array_length(i_input_p1_len, 1);
  v_p2_ndims       int       := array_length(i_input_p2_len, 1);
  v_p3_ndims       int       := array_length(i_input_p3_len, 1);
  v_p1_len_heigh   int       := i_input_p1_len[v_p1_ndims - 1];
  v_p1_len_width   int       := i_input_p1_len[v_p1_ndims];
  v_p2_len_heigh   int       := i_input_p2_len[v_p2_ndims - 1];
  v_p2_len_width   int       := i_input_p2_len[v_p2_ndims];
  v_p3_len_heigh   int       := i_input_p3_len[v_p3_ndims - 1];
  v_p3_len_width   int       := i_input_p3_len[v_p3_ndims];
  v_n_ndims_len    int[]     := 
    case 
      when v_p1_ndims = 4 then i_input_p1_len[1 : 2] 
      when v_p1_ndims = 3 then i_input_p1_len[1 : 1]
      when v_p2_ndims = 4 then i_input_p2_len[1 : 2]
      when v_p2_ndims = 3 then i_input_p2_len[1 : 1]
      when v_p3_ndims = 4 then i_input_p3_len[1 : 2]
      when v_p3_ndims = 3 then i_input_p3_len[1 : 1]
      else null
    end;
  
begin
  -- 审计各参数各维度长度是否匹配
  if i_lambda = '81_query_from_col'
  then 
    return 
      i_input_p1_len[ : array_length(i_input_p1_len, 1) - 2] || array[1] || i_input_p1_len[array_length(i_input_p1_len, 1)]
    ;
  elsif i_lambda = '81_query_from_row'
  then 
    return 
      i_input_p1_len[ : array_length(i_input_p1_len, 1) - 1] || array[1]
    ;
  elsif i_lambda = '81_prod_mx_slice_no_backward'
  then 
    if v_p1_len_heigh > 0 and v_p1_len_width > 0 
      and v_p1_len_width > 0 and v_p2_len_width > 0
      -- and v_p1_len_width = coalesce(v_p2_len_heigh, v_arr_asso[2]) 
    then 
      return 
        v_n_ndims_len ||
        array[v_p1_len_heigh, v_p2_len_width];
    else
      raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
    end if;
    
  elsif i_lambda = '81_prod_mx_chunk'
  then 
    if v_p1_len_heigh > 0 and v_p1_len_width > 0 
      and v_p1_len_width > 0 and v_p2_len_width > 0
      and v_p1_len_heigh >= v_p3_len_heigh
      and v_p2_len_width >= v_p3_len_width
      and v_p3_ndims = greatest(v_p1_ndims, v_p2_ndims)
      and v_p1_len_width = v_p2_len_heigh
      and v_arr_asso[1] <= v_p1_len_width
    then 
      return 
        -- v_arr_asso[1] :: int                                                   -- 规约：存放 array_length(i_indepdt, 1)
        v_n_ndims_len ||
        array[v_p1_len_heigh, v_p2_len_width];
    else
      raise exception 'unmatch p1, p2.  i_node_no: %; i_lambda: %; i_input_p1_len: %; i_input_p2_len: %; i_input_arr_asso: %;', i_node_no, i_lambda, i_input_p1_len, i_input_p2_len, v_arr_asso;
    end if;
    
  else 
    raise exception 'no defination for this lambda %', i_lambda;
  end if;  

-- exception when others then
--   raise exception 
--   ' fn: sm_sc.ufv_lambda_arr_len
--     i_node_no: %
--     i_lambda: %
--     i_input_p1_len: %
--     i_input_p2_len: %
--     v_arr_asso: %
--     sqlerrm: %
--   '
--   , i_node_no
--   , i_lambda
--   , i_input_p1_len
--   , i_input_p2_len
--   , v_arr_asso
--   , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;



-- select 
--   sm_sc.ufv_lambda_arr_len
--   (
--     'conv_2d',                                -- i_lambda              
--     array[70, 784],                           -- i_input_p1_len
--     array[1, 25],                              -- i_input_p2_len        
--     array[28, 5, 5, 1, 1, 2, 2, 2, 2, 0]      -- v_arr_asso 
--   )

-- -- select 
-- --         array
-- --         [
-- --           v_p1_len_heigh,
-- --           (v_p1_len_width / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], v_p2_len_width)) / coalesce(v_arr_asso[5], 1)       
-- --           * (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], v_p2_len_heigh)) / coalesce(v_arr_asso[4], 1)     
-- --         ]
-- -- 
-- --         -- v_arr_asso[1]                                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
-- --         -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
-- --         -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
-- --         -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
-- --         -- coalesce(v_arr_asso[10] :: float ,0.0              )       -- 规约：存放 i_padding_value