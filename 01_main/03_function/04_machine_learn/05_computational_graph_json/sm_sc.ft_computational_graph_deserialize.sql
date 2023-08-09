-- drop function if exists sm_sc.ft_computational_graph_deserialize(jsonb);
create or replace function sm_sc.ft_computational_graph_deserialize
(
  i_opr_chain     jsonb
)
returns    
  table
  (
    o_out_param              varchar(64)      ,
    o_in_param               varchar(64)      ,
    o_in_value               float    ,
    o_param_loc              int              ,
    o_out_opr                varchar(64)
  )
as
$$
-- declare
begin
  return query
    with
    recursive cte_a_back_oprs as
    (
      select
        ''::varchar(64) as out_param,
        trim((select jsonb_path_query(i_opr_chain, '$.out_param')::varchar(64) limit 1), '"')::varchar(64) as in_param,
        case 
          -- 常量在 json 内取值
          when jsonb_path_exists(i_opr_chain, '$.out_value') 
            then (select jsonb_path_query(i_opr_chain, '$.out_value') limit 1)::float 
          else null::float 
        end
        as in_value,
        1::int as param_loc,
        ''::varchar(64) as out_opr,
        trim((select jsonb_path_query(i_opr_chain, '$.opr')::varchar(64) limit 1), '"')::varchar(64) as back_opr,
        jsonb_path_query_array(i_opr_chain, '$.in_params[*]') as back_params
      union all
      select 
        tb_a_forward.in_param as out_param,
        case 
          -- 参数 在 json 内取 in_name
          when jsonb_path_exists(in_param_ex, '$.out_value') or jsonb_path_exists(in_param_ex, '$.out_param')
            then trim((select jsonb_path_query(in_param_ex, '$.out_param') limit 1) ::varchar(64), '"')::varchar(64) 
          -- 中间结果 生成临时 in_name
          else md5((select jsonb_path_query(in_param_ex, '$.opr')::text limit 1) || '||' || (select jsonb_path_query(in_param_ex, '$.in_params[*]')::text limit 1))::varchar(64)
          end 
        as in_param,
        case 
          when jsonb_path_exists(in_param_ex, '$.out_value') 
            then (select jsonb_path_query(in_param_ex, '$.out_value') limit 1) 
          else null 
        end ::float 
        as in_value,
        row_number() over(partition by tb_a_forward.in_param)::int as param_loc,
        tb_a_forward.back_opr as out_opr,
        trim((select jsonb_path_query(in_param_ex, '$.opr')::varchar(64) limit 1), '"')::varchar(64) as back_opr,
        jsonb_path_query_array(in_param_ex, '$.in_params[*]') as back_params
      from cte_a_back_oprs tb_a_forward, jsonb_path_query(back_params, '$[*]') tb_a_in_params(in_param_ex)
    )
    select
      out_param                    :: varchar(64)                                   ,
      max(in_param)                :: varchar(64)                 as  in_param      ,
      max(in_value)                :: float               as  in_value      ,
      param_loc                    :: int                                           ,
      coalesce(max(out_opr), '')   :: varchar(64)                 as out_opr
    from cte_a_back_oprs
    group by out_param, param_loc;
end
$$
language plpgsql volatile
cost 100;



-- -- select pgv_set('vars', 'a_opr_chain_01', 
-- -- '
-- -- {
-- --   "out_param": "v_y_in",
-- --   "opr": "sm_sc.fv_opr_add",
-- --   "in_params": 
-- --   [
-- --     {
-- --       "out_param": "w0_in"
-- --     },
-- --     {
-- --       "opr": "sm_sc.fv_opr_mul",
-- --       "in_params": 
-- --       [
-- --         {
-- --           "out_param": "w1_in"
-- --         },
-- --         {
-- --           "out_param": "v_x1_in"
-- --         }
-- --       ]
-- --     },
-- --     {
-- --       "opr": "sm_sc.fv_opr_mul",
-- --       "in_params": 
-- --       [
-- --         {
-- --           "out_param": "w2_in"
-- --         },
-- --         {
-- --           "opr": "sm_sc.fv_opr_pow",
-- --           "in_params": 
-- --           [
-- --             {
-- --               "out_param": "v_x1_in"
-- --             },
-- --             {
-- --               "out_value": 2
-- --             }
-- --           ]
-- --         }
-- --       ]
-- --     },
-- --     {
-- --       "opr": "sm_sc.fv_opr_mul",
-- --       "in_params": 
-- --       [
-- --         {
-- --           "out_param": "w3_in"
-- --         },
-- --         {
-- --           "opr": "sm_sc.fv_opr_pow",
-- --           "in_params": 
-- --           [
-- --             {
-- --               "out_param": "v_x1_in"
-- --             },
-- --             {
-- --               "out_value": 3
-- --             }
-- --           ]
-- --         }
-- --       ]
-- --     }
-- --   ]
-- -- }
-- -- '::jsonb);

-- select * from sm_sc.ft_computational_graph_deserialize(pgv_get('vars', 'a_opr_chain_01', NULL::jsonb))

-- -----------------------------------------------------------------------------------------------
-- -- select pgv_set('vars', 'a_opr_chain', 
-- -- '
-- -- {
-- --   "out_param": "v_z_in",
-- --   "opr": "sm_sc.fv_opr_add",
-- --   "in_params": 
-- --   [
-- --     {
-- --       "opr": "sm_sc.fv_opr_mul",
-- --       "in_params": 
-- --       [
-- --         {
-- --           "out_param": "v_x_in"
-- --         },
-- --         {
-- --           "out_param": "v_y_in"
-- --         }
-- --       ]
-- --     },
-- --     {
-- --       "opr": "sm_sc.fv_opr_exp",
-- --       "in_params": 
-- --       [
-- --         {
-- --           "opr": "sm_sc.fv_opr_mul",
-- --           "in_params": 
-- --           [
-- --             {
-- --               "out_param": "v_x_in"
-- --             },
-- --             {
-- --               "out_param": "v_y_in"
-- --             }
-- --           ]
-- --         }
-- --       ]
-- --     }
-- --   ]
-- -- }
-- -- '::jsonb);

-- select
--   o_out_param                                         ,
--   max(o_in_param)    as    o_in_param                 ,
--   max(o_in_value)    as    o_in_value                 ,
--   o_param_loc                                             ,
--   max(o_out_opr)   as    o_out_opr
-- from sm_sc.ft_computational_graph_deserialize(pgv_get('vars', 'a_opr_chain', NULL::jsonb))
-- group by o_out_param, o_param_loc


-- -----------------------------------------------------------------------------------------------
-- -- select pgv_set('vars', 'a_opr_chain_6', 
-- -- '
-- -- {
-- --   "out_param": "v_y_in",
-- --   "opr": "sm_sc.fv_opr_pow",
-- --   "in_params": 
-- --   [
-- --     {
-- --       "out_param": "v_x_in"
-- --     },
-- --     {
-- --       "out_param": "v_x_in"
-- --     }
-- --   ]
-- -- }
-- -- '::jsonb);

-- select
--   o_out_param                                         ,
--   max(o_in_param)    as    o_in_param                 ,
--   max(o_in_value)    as    o_in_value                 ,
--   o_param_loc                                             ,
--   max(o_out_opr)   as    o_out_opr
-- from sm_sc.ft_computational_graph_deserialize(pgv_get('vars', 'a_opr_chain_6', NULL::jsonb))
-- group by o_out_param, o_param_loc


-- ----------------------------------------------------------------------------------------------------------------------------------------------
-- -- 清理多余括号
-- drop function if exists sm_sc.fv_clean_bracket(text);
create or replace function sm_sc.fv_clean_bracket
(
  i_opr_algebra text
)
returns text
as
$$
declare -- here
  v_rgx_bracket_var         text    :=    '(?<![a-zA-Z0-9_\.])\(([^\(\)]+?)\)'   ;
  v_rgx_bracket2_fn_vars    text    :=    '\((\([^\(\)]+?\))\)'                  ;
begin
  -- 替换以单变量为内容的括号，其中单入参函数的文法，做否定预查，不需要保留括号
  while i_opr_algebra ~ v_rgx_bracket_var
  loop
    select regexp_replace(i_opr_algebra, v_rgx_bracket_var, '\1', 'g') into i_opr_algebra;
  end loop;

  -- 替换以函数变量为内容的括号，保留一副括号
  while i_opr_algebra ~ v_rgx_bracket2_fn_vars
  loop
    select regexp_replace(i_opr_algebra, v_rgx_bracket2_fn_vars, '\1', 'g') into i_opr_algebra;
  end loop;

  return i_opr_algebra;
end
$$
language plpgsql stable
cost 100;

-- select sm_sc.fv_clean_bracket('fm(((v_a,v_b)))+((v_c))')



-- ----------------------------------------------------------------------------------------------------------------------------------------------
-- drop function if exists sm_sc.ft_computational_graph_deserialize(text);
create or replace function sm_sc.ft_computational_graph_deserialize
(
  i_opr_algebra     text
)
returns    
  table
  (
    o_out_param              varchar(64)      ,
    o_in_param               varchar(64)      ,
    o_in_value               float    ,
    o_param_loc              int              ,
    o_out_opr                varchar(64)
  )
as
$$
declare -- here
  -- 清理空白字符、首轮多余括号
  v_opr_algebra              text     :=   sm_sc.fv_clean_bracket(regexp_replace(i_opr_algebra, '\s', '', 'g'));
  v_reg_arr                  text[];
  v_cache_last_opr_algebra   text;

  -- 变量实体。
  v_rgx_var                  text     :=    '((?<![a-zA-Z0-9_\)])\-[0-9]+(\.?[0-9]*)?(?![a-zA-Z0-9_\(])|(?<![a-zA-Z0-9_\)])[0-9]+(\.?[0-9]*)?(?![a-zA-Z0-9_\(])|(?<![a-zA-Z0-9_\)])[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?(?![a-zA-Z0-9_\(]))';  -- 数字常量与变量引用名区分，用于后续分别装配value/param；负常数，做后向预查，保证六则运算符优先级高于负号
  -- 第零优先级函数名                       
  v_rgx_fn                   text     :=    '((?<![a-zA-Z0-9_])[a-zA-Z0-9_]([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?(?=\())';
  -- 第一优先级运算符      单目 ^ ^!               
  v_rgx_opr_l1               text     :=    '(?<=[a-zA-Z0-9_\.\)])(\^\!?)(?![a-zA-Z0-9_])';
  -- 第二优先级运算符      双目 ^ ^!                  
  v_rgx_opr_l2               text     :=    '(?<=[a-zA-Z0-9_\.\)])(\^\!?)(?=[a-zA-Z0-9_])'; 
  -- -- -- 第三优先级运算符    双目  *  /                                   
  -- --   v_rgx_opr_l3               text     :=    '(?<=[a-zA-Z0-9_\.\)])(\*\/)(?=[a-zA-Z0-9_])';      
  -- 第四优先级运算符      单目 -                                           
  v_rgx_opr_l4               text     :=    '(?<![a-zA-Z0-9_\.\)])(\-)(?=[a-zA-Z0-9_])';    
  -- -- -- 第五优先级运算符    双目  +  -                                        
  -- --  v_rgx_opr_l5               text     :=    '(?<=[a-zA-Z0-9_\.\)])(\+\-)(?=[a-zA-Z0-9_])'; 
  -- -- -- 第六优先级等式运算符   双目   =                                    
  -- --  v_rgx_opr_l6               text     :=    '(?<=[a-zA-Z0-9_\.\)])(\=)(?=[a-zA-Z0-9_])';     

                                             
-- 第零优先级代数式，函数式                       
declare v_obj_rgx_fn_x             text     :=    '(' || v_rgx_fn || '(\(' || v_rgx_var || '(,' || v_rgx_var || ')*' || '\))' || ')';         
-- 第一优先级运算符代数式，自然常数幂指运算
declare v_obj_rgx_algebra_l1       text     :=    '(' || v_rgx_var || v_rgx_opr_l1 || ')';
-- 第二优先级运算符代数式，幂指运算
declare v_obj_rgx_algebra_l2       text     :=    '(' || v_rgx_var || v_rgx_opr_l2 || v_rgx_var || ')';   
-- 第三优先级运算符代数式，乘除
declare v_obj_rgx_algebra_l3       text     :=    '(' || v_rgx_var || '(\/)' || v_rgx_var || '|' || v_rgx_var || '(((\*)' || v_rgx_var || ')+))'; 
-- 第四优先级运算符代数式，负运算
declare v_obj_rgx_algebra_l4       text     :=    '(' || v_rgx_opr_l4 || v_rgx_var || ')';
-- 第五优先级运算符代数式，加减
declare v_obj_rgx_algebra_l5       text     :=    '(' || v_rgx_var || '(\-)' || v_rgx_var || '|' || v_rgx_var || '(((\+)' || v_rgx_var || ')+))';  
-- 第六优先级等式表达式，等式
declare v_obj_rgx_equation         text     :=    '(' || v_rgx_var || '=' || v_rgx_var || ')';

declare v_loop_no_01               int      :=    1;
declare v_loop_no_02               int      :=    1;
declare v_sess_id                  bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32) :=    replace(gen_random_uuid()::char(36), '-', '')::char(32);
   
begin

  -- -- -- 缓存计算关系
  -- -- -- drop table if exists sm_sc._vt_fn_compu_graph_deseri__graph;
  -- -- create temp table sm_sc._vt_fn_compu_graph_deseri__graph
  -- -- (
  -- --   out_param            varchar(64)      ,
  -- --   in_param             varchar(64)      ,
  -- --   in_value             float    ,
  -- --   param_loc            int              ,
  -- --   out_opr              varchar(64)      ,
  -- --   unique (out_param, param_loc) 
  -- -- );

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 00 -- v_opr_algebra: %', v_opr_algebra;

  -- 代入化简，直至不在化简结果不再变化，或直至最简
  while (v_opr_algebra <> v_cache_last_opr_algebra or v_cache_last_opr_algebra is null)
    and (
          v_opr_algebra !~ ('^' || v_rgx_var || '$')
          or v_opr_algebra !~ ('^' || v_obj_rgx_equation || '$')
        )
    and v_loop_no_01 <= 100
  loop 
    v_loop_no_01   :=  v_loop_no_01  +  1;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 01 -- v_opr_algebra: %', v_opr_algebra;

    v_cache_last_opr_algebra := v_opr_algebra;
    -- 第零优先级优先识别函数式
    v_loop_no_02   :=  1;
    while v_opr_algebra ~ v_obj_rgx_fn_x
      and v_loop_no_02 <= 100
    loop
      v_loop_no_02   :=  v_loop_no_02  +  1;
      -- 逐一发现
      select regexp_matches(v_opr_algebra, v_obj_rgx_fn_x) into v_reg_arr;
    
      -- 解析
      if not exists (select from sm_sc._vt_fn_compu_graph_deseri__graph where out_param = md5(v_reg_arr[1]) and sess_id = v_sess_id)
      then
        insert into sm_sc._vt_fn_compu_graph_deseri__graph
        (
          sess_id          ,
          out_param         ,
          in_param          ,
          in_value          ,
          param_loc         ,
          out_opr   
        )
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when a_in_param[1] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and a_in_param[1] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then a_in_param[1] end
                                       as   in_param,
          case when a_in_param[1] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then a_in_param[1]::float end
                                       as   in_value,
          row_number() over()          as   param_loc,
          case v_reg_arr[2]
            when 'add'        then 'sm_sc.fv_opr_add'
            when 'sub'        then 'sm_sc.fv_opr_sub'
            when 'mul'        then 'sm_sc.fv_opr_mul'
            when 'div'        then 'sm_sc.fv_opr_div'
            when 'pow'        then 'sm_sc.fv_opr_pow'
            when 'power'      then 'sm_sc.fv_opr_pow'
            when 'exp'        then 'sm_sc.fv_opr_exp'
            when 'log'        then 'sm_sc.fv_opr_log'
            when 'ln'         then 'sm_sc.fv_opr_ln'
            when 'sin'        then 'sm_sc.fv_sin'
            when 'cos'        then 'sm_sc.fv_cos'
            when 'tan'        then 'sm_sc.fv_tan'
            when 'cot'        then 'sm_sc.fv_cot'
            when 'sec'        then 'sm_sc.fv_sec'
            when 'csc'        then 'sm_sc.fv_csc'
            when 'asin'       then 'sm_sc.fv_asin'
            when 'acos'       then 'sm_sc.fv_acos'
            when 'atan'       then 'sm_sc.fv_atan'
            when 'acot'       then 'sm_sc.fv_acot'
            when 'asec'       then 'sm_sc.fv_asec'
            when 'acsc'       then 'sm_sc.fv_acsc'
            when 'sinh'       then 'sm_sc.fv_sinh'
            when 'cosh'       then 'sm_sc.fv_cosh'
            when 'tanh'       then 'sm_sc.fv_tanh'
            when 'asinh'      then 'sm_sc.fv_asinh'
            when 'acosh'      then 'sm_sc.fv_acosh'
            when 'atanh'      then 'sm_sc.fv_atanh'
            else v_reg_arr[2]
          end
                                       as out_opr
        from regexp_matches(v_reg_arr[4], v_rgx_var, 'g') as tb_a_in_params(a_in_param)
        ;
      end if;
    
      -- 即以识别处理的表达式替换为中间变量，准备下次识别
      select 
        sm_sc.fv_clean_bracket
        (
          regexp_replace
          (
            v_opr_algebra
--            , v_reg_arr[1]
            , regexp_replace
              (
                v_reg_arr[1]
                , '([\+\-\*\/\.\^\!\(\)\,\:\<\>\[\]\\])'
                , '\\\1'
                , 'g'
              )
            , md5(v_reg_arr[1])
            , 'g'
          )
        ) 
        into v_opr_algebra;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 011 -- v_opr_algebra: %', v_opr_algebra;
    end loop;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 02 -- v_opr_algebra: %', v_opr_algebra;
    
    -- 第一优先识别代数式
    v_loop_no_02   :=  1;
    while v_opr_algebra ~ v_obj_rgx_algebra_l1
      and v_loop_no_02 <= 100
    loop
      v_loop_no_02   :=  v_loop_no_02  +  1;
      -- 逐一发现
      select regexp_matches(v_opr_algebra, v_obj_rgx_algebra_l1) into v_reg_arr;
    
      -- 解析
      if not exists (select from sm_sc._vt_fn_compu_graph_deseri__graph where out_param = md5(v_reg_arr[1]) and sess_id = v_sess_id)
      then
        insert into sm_sc._vt_fn_compu_graph_deseri__graph
        (
          sess_id          ,
          out_param         ,
          in_param          ,
          in_value          ,
          param_loc         ,
          out_opr   
        )
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when v_reg_arr[2] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_reg_arr[2] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[2] end
                                       as   in_param,
          case when v_reg_arr[2] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[2]::float end
                                       as   in_value,
          1                            as   param_loc,
          case v_reg_arr[6]
            when '^'        then 'sm_sc.fv_opr_exp'
            when '^!'       then 'sm_sc.fv_opr_ln'
          end
                                       as out_opr
        ;
      end if;

      -- 即以识别处理的表达式替换为中间变量，准备下次识别
      select 
        sm_sc.fv_clean_bracket
        (
          regexp_replace
          (
            v_opr_algebra
--            , v_reg_arr[1]
            , regexp_replace
              (
                v_reg_arr[1]
                , '([\+\-\*\/\.\^\!\(\)\,\:\<\>\[\]\\])'
                , '\\\1'
                , 'g'
              )
            , md5(v_reg_arr[1])
            , 'g'
          )
        ) 
        into v_opr_algebra;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 021 -- v_opr_algebra: %', v_opr_algebra;
    end loop;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 03 -- v_opr_algebra: %', v_opr_algebra;
    -- 第二优先识别代数式
    v_loop_no_02   :=  1;
    while v_opr_algebra ~ v_obj_rgx_algebra_l2
      and v_loop_no_02 <= 100
    loop
      v_loop_no_02   :=  v_loop_no_02  +  1;
      -- 逐一发现
      select regexp_matches(v_opr_algebra, v_obj_rgx_algebra_l2) into v_reg_arr;
    
      -- 解析
      if not exists (select from sm_sc._vt_fn_compu_graph_deseri__graph where out_param = md5(v_reg_arr[1]) and sess_id = v_sess_id)
      then
        insert into sm_sc._vt_fn_compu_graph_deseri__graph
        (
          sess_id          ,
          out_param         ,
          in_param          ,
          in_value          ,
          param_loc         ,
          out_opr   
        )
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when v_reg_arr[2] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_reg_arr[2] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[2] end
                                       as   in_param,
          case when v_reg_arr[2] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[2]::float end
                                       as   in_value,
          1                            as   param_loc,
          case v_reg_arr[6]
            when '^'        then 'sm_sc.fv_opr_pow'
            when '^!'       then 'sm_sc.fv_opr_log'
          end
                                       as out_opr
        union all
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when v_reg_arr[7] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_reg_arr[7] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[7] end
                                       as   in_param,
          case when v_reg_arr[7] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[7]::float end
                                       as   in_value,
          2                            as   param_loc,
          case v_reg_arr[6]
            when '^'        then 'sm_sc.fv_opr_pow'
            when '^!'       then 'sm_sc.fv_opr_log'
          end
                                       as out_opr
        ;
      end if;
    
      -- 即以识别处理的表达式替换为中间变量，准备下次识别
      select 
        sm_sc.fv_clean_bracket
        (
          regexp_replace
          (
            v_opr_algebra
--            , v_reg_arr[1]
            , regexp_replace
              (
                v_reg_arr[1]
                , '([\+\-\*\/\.\^\!\(\)\,\:\<\>\[\]\\])'
                , '\\\1'
                , 'g'
              )
            , md5(v_reg_arr[1])
            , 'g'
          )
        ) 
        into v_opr_algebra;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 031 -- v_opr_algebra: %', v_opr_algebra;
    end loop;
 
-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 04 -- v_opr_algebra: %', v_opr_algebra;   
    -- 第三优先识别代数式
    v_loop_no_02   :=  1;
    while v_opr_algebra ~ v_obj_rgx_algebra_l3
      and v_loop_no_02 <= 100
    loop
      v_loop_no_02   :=  v_loop_no_02  +  1;
      -- 逐一发现
      select regexp_matches(v_opr_algebra, v_obj_rgx_algebra_l3) into v_reg_arr;
    
      -- 解析
      if not exists (select from sm_sc._vt_fn_compu_graph_deseri__graph where out_param = md5(v_reg_arr[1]) and sess_id = v_sess_id)
      then
        insert into sm_sc._vt_fn_compu_graph_deseri__graph
        (
          sess_id          ,
          out_param         ,
          in_param          ,
          in_value          ,
          param_loc         ,
          out_opr   
        )
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when coalesce(v_reg_arr[2], v_reg_arr[11]) ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and coalesce(v_reg_arr[2], v_reg_arr[11]) !~ '^\-?[0-9]+(\.?[0-9]*)?$' then coalesce(v_reg_arr[2], v_reg_arr[11]) end
                                       as   in_param,
          case when coalesce(v_reg_arr[2], v_reg_arr[11]) ~ '^\-?[0-9]+(\.?[0-9]*)?$' then coalesce(v_reg_arr[2], v_reg_arr[11])::float end
                                       as   in_value,
          1                            as   param_loc,
          case coalesce(v_reg_arr[6], v_reg_arr[17])
            when '*'        then 'sm_sc.fv_opr_mul'
            when '/'        then 'sm_sc.fv_opr_div'
          end
                                       as out_opr
        union all
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when v_reg_arr[7] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_reg_arr[7] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[7] end
                                       as   in_param,
          case when v_reg_arr[7] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[7]::float end
                                       as   in_value,
          2                            as   param_loc,
          'sm_sc.fv_opr_div'         as   out_opr
        where v_reg_arr[7] is not null
        union all
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when a_in_param[1] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and a_in_param[1] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then a_in_param[1] end
                                       as   in_param,
          case when a_in_param[1] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then a_in_param[1]::float end
                                       as   in_value,
          row_number() over () + 1     as   param_loc,
          'sm_sc.fv_opr_mul'         as   out_opr
        from regexp_matches(v_reg_arr[15], v_rgx_var, 'g')   tb_a(a_in_param)
        where v_reg_arr[15] is not null
        ;
      end if;
    
      -- 即以识别处理的表达式替换为中间变量，准备下次识别
      select 
        sm_sc.fv_clean_bracket
        (
          regexp_replace
          (
            v_opr_algebra
--            , v_reg_arr[1]
            , regexp_replace
              (
                v_reg_arr[1]
                , '([\+\-\*\/\.\^\!\(\)\,\:\<\>\[\]\\])'
                , '\\\1'
                , 'g'
              )
            , md5(v_reg_arr[1])
            , 'g'
          )
        ) 
        into v_opr_algebra;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 041 -- v_reg_arr[1]: %', v_reg_arr[1];
-- -- -- -- raise notice 'debug -- 041 -- v_opr_algebra: %', v_opr_algebra;
    end loop;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 05 -- v_opr_algebra: %', v_opr_algebra;
    -- 第四优先识别代数式
    v_loop_no_02   :=  1;
    while v_opr_algebra ~ v_obj_rgx_algebra_l4
      and v_loop_no_02 <= 100
    loop
      v_loop_no_02   :=  v_loop_no_02  +  1;
      -- 逐一发现
      select regexp_matches(v_opr_algebra, v_obj_rgx_algebra_l4) into v_reg_arr;

      -- 解析
      if not exists (select from sm_sc._vt_fn_compu_graph_deseri__graph where out_param = md5(v_reg_arr[1]) and sess_id = v_sess_id)
      then
        insert into sm_sc._vt_fn_compu_graph_deseri__graph
        (
          sess_id          ,
          out_param         ,
          in_param          ,
          in_value          ,
          param_loc         ,
          out_opr   
        )
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param  ,
          null                         as   in_param   ,
          0.0                          as   in_value   ,
          1                            as   param_loc  ,
          'sm_sc.fv_opr_sub'         as   out_opr
        union all
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param  ,
          v_reg_arr[3]                 as   in_param   ,
          null                         as   in_value   ,
          2                            as   param_loc  ,
          'sm_sc.fv_opr_sub'         as   out_opr
        ;
      end if;

      -- 即以识别处理的表达式替换为中间变量，准备下次识别
      select 
        sm_sc.fv_clean_bracket
        (
          regexp_replace
          (
            v_opr_algebra
--            , v_reg_arr[1]
            , regexp_replace
              (
                v_reg_arr[1]
                , '([\+\-\*\/\.\^\!\(\)\,\:\<\>\[\]\\])'
                , '\\\1'
                , 'g'
              )
            , md5(v_reg_arr[1])
            , 'g'
          )
        ) 
        into v_opr_algebra;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 051 -- v_opr_algebra: %', v_opr_algebra;
    end loop; 

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 06 -- v_opr_algebra: %', v_opr_algebra;
    -- 第五优先识别代数式
    v_loop_no_02   :=  1;
    while v_opr_algebra ~ v_obj_rgx_algebra_l5
      and v_loop_no_02 <= 100
    loop
      v_loop_no_02   :=  v_loop_no_02  +  1;
      -- 逐一发现
      select regexp_matches(v_opr_algebra, v_obj_rgx_algebra_l5) into v_reg_arr;
    
      -- 解析
      if not exists (select from sm_sc._vt_fn_compu_graph_deseri__graph where out_param = md5(v_reg_arr[1]) and sess_id = v_sess_id)
      then
        insert into sm_sc._vt_fn_compu_graph_deseri__graph
        (
          sess_id          ,
          out_param         ,
          in_param          ,
          in_value          ,
          param_loc         ,
          out_opr   
        )
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when coalesce(v_reg_arr[2], v_reg_arr[11]) ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and coalesce(v_reg_arr[2], v_reg_arr[11]) !~ '^\-?[0-9]+(\.?[0-9]*)?$' then coalesce(v_reg_arr[2], v_reg_arr[11]) end
                                       as   in_param,
          case when coalesce(v_reg_arr[2], v_reg_arr[11]) ~ '^\-?[0-9]+(\.?[0-9]*)?$' then coalesce(v_reg_arr[2], v_reg_arr[11])::float end
                                       as   in_value,
          1                            as   param_loc,
          case coalesce(v_reg_arr[6], v_reg_arr[17])
            when '+'        then 'sm_sc.fv_opr_add'
            when '-'        then 'sm_sc.fv_opr_sub'
          end
                                       as   out_opr
        union all
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when v_reg_arr[7] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_reg_arr[7] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[7] end
                                       as   in_param,
          case when v_reg_arr[7] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[7]::float end
                                       as   in_value,
          2                            as   param_loc,
          'sm_sc.fv_opr_sub'         as   out_opr
        where v_reg_arr[7] is not null
        union all
        select 
          v_sess_id,
          md5(v_reg_arr[1])            as   out_param,
          case when a_in_param[1] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and a_in_param[1] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then a_in_param[1] end
                                       as   in_param,
          case when a_in_param[1] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then a_in_param[1]::float end
                                       as   in_value,
          row_number() over () + 1     as   param_loc,
          'sm_sc.fv_opr_add'         as   out_opr
        from regexp_matches(v_reg_arr[15], v_rgx_var, 'g')   tb_a(a_in_param)
        where v_reg_arr[15] is not null
        ;
      end if;
    
      -- 即以识别处理的表达式替换为中间变量，准备下次识别
      select 
        sm_sc.fv_clean_bracket
        (
          regexp_replace
          (
            v_opr_algebra
--            , v_reg_arr[1]
            , regexp_replace
              (
                v_reg_arr[1]
                , '([\+\-\*\/\.\^\!\(\)\,\:\<\>\[\]\\])'
                , '\\\1'
                , 'g'
              )
            , md5(v_reg_arr[1])
            , 'g'
          )
        ) 
        into v_opr_algebra;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 061 -- v_reg_arr[1]: %', v_reg_arr[1];
-- -- -- -- raise notice 'debug -- 061 -- v_opr_algebra: %', v_opr_algebra;
    end loop;
    
  end loop;

-- -- -- -- -- debug
-- -- -- -- raise notice 'debug -- 07 -- v_opr_algebra: %', v_opr_algebra;
  -- 第六优先识别等式左侧的因变量关联关系
  if v_opr_algebra ~ ('^' || v_obj_rgx_equation || '$')
  then
    select regexp_matches(v_opr_algebra, v_obj_rgx_equation) into v_reg_arr;
    -- 解析
    insert into sm_sc._vt_fn_compu_graph_deseri__graph
    (
      sess_id          ,
      out_param         ,
      in_param          ,
      in_value          ,
      param_loc         ,
      out_opr   
    )
    select 
      v_sess_id,
      case when v_reg_arr[6] like '-%' then md5(v_reg_arr[6]) else v_reg_arr[2]::varchar(64) end  
                                   as   out_param,
      case when v_reg_arr[6] ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_reg_arr[6] !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[6] end
                                   as   in_param,
      case when v_reg_arr[6] ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_reg_arr[6]::float end
                                   as   in_value,
      1                            as   param_loc,
      ''  ::varchar(64)            as   out_opr
    ;    
  -- 最简中间变量而没有等式的情况
  elsif v_opr_algebra ~ ('^' || v_rgx_var || '$')
  then
    insert into sm_sc._vt_fn_compu_graph_deseri__graph
    (
      sess_id          ,
      out_param         ,
      in_param          ,
      in_value          ,
      param_loc         ,
      out_opr   
    )
    select 
      v_sess_id,
      ''::varchar(64)              as   out_param,
      case when v_opr_algebra ~ '^[a-zA-Z0-9_]+([a-zA-Z0-9_\.]*[a-zA-Z0-9_])?$' and v_opr_algebra !~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_opr_algebra end
                                   as   in_param,
      case when v_opr_algebra ~ '^\-?[0-9]+(\.?[0-9]*)?$' then v_opr_algebra::float end
                                   as   in_value,
      1                            as   param_loc,
      ''  ::varchar(64)            as   out_opr
    ;
  -- 无法化简为最简，解析失败
  else
    raise exception 'unknown algebra!';
  end if;

  return query
    select 
      out_param    ,
      in_param     ,
      in_value     ,
      param_loc    ,
      out_opr
    from sm_sc._vt_fn_compu_graph_deseri__graph
    where sess_id = v_sess_id
  ;

  -- -- drop table if exists sm_sc._vt_fn_compu_graph_deseri__graph;
  delete from sm_sc._vt_fn_compu_graph_deseri__graph
  where sess_id = v_sess_id;
end
$$
language plpgsql volatile
cost 100;

-- -- set force_parallel_mode = 'off';
-- select * from sm_sc.ft_computational_graph_deserialize('v_y_in = w1 * v_x1_in + w2 * v_x2 + w3 * v_x3')
-- select * from sm_sc.ft_computational_graph_deserialize('v_z_in = (v_x_in * v_y) + exp(v_x_in * v_y) + power(v_x_in, 2)')