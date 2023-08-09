-- 计算图原子运算求导
-- drop function if exists sm_sc.ft_gradient_opr_graph(varchar(64), varchar(64), int, varchar(64), float, varchar(64));
create or replace function sm_sc.ft_gradient_opr_graph
( 
  i_depdt_var_name               varchar(64)                     ,    -- 自变量名
  i_fn                           varchar(64)                     ,    -- i_fn = '' and i_co_value is not null, 则恒为常数；对于 y = x, 则 i_fn 设为 ''
  i_depdt_var_loc                int              default 1      ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 sub, div, pow, log 四种运算操作敏感；其他运算操作用不到 i_depdt_var_loc
  i_co_name                      varchar(64)      default null   ,    -- fn 配套的另一个入参名，该配套入参位置与 i_depdt_var_loc 对立；如果该另一入参是常数，则 i_co_name 为空，i_co_value 填值
  i_co_value                     float   default null   ,    -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立；如果该另一入参是变量，则 i_co_value 为空，i_co_name 填值
    -- 对于常量引用，请装入 i_co_name, 数字协参可以装入 i_co_value, 也可以作为字符串装入 i_co_name
    -- 预留 i_co_value 的目的为了未来可以扩展后续步骤的数学运算
  i_grad_name                    varchar(64)      default null        -- 最终微分结果变量名
  -- 约定：当 i_fn = '' and i_co_value is null, 表示函数: y = x;  
  --       当 i_fn = '' and i_co_value is not null, 表示函数: y = C (C 为 常数);  
)
returns 
  -- 约定：如果 i_grad_name is null, 那么返回结果有且只有唯一一条记录 where o_out_param is null，表示计算图的根结果
  table
  (
    o_out_param                varchar(64)      ,
    o_in_param                 varchar(64)      ,
    o_in_value                 float   ,
    o_param_loc                int              ,
    o_out_opr                  varchar(64)        
  )
as
$$
declare -- here
  v_sql_code  text;
  v_sql_ret   float;
  v_tmp       float;
begin

  if i_fn = '' and (i_co_value is not null or i_co_name is not null)
  then 
    return query
      select 
        i_grad_name   
                             ::varchar(64)    as      o_out_param        ,
        null                 ::varchar(64)    as      o_in_param         ,
        0.0                  ::float as      o_in_value         ,
        1                    ::int            as      o_param_loc          ,
        ''                   ::varchar(64)    as      o_out_opr   
      ;
  elsif i_fn = 'sm_sc.fv_opr_add'
    or i_fn = '' and i_co_value is null and i_co_name is null
  then 
    return query
      select 
        i_grad_name   
                             ::varchar(64)    as      o_out_param        ,
        null                 ::varchar(64)    as      o_in_param         ,
        1.0 :: float                 ::float as      o_in_value         ,
        1                    ::int            as      o_param_loc          ,
        ''                   ::varchar(64)    as      o_out_opr   
      ;
  elsif i_fn = 'sm_sc.fv_opr_mul'
  then 
    return query
      select 
        i_grad_name  
                             ::varchar(64)    as      o_out_param        ,
        i_co_name            ::varchar(64)    as      o_in_param         ,
        i_co_value           ::float as      o_in_value         ,
        1                    ::int            as      o_param_loc          ,
        ''                   ::varchar(64)    as      o_out_opr   
      ;
  elsif i_fn = 'sm_sc.fv_opr_sub'
  then 
    return query
      select 
        i_grad_name   
                             ::varchar(64)    as      o_out_param        ,
        null                 ::varchar(64)    as      o_in_param         ,
        case i_depdt_var_loc 
          when 1 
            then 1.0
          when 2 
            then -1.0
        end                  ::float as      o_in_value         ,
        1                    ::int            as      o_param_loc          ,
        ''                   ::varchar(64)    as      o_out_opr   
      ;
  elsif i_fn = 'sm_sc.fv_opr_div'
  then 
    if i_depdt_var_loc = 1
    then 
      return query
        select 
          coalesce(i_grad_name, md5('1.0 :: float/ ' || coalesce(i_co_name, i_co_value::text)::text))   
                               ::varchar(64)    as      o_out_param        ,
          null                 ::varchar(64)    as      o_in_param         ,
          1.0 :: float                 ::float as      o_in_value         ,
          1                    ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_div' ::varchar(64)    as      o_out_opr   
        union all
        select 
          coalesce(i_grad_name, md5('1.0 :: float/ ' || coalesce(i_co_name, i_co_value::text)::text))     
                                    ::varchar(64)    as      o_out_param        ,
          i_co_name                 ::varchar(64)    as      o_in_param         ,
          nullif(i_co_value, 0.0 :: float)   ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_div'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          null                                      as      o_out_param        ,
          md5('1.0 :: float/ ' || coalesce(i_co_name, i_co_value::text)::text)   
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
      ;
    elsif i_depdt_var_loc = 2
    then 
      return query
        select 
          md5('power(' || i_depdt_var_name || ', -2)')
                                    ::varchar(64)    as      o_out_param      ,
          i_depdt_var_name          ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('power(' || i_depdt_var_name || ', -2)')
                                    ::varchar(64)    as      o_out_param      ,
          null                      ::varchar(64)    as      o_in_param         ,
          -2.0                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'      ::varchar(64)    as      o_out_opr    
        union all
        select  
          md5(coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', -2)')
                                    ::varchar(64)    as      o_out_param      ,
          i_co_name                 ::varchar(64)    as      o_in_param         ,
          i_co_value                ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'      ::varchar(64)    as      o_out_opr   
        union all
        select  
          md5(coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', -2)')
                                    ::varchar(64)    as      o_out_param      ,
          md5('power(' || i_depdt_var_name || ', -2)')
                                    ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'      ::varchar(64)    as      o_out_opr   
        union all
        select  
          coalesce(i_grad_name, md5('-' || coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', -2)'))   
                               ::varchar(64)    as      o_out_param        ,
          null                      ::varchar(64)    as      o_in_param         ,
          0.0                       ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_sub'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          coalesce(i_grad_name, md5('-' || coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', -2)'))   
                               ::varchar(64)    as      o_out_param        ,
          md5(coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', -2)')
                                    ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_sub'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          null                                      as      o_out_param        ,
          md5('-' || coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', -2)') 
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
      ;
    end if;
  elsif i_fn = 'sm_sc.fv_opr_pow'
  then 
    if i_depdt_var_loc = 1
    then 
      return query
        select 
          md5(coalesce(i_co_name, i_co_value::text) || ' - 1')
                                    ::varchar(64)    as      o_out_param      ,
          i_co_name                 ::varchar(64)    as      o_in_param         ,
          i_co_value                ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_sub'      ::varchar(64)    as      o_out_opr   
        union all  
        select 
          md5(coalesce(i_co_name, i_co_value::text) || ' - 1')
                                    ::varchar(64)    as      o_out_param      ,
          null                      ::varchar(64)    as      o_in_param         ,
          1.0 :: float                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_sub'      ::varchar(64)    as      o_out_opr 
        union all
        select 
          md5('power(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ' - 1)')
                                    ::varchar(64)    as      o_out_param      ,
          i_depdt_var_name          ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('power(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ' - 1)')
                                    ::varchar(64)    as      o_out_param      ,
          md5(coalesce(i_co_name, i_co_value::text) || ' - 1')
                                    ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          coalesce(i_grad_name, md5(coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ' - 1)'))   
                                    ::varchar(64)    as      o_out_param        ,
          i_co_name                 ::varchar(64)    as      o_in_param         ,
          i_co_value                ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          coalesce(i_grad_name, md5(coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ' - 1)'))   
                                    ::varchar(64)    as      o_out_param        ,
          md5('power(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ' - 1)')
                                    ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          null                                      as      o_out_param        ,
          md5(coalesce(i_co_name, i_co_value::text) || ' * power(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ' - 1)') 
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
      ;
    elsif i_depdt_var_loc = 2
    then
      return query
        select 
          md5('power(' || coalesce(i_co_name, i_co_value::text) || ', ' || i_depdt_var_name || ')')
                                  ::varchar(64)    as      o_out_param      ,
          i_co_name               ::varchar(64)    as      o_in_param         ,
          i_co_value              ::float as      o_in_value         ,
          1                       ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'    ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('power(' || coalesce(i_co_name, i_co_value::text) || ', ' || i_depdt_var_name || ')')
                                  ::varchar(64)    as      o_out_param      ,
          i_depdt_var_name        ::varchar(64)    as      o_in_param         ,
          null                    ::float as      o_in_value         ,
          2                       ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'    ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                  ::varchar(64)    as      o_out_param      ,
          i_co_name               ::varchar(64)    as      o_in_param         ,
          i_co_value              ::float as      o_in_value         ,
          1                       ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_ln'     ::varchar(64)    as      o_out_opr   
        union all
        select 
          coalesce(i_grad_name, md5('power(' || coalesce(i_co_name, i_co_value::text) || ', ' || i_depdt_var_name || ') * ln(' || coalesce(i_co_name, i_co_value::text) || ')'))   
                                    ::varchar(64)    as      o_out_param        ,
          md5('power(' || coalesce(i_co_name, i_co_value::text) || ', ' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          1                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'      ::varchar(64)    as      o_out_opr      
        union all
        select 
          coalesce(i_grad_name, md5('power(' || coalesce(i_co_name, i_co_value::text) || ', ' || i_depdt_var_name || ') * ln(' || coalesce(i_co_name, i_co_value::text) || ')'))     
                                    ::varchar(64)    as      o_out_param        ,
          md5('ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                    ::varchar(64)    as      o_in_param         ,
          null                      ::float as      o_in_value         ,
          2                         ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'      ::varchar(64)    as      o_out_opr   
        union all
        select 
          null                                      as      o_out_param        ,
          md5('power(' || coalesce(i_co_name, i_co_value::text) || ', ' || i_depdt_var_name || ') * ln(' || coalesce(i_co_name, i_co_value::text) || ')')   
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
      ;
    end if;
  elsif i_fn = 'sm_sc.fv_opr_exp'
  then 
    return query
      select 
        i_grad_name   
                                    ::varchar(64)    as      o_out_param        ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_exp'        ::varchar(64)    as      o_out_opr   
    ;
  elsif i_fn = 'sm_sc.fv_opr_log'
  then 
    if i_depdt_var_loc = 1
    then
      return query
        select 
          md5('log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_log'        ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          i_co_name                   ::varchar(64)    as      o_in_param         ,
          i_co_value                  ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_log'        ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2)')
                                      ::varchar(64)    as      o_out_param      ,
          md5('log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          md5('power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2)')
                                      ::varchar(64)    as      o_out_param      ,
          null                        ::varchar(64)    as      o_in_param         ,
          2.0                         ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('-power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2)')
                                      ::varchar(64)    as      o_out_param      ,
          null                        ::varchar(64)    as      o_in_param         ,
          0.0                         ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
        union all
        select 
          md5('-power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2)')
                                      ::varchar(64)    as      o_out_param      ,
          md5('power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2)')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5('ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          i_co_name                   ::varchar(64)    as      o_in_param         ,
          i_co_value                  ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_ln'         ::varchar(64)    as      o_out_opr      
        union all
        select 
          md5(i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'        ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5(i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          md5('ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          coalesce(i_grad_name, md5('-power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2) / (' || i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || '))'))   
                                      ::varchar(64)    as      o_out_param        ,
          md5('-power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2)')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          coalesce(i_grad_name, md5('-power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2) / (' || i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || '))'))   
                                      ::varchar(64)    as      o_out_param        ,
          md5(i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          null                                      as      o_out_param        ,
          md5('-power(log(' || i_depdt_var_name || ', ' || coalesce(i_co_name, i_co_value::text) || '), 2) / (' || i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || '))')  
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
      ;
    elsif i_depdt_var_loc = 2
    then 
      return query
        select 
          md5('ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          i_co_name                   ::varchar(64)    as      o_in_param         ,
          i_co_value                  ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_ln'         ::varchar(64)    as      o_out_opr      
        union all
        select 
          md5(i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'        ::varchar(64)    as      o_out_opr   
        union all
        select 
          md5(i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_out_param      ,
          md5('ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_mul'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          coalesce(i_grad_name, md5('1.0 :: float/ (' || i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || '))'))   
                                      ::varchar(64)    as      o_out_param        ,
          null                        ::varchar(64)    as      o_in_param         ,
          1.0 :: float                        ::float as      o_in_value         ,
          1                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          coalesce(i_grad_name, md5('1.0 :: float/ (' || i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || '))'))   
                                      ::varchar(64)    as      o_out_param        ,
          md5(i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || ')')
                                      ::varchar(64)    as      o_in_param         ,
          null                        ::float as      o_in_value         ,
          2                           ::int            as      o_param_loc          ,
          'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
        union all
        select 
          null                                      as      o_out_param        ,
          md5('1.0 :: float/ (' || i_depdt_var_name || ' * ln(' || coalesce(i_co_name, i_co_value::text) || '))')
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
      ;
    end if;
  elsif i_fn = 'sm_sc.fv_opr_ln'
  then 
    return query
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ ' || i_depdt_var_name ::text))   
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ ' || i_depdt_var_name ::text)) 
                                    ::varchar(64)    as      o_out_param        ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                      as      o_out_param        ,
        md5('1.0 :: float/ ' || i_depdt_var_name ::text) 
                                                  as      o_in_param         ,
        null                                      as      o_in_value         ,
        1                                         as      o_param_loc          ,
        ''                                        as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_sin'
  then 
    return query
      select 
        i_grad_name   
                                    ::varchar(64)    as      o_out_param        ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_cos'            ::varchar(64)    as      o_out_opr    
    ;
  elsif i_fn = 'sm_sc.fv_cos'
  then 
    return query
      select 
        md5('sin(' || i_depdt_var_name || ')')  
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_sin'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-sin(' || i_depdt_var_name || ')'))   
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.0                         ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-sin(' || i_depdt_var_name || ')'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('sin(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        null                                      as      o_out_param        ,
        md5('-sin(' || i_depdt_var_name || ')')
                                                  as      o_in_param         ,
        null                                      as      o_in_value         ,
        1                                         as      o_param_loc          ,
        ''                                        as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_tan'
  then 
    return query
      select 
        md5('cos(' || i_depdt_var_name || ')')  
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_cos'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(cos(' || i_depdt_var_name || '), 2)')  
                                    ::varchar(64)    as      o_out_param      ,
        md5('cos(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr       
      union all
      select 
        md5('power(cos(' || i_depdt_var_name || '), 2)')  
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(cos(' || i_depdt_var_name || '), 2)'))   
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(cos(' || i_depdt_var_name || '), 2)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('power(cos(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        null                                      as      o_out_param        ,
        md5('1.0 :: float/ power(cos(' || i_depdt_var_name || '), 2)')
                                                  as      o_in_param         ,
        null                                      as      o_in_value         ,
        1                                         as      o_param_loc          ,
        ''                                        as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_cot'
  then 
    return query
      select 
        md5('sin(' || i_depdt_var_name || ')')  
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_sin'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(sin(' || i_depdt_var_name || '), 2)')  
                                    ::varchar(64)    as      o_out_param      ,
        md5('sin(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr       
      union all
      select 
        md5('power(sin(' || i_depdt_var_name || '), 2)')  
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float/ power(sin(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float/ power(sin(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(sin(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ power(sin(' || i_depdt_var_name || '), 2)'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.0                         ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ power(sin(' || i_depdt_var_name || '), 2)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('1.0 :: float/ power(sin(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        null                                      as      o_out_param        ,
        md5('-1.0 :: float/ power(sin(' || i_depdt_var_name || '), 2)')
                                                  as      o_in_param         ,
        null                                      as      o_in_value         ,
        1                                         as      o_param_loc          ,
        ''                                        as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_sec'
  then 
    return query
      select 
        md5('tan(' || i_depdt_var_name || ')') 
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_tan'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('cos(' || i_depdt_var_name || ')') 
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_cos'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('tan(' || i_depdt_var_name || ') / cos(' || i_depdt_var_name || ')'))  
                                    ::varchar(64)    as      o_out_param        ,
        md5('tan(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('tan(' || i_depdt_var_name || ') / cos(' || i_depdt_var_name || ')')) 
                                    ::varchar(64)    as      o_out_param        ,
        md5('cos(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        null                                         as      o_out_param        ,
        md5('tan(' || i_depdt_var_name || ') / cos(' || i_depdt_var_name || ')') 
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_csc'
  then 
    return query
      select 
        md5('cot(' || i_depdt_var_name || ')') 
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_cot'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('sin(' || i_depdt_var_name || ')') 
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_sin'            ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('cot(' || i_depdt_var_name || ') / sin(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_out_param      ,
        md5('cot(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('cot(' || i_depdt_var_name || ') / sin(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_out_param      ,
        md5('sin(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        coalesce(i_grad_name, md5('-cot(' || i_depdt_var_name || ') / sin(' || i_depdt_var_name || ')'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.0                         ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-cot(' || i_depdt_var_name || ') / sin(' || i_depdt_var_name || ')'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('cot(' || i_depdt_var_name || ') / sin(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        null                                         as      o_out_param        ,
        md5('-cot(' || i_depdt_var_name || ') / sin(' || i_depdt_var_name || ')')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_asin'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select
        md5('power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.5                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_acos'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select
        md5('power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.5                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select 
        md5('1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.0                         ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('-1.0 :: float/ power(1.0 :: float- power(' || i_depdt_var_name || ', 2), 0.5 :: float)')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_atan'
  then  
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float+ power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_add'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        md5('1.0 :: float+ power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_add'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('1.0 :: float+ power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_acot'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float+ power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_add'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        md5('1.0 :: float+ power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_add'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))')
                                    ::varchar(64)    as      o_out_param      ,
        md5('1.0 :: float+ power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))'))  
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.0                         ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))')) 
                                    ::varchar(64)    as      o_out_param        ,
        md5('1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('-1.0 :: float/ (1.0 :: float+ power(' || i_depdt_var_name || ', 2))') 
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_asec'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr      
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr       
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr
      union all
      select
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.5                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select
        md5(i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5(i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))'))   
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))'))    
                                    ::varchar(64)    as      o_out_param        ,
        md5(i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))')  
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_acsc'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr      
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr       
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr
      union all
      select
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.5                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select
        md5(i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5(i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select 
        md5('1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))')
                                    ::varchar(64)    as      o_out_param      ,
        md5(i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.0                         ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('-1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('-1.0 :: float/ (' || i_depdt_var_name || ' * power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float))')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_sinh'
  then 
    return query
      select 
        i_grad_name   
                                    ::varchar(64)    as      o_out_param        ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_cosh'           ::varchar(64)    as      o_out_opr    
    ;
  elsif i_fn = 'sm_sc.fv_cosh'
  then 
    return query
      select 
        i_grad_name   
                                    ::varchar(64)    as      o_out_param        ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_sinh'           ::varchar(64)    as      o_out_opr    
    ;
  elsif i_fn = 'sm_sc.fv_tanh'
  then 
    return query
      select 
        md5('cosh(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_cosh'           ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(cosh(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('cosh(' || i_depdt_var_name || ')')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(cosh(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(cosh(' || i_depdt_var_name || '), 2)'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(cosh(' || i_depdt_var_name || '), 2)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('power(cosh(' || i_depdt_var_name || '), 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ power(cosh(' || i_depdt_var_name || '), 2)')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_asinh'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) + 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_add'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) + 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_add'        ::varchar(64)    as      o_out_opr     
      union all
      select
        md5('power(power(' || i_depdt_var_name || ', 2) + 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2) + 1.0')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(power(' || i_depdt_var_name || ', 2) + 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.5                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(power(' || i_depdt_var_name || ', 2) + 1.0 :: float, 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(power(' || i_depdt_var_name || ', 2) + 1.0 :: float, 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('power(power(' || i_depdt_var_name || ', 2) + 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ power(power(' || i_depdt_var_name || ', 2) + 1.0 :: float, 0.5 :: float)')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_acosh'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2) - 1.0')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        0.5                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr   
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)'))
                                    ::varchar(64)    as      o_out_param        ,
        md5('power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ power(power(' || i_depdt_var_name || ', 2) - 1.0 :: float, 0.5 :: float)')
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  elsif i_fn = 'sm_sc.fv_atanh'
  then 
    return query
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        i_depdt_var_name            ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        2.0                         ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_pow'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_out_param      ,
        md5('power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_sub'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ (1.0 :: float- power(' || i_depdt_var_name || ', 2))'))   
                                    ::varchar(64)    as      o_out_param        ,
        null                        ::varchar(64)    as      o_in_param         ,
        1.0 :: float                        ::float as      o_in_value         ,
        1                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr    
      union all
      select 
        coalesce(i_grad_name, md5('1.0 :: float/ (1.0 :: float- power(' || i_depdt_var_name || ', 2))'))  
                                    ::varchar(64)    as      o_out_param        ,
        md5('1.0 :: float- power(' || i_depdt_var_name || ', 2)')
                                    ::varchar(64)    as      o_in_param         ,
        null                        ::float as      o_in_value         ,
        2                           ::int            as      o_param_loc          ,
        'sm_sc.fv_opr_div'        ::varchar(64)    as      o_out_opr     
      union all
      select 
        null                                         as      o_out_param        ,
        md5('1.0 :: float/ (1.0 :: float- power(' || i_depdt_var_name || ', 2))') 
                                                     as      o_in_param         ,
        null                                         as      o_in_value         ,
        1                                            as      o_param_loc          ,
        ''                                           as      o_out_opr   
      where i_grad_name is null
    ;
  else 
    raise exception 'unknown function: % !', i_fn;
  end if;

end
$$
language plpgsql stable
cost 100;


-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   ''
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   ''                      ,
-- --   1                       ,
-- --   'C'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   ''                      ,
-- --   1                       ,
-- --   null                    ,
-- --   12
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'    ,
-- --   1
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'    ,
-- --   2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   2                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   'a'                     ,
-- --   null::float
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_sub'    ,
-- --   1
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_sub'    ,
-- --   2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_div'    ,
-- --   1                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_div'    ,
-- --   1                       ,
-- --   'a'                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_div'    ,
-- --   2                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_div'    ,
-- --   2                       ,
-- --   'a'                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_pow'    ,
-- --   1                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_pow'    ,
-- --   1                       ,
-- --   'a'                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_pow'    ,
-- --   2                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_pow'    ,
-- --   2                       ,
-- --   'a'                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_exp' 
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_log'    ,
-- --   1                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_log'    ,
-- --   1                       ,
-- --   'a'                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_log'    ,
-- --   2                       ,
-- --   null                    ,
-- --   1.2
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_log'    ,
-- --   2                       ,
-- --   'a'                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_ln'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_sin'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_cos'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_tan'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_cot'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_sec'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_csc'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_asin'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_acos'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_atan'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_acot'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_asec'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_acsc'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_sinh'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_cosh'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_tanh'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_asinh'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_acosh'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_atanh'
-- -- );

-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   null      ,
-- --   null      ,
-- --   null      ,
-- --   null ::float     ,
-- --   'dydx_xxx'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_atanh'      ,
-- --   null                    ,
-- --   null                    ,
-- --   null     :: float       ,
-- --   'dydx_xxx'
-- -- );


-- ---------------------------------------------------------------------------------------
-- 计算图原子运算求导
-- 为了支持多目运算符
-- drop function if exists sm_sc.ft_gradient_opr_graph(varchar(64), varchar(64), int, varchar(64)[], float[], varchar(64));
create or replace function sm_sc.ft_gradient_opr_graph
( 
  i_depdt_var_name               varchar(64)                     ,    -- 自变量名
  i_fn                           varchar(64)                     ,    -- i_fn = '' and i_co_value is not null, 则恒为常数；对于 y = x, 则 i_fn 设为 ''
  i_depdt_var_loc                int                             ,    -- 单目、双目为 x 参数实际位置，并目(无目/常量y)为0；该参数对 sub, div, pow, log 四种运算操作敏感；其他运算操作用不到 i_depdt_var_loc
  i_co_names                     varchar(64)[]                   ,    -- fn 配套的另一个入参名，该配套入参位置与 i_depdt_var_loc 对立；如果该另一入参是常数，则 i_co_name 为空，i_co_value 填值
  i_co_values                    float[] default null   ,    -- fn 配套的另一个入参值，该配套入参位置与 i_depdt_var_loc 对立；如果该另一入参是变量，则 i_co_value 为空，i_co_name 填值
  i_grad_name                    varchar(64)      default null        -- 最终微分结果变量名
  -- 约定：当 i_fn = '' and i_co_value is null, 表示函数: y = x;  
  --       当 i_fn = '' and i_co_value is not null, 表示函数: y = C (C 为 常数);  
)
returns 
  table
  (
    o_out_param                varchar(64)      ,
    o_in_param                 varchar(64)      ,
    o_in_value                 float   ,
    o_param_loc                int              ,
    o_out_opr                  varchar(64)        
  )
as
$$
-- declare
begin
  if coalesce(array_length(i_co_names, 1), 0) + coalesce(array_length(i_co_values, 1), 0) < 2
  then 
    return query
      select 
        tb_a.o_out_param    ,
        tb_a.o_in_param     ,
        tb_a.o_in_value     ,
        tb_a.o_param_loc    ,
        tb_a.o_out_opr  
      from sm_sc.ft_gradient_opr_graph(i_depdt_var_name, i_fn, i_depdt_var_loc, i_co_names[1], i_co_values[1], i_grad_name) tb_a
    ;
  else
    if i_fn = 'sm_sc.fv_opr_add'
    then
      return query
        select 
          i_grad_name          ::varchar(64)        as      o_out_param      ,
          null                 ::varchar(64)        as      o_in_param         ,
          1.0 :: float                 ::float     as      o_in_value         ,
          1                    ::int                as      o_param_loc          ,
          ''                   ::varchar(64)        as      o_out_opr   
      ;                                           
    elsif i_fn = 'sm_sc.fv_opr_mul'             
    then     
      return query                                     
        select
          coalesce(i_grad_name, md5('prod(' || array_to_string(i_co_names::text[] || i_co_values::text[], ', ')::text || ')'))
                                  ::varchar(64)        as      o_out_param      ,
          i_co_names[a_name_no]   ::varchar(64)        as      o_in_param       ,
          null                    ::float     as      o_in_value       ,
          row_number() over()     ::int                as      o_param_loc      ,
          case 
            when coalesce(array_length(i_co_names, 1), 0) > 1 
                or i_co_values is not null 
              then i_fn 
            else '' 
          end                     ::varchar(64)        as      o_out_opr   
        from generate_series(1, array_length(i_co_names, 1))  tb_a_name(a_name_no) 
        -- where coalesce(array_length(i_co_names, 1), 0) > 0     
        union all                                   
        -- -- select                                      
        -- --   md5('prod(' || array_to_string(i_co_names::text[] || i_co_values::text[], ', ')::text || ')')
        -- --                        ::varchar(64)        as      o_out_param      ,
        -- --   null                 ::varchar(64)        as      o_in_param         ,
        -- --   sm_sc.fv_aggr_slice_prod(i_co_values)   as      o_in_value         ,
        -- --   1                    ::int                as      o_param_loc          ,
        -- --   case 
        -- --     when coalesce(array_length(i_co_names, 1), 0) > 0 
        -- --       then i_fn 
        -- --     else '' 
        -- --   end                 ::varchar(64)        as      o_out_opr   
        -- -- where coalesce(array_length(i_co_values, 1), 0) > 0
        select                                      
          coalesce(i_grad_name, md5('prod(' || array_to_string(i_co_names::text[] || i_co_values::text[], ', ')::text || ')'))
                                    ::varchar(64)         as      o_out_param      ,
          null                      ::varchar(64)         as      o_in_param         ,
          i_co_values[a_value_no]   ::float      as      o_in_value         ,
          array_length(i_co_names, 1) + row_number() over()   ::int                 as      o_param_loc          ,
          case 
            when coalesce(array_length(i_co_values, 1), 0) > 0 
                or i_co_names is not null
              then i_fn 
            else '' 
          end                 ::varchar(64)        as      o_out_opr   
        from generate_series(1, array_length(i_co_values, 1))  tb_a_value(a_value_no) 
        -- where coalesce(array_length(i_co_values, 1), 0) > 0
        union all
        select 
          null                                      as      o_out_param        ,
          md5('prod(' || array_to_string(i_co_names::text[] || i_co_values::text[], ', ')::text || ')')
                                                    as      o_in_param         ,
          null                                      as      o_in_value         ,
          1                                         as      o_param_loc          ,
          ''                                        as      o_out_opr   
        where i_grad_name is null
        ;
    else
      raise exception 'unknown function: % for such co_params!', i_fn;
    end if;
  end if;
end
$$
language plpgsql volatile
cost 100;


-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'    ,
-- --   2                       ,
-- --   null                    ,
-- --   array[1.2]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'    ,
-- --   1                       ,
-- --   array['a']                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'    ,
-- --   1                       ,
-- --   array['a', 'b']                     ,
-- --   array[1.2, 1.1]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   2                       ,
-- --   null                    ,
-- --   array[1.2]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   2                       ,
-- --   null                    ,
-- --   array[1.2, 1.1]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a']                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a', 'b']                     ,
-- --   null
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a']                     ,
-- --   array[1.2]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a']                     ,
-- --   array[1.2, 1.1]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a', 'b']                     ,
-- --   array[1.2]
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a', 'b']                     ,
-- --   array[1.2, 1.1]
-- -- );


-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_mul'    ,
-- --   1                       ,
-- --   array['a', 'b']         ,
-- --   array[1.2, 1.1]         ,
-- --   'dydx_balabala'
-- -- );
-- -- select * from sm_sc.ft_gradient_opr_graph
-- -- (
-- --   'x'                     ,
-- --   'sm_sc.fv_opr_add'    ,
-- --   1                       ,
-- --   array['a', 'b']         ,
-- --   array[1.2, 1.1]         ,
-- --   'dydx_balabala'
-- -- );