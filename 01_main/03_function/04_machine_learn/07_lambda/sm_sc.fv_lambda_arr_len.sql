-- drop function if exists sm_sc.fv_lambda_arr_len(bigint, varchar(64), int[2], int[2], float[][]);
create or replace function sm_sc.fv_lambda_arr_len
(
  i_node_no  bigint,
  i_lambda                    varchar(64)                      ,
  i_input_arr_params_len      int[2]                           ,
  i_co_value_len              int[2]             default null  ,      -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立
  i_input_arr_asso            float[]         default null       
)
returns int[2]
as
$$
declare 
  v_arr_asso int[] := i_input_arr_asso ;
  
begin
  -- 审计各参数各维度长度是否匹配
  if i_lambda = 'prod_mx'
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0 
      and i_input_arr_params_len[2] > 0 and coalesce(i_co_value_len[2], v_arr_asso[3]) > 0
      and i_input_arr_params_len[2] = coalesce(i_co_value_len[1], v_arr_asso[2]) 
    then 
      return 
        -- v_arr_asso[1] :: int                                                   -- 规约：存放 array_length(i_x, 1)
        -- v_arr_asso[2] :: int                                                   -- 规约：存放 array_length(i_x, 2), 也即 array_length(i_w, 1)
        -- v_arr_asso[3] :: int                                                   -- 规约：存放 array_length(i_w, 2)
        array[i_input_arr_params_len[1], coalesce(i_co_value_len[2], v_arr_asso[3])];
    else
      raise exception 'unmatch p1, p2.  i_lambda: %; i_input_arr_params_len: %; i_co_value_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, i_co_value_len, v_arr_asso;
    end if;

  elsif i_lambda = 'conv_2d'
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_co_value_len[1] = 1 and i_co_value_len[2] > 0
      and v_arr_asso[2] * v_arr_asso[3] in (i_co_value_len[2] - 1, i_co_value_len[2])
      and i_input_arr_params_len[2] % (v_arr_asso[1]) = 0
      and (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], i_co_value_len[2] / v_arr_asso[3])) % coalesce(v_arr_asso[4], 1) = 0
      and (i_input_arr_params_len[2] / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], i_co_value_len[2] / v_arr_asso[2])) % coalesce(v_arr_asso[5], 1) = 0
    then 
      return
        -- v_arr_asso[1]                                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
        -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
        -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
        -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
        -- coalesce(v_arr_asso[10] :: float ,0.0              )       -- 规约：存放 i_padding_value
        array
        [
          i_input_arr_params_len[1],
          ((i_input_arr_params_len[2] / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], i_co_value_len[2] / v_arr_asso[2])) / coalesce(v_arr_asso[5], 1) + 1)      
          * ((v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], i_co_value_len[1] / v_arr_asso[3])) / coalesce(v_arr_asso[4], 1) + 1)     
        ];
    else
      raise exception 'unmatch p1, p2.  i_lambda: %; i_input_arr_params_len: %; i_co_value_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, i_co_value_len, v_arr_asso;
    end if;

  elsif i_lambda in ('pool_max', 'pool_avg')
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_input_arr_params_len[2] % (v_arr_asso[1]) = 0
      and (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) % coalesce(v_arr_asso[4], 1) = 0
      and (i_input_arr_params_len[2] / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) % coalesce(v_arr_asso[5], 1) = 0
    then 
      return 
        -- v_arr_asso[1]                                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
        -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
        -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
        -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
        -- coalesce(v_arr_asso[10] :: float ,0.0              )       -- 规约：存放 i_padding_value
        array
        [
          i_input_arr_params_len[1],
          ((i_input_arr_params_len[2] / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - v_arr_asso[3]) / coalesce(v_arr_asso[5], 1) + 1)   
          * ((v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - v_arr_asso[2]) / coalesce(v_arr_asso[4], 1) + 1)         
        ];
    else
      raise exception 'unmatch p1.  i_lambda: %; i_input_arr_params_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, v_arr_asso;
    end if;

  elsif i_lambda = 'rand_pick_x'
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_input_arr_params_len[2] >= v_arr_asso[1]
    then 
      return 
        -- 规约：v_arr_asso[1] 存放所设置的 取样数量
        array[i_input_arr_params_len[1], v_arr_asso[1]];
    else
      raise exception 'unmatch p1.  i_lambda: %; i_input_arr_params_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, v_arr_asso;
    end if;

  elsif i_lambda = 'rand_pick_y'
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_input_arr_params_len[1] >= v_arr_asso[1]
    then 
      return 
        -- 规约：v_arr_asso[1] 存放所设置的 取样数量
        array[v_arr_asso[1], i_input_arr_params_len[2]];
    else
      raise exception 'unmatch p1.  i_lambda: %; i_input_arr_params_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, v_arr_asso;
    end if;

  elsif i_lambda = 'slice_x'
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_input_arr_params_len[2] >= coalesce(v_arr_asso[2], v_arr_asso[1]) - v_arr_asso[1]
    then 
      return 
        -- 规约：v_arr_asso[1 : 2] 存放所设置的切片位置上下界
        array[i_input_arr_params_len[1], coalesce(v_arr_asso[2], v_arr_asso[1]) - v_arr_asso[1] + 1];
    else
      raise exception 'unmatch p1.  i_lambda: %; i_input_arr_params_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, v_arr_asso;
    end if;

  elsif i_lambda = 'slice_y'
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_input_arr_params_len[1] >= coalesce(v_arr_asso[2], v_arr_asso[1]) - v_arr_asso[1]
    then 
      return 
        -- 规约：v_arr_asso[1 : 2] 存放所设置的切片位置上下界
        array[coalesce(v_arr_asso[2], v_arr_asso[1]) - v_arr_asso[1] + 1, i_input_arr_params_len[2]];
    else
      raise exception 'unmatch p1.  i_lambda: %; i_input_arr_params_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, v_arr_asso;
    end if;

  elsif i_lambda in ('add', 'mul', 'mod', 'pow', 'log')
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and i_co_value_len[1] > 0 and i_co_value_len[2] > 0
      and (i_input_arr_params_len[1] = i_co_value_len[1] or least(i_input_arr_params_len[1], i_co_value_len[1]) = 1)
      and (i_input_arr_params_len[2] = i_co_value_len[2] or least(i_input_arr_params_len[2], i_co_value_len[2]) = 1)
    then 
      return array[greatest(i_input_arr_params_len[1], i_co_value_len[1]), greatest(i_input_arr_params_len[2], i_co_value_len[2])];
    else
      raise exception 'unmatch p1, p2.  i_lambda: %; i_input_arr_params_len: %; i_co_value_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, i_co_value_len, v_arr_asso;
    end if;

  elsif i_lambda in ('sub', 'div')
  then
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
      and 
      (
        i_co_value_len[1] > 0 and i_co_value_len[2] > 0
          and (i_input_arr_params_len[1] = i_co_value_len[1] or least(i_input_arr_params_len[1], i_co_value_len[1]) = 1)
          and (i_input_arr_params_len[2] = i_co_value_len[2] or least(i_input_arr_params_len[2], i_co_value_len[2]) = 1)
        or i_co_value_len is null
      )
    then 
      return array[greatest(i_input_arr_params_len[1], i_co_value_len[1]), greatest(i_input_arr_params_len[2], i_co_value_len[2])];
    else
      raise exception 'unmatch p1, p2.  i_lambda: %; i_input_arr_params_len: %; i_co_value_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, i_co_value_len, v_arr_asso;
    end if;

  else
    if i_input_arr_params_len[1] > 0 and i_input_arr_params_len[2] > 0
    then 
      return i_input_arr_params_len;
    else
      raise exception 'unmatch p1.  i_lambda: %; i_input_arr_params_len: %; i_input_arr_asso: %;', i_lambda, i_input_arr_params_len, v_arr_asso;
    end if;

  end if;

-- exception when others then
--   raise exception 
--   ' fn: sm_sc.fv_lambda_arr_len
--     i_node_no: %
--     i_lambda: %
--     i_input_arr_params_len: %
--     i_co_value_len: %
--     v_arr_asso: %
--     sqlerrm: %
--   '
--   , i_node_no
--   , i_lambda
--   , i_input_arr_params_len
--   , i_co_value_len
--   , v_arr_asso
--   , sqlerrm;

end
$$
language plpgsql volatile
parallel safe
cost 100;



-- select 
--   sm_sc.fv_lambda_arr_len
--   (
--     'conv_2d',                                -- i_lambda              
--     array[70, 784],                           -- i_input_arr_params_len
--     array[1, 25],                              -- i_co_value_len        
--     array[28, 5, 5, 1, 1, 2, 2, 2, 2, 0]      -- v_arr_asso 
--   )

-- -- select 
-- --         array
-- --         [
-- --           i_input_arr_params_len[1],
-- --           (i_input_arr_params_len[2] / v_arr_asso[1] + coalesce(v_arr_asso[8], 0) + coalesce(v_arr_asso[9], 0) - coalesce(v_arr_asso[3], i_co_value_len[2])) / coalesce(v_arr_asso[5], 1)       
-- --           * (v_arr_asso[1] + coalesce(v_arr_asso[6], 0) + coalesce(v_arr_asso[7], 0) - coalesce(v_arr_asso[2], i_co_value_len[1])) / coalesce(v_arr_asso[4], 1)     
-- --         ]
-- -- 
-- --         -- v_arr_asso[1]                                                       -- 规约：存放 i_1d_2_2d_cnt_per_grp
-- --         -- v_arr_asso[2 : 3]                                           -- 规约：存放 i_window_len
-- --         -- coalesce(v_arr_asso[4 : 5]        ,array[1, 1]      )       -- 规约：存放 i_stride       
-- --         -- coalesce(v_arr_asso[6 : 9]        ,array[0, 0, 0, 0])       -- 规约：存放 i_padding      
-- --         -- coalesce(v_arr_asso[10] :: float ,0.0              )       -- 规约：存放 i_padding_value