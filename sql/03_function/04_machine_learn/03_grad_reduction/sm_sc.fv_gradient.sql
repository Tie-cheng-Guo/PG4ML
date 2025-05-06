-- 计算图的设计
-- https://www.zhihu.com/question/66200879/answer/317086336
-- https://blog.csdn.net/hohaizx/article/details/82313143
-- -- 图中一个顶点对另一个顶点的导数等于该顶点到另一个顶点的路径上所有导数的乘积
-- -- 当存在从一个顶点到另一个顶点的多条路径时，那么这个顶点对另一个顶点的导数等于所有路径上导数的和
-- --------------------------------------------------------------------------------------------------------------------------------
-- 代数式的求导：
-- 返回推导出来的导数代数式
-- 计算图入参为 text (代数式) 或 json (计算关系 chart )
-- drop function if exists sm_sc.fv_gradient(varchar(64), anynonarray);
create or replace function sm_sc.fv_gradient
(
  i_indepdt_var_name               varchar(64),
  -- i_indepdt_var_name             varchar(64),
  i_opr_chart                    anynonarray     -- 仅支持 text (代数式) 或 json (计算关系 chart ) 类型,
)
returns text
as
$$
declare -- here
  v_root_out_param  varchar(64);
  v_ret             text;
  v_sess_id         bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)   := replace(gen_random_uuid()::char(36), '-', '')::char(32);

begin

  -- 用临时表并不是优雅的实现方式，期待未来版本 cte 的迭代部分支持分组聚合
  -- 01. 计算图关系列表
  insert into sm_sc._vt_fn_grad__graph
  (
    sess_id      ,
    o_out_param   ,
    o_in_param    ,
    o_in_value    ,
    o_param_loc   ,
    o_out_opr     ,
    is_decimal     
  )
  select
    v_sess_id,
    o_out_param_x        ::    varchar(64)       as o_out_param   ,
    o_in_param_x         ::    varchar(64)       as o_in_param    ,
    o_in_value_x         ::    varchar(64)       as o_in_value    ,
    o_param_loc_x        ::    int               as o_param_loc   ,
    o_out_opr_x          ::    varchar(64)       as o_out_opr     ,
    (o_in_value_x is not null)                   as is_decimal      -- 用于运算化简
  from sm_sc.ft_gradient_graph(i_indepdt_var_name, i_opr_chart)
  ;

  select o_in_param into v_root_out_param from sm_sc._vt_fn_grad__graph where o_out_param = '' and sess_id = v_sess_id limit 1;

  -- 02. 初始化插入计算图入参起点，包括常参、变参
  insert into sm_sc._vt_fn_grad__algebra
  (
    sess_id               ,
    o_out_param            ,
    o_out_algebra          ,
    is_decimal   
  )
  -- 常数代数
  select
    v_sess_id,
    o_out_param     :: varchar(64)     as   o_out_param     ,
    max(o_in_value) :: text            as   o_out_algebra   ,
    true                               as   is_decimal      -- 用于运算化简
  from sm_sc._vt_fn_grad__graph t
  where o_out_param <> ''
    and o_in_param is null
    and o_in_value is not null
    and sess_id = v_sess_id
  group by sess_id, o_out_param
  having count(*) = 1
    and max(o_out_opr) is null 
    and max(o_param_loc) = 1
  union all
  -- 入参代数
  select
    v_sess_id,
    tb_main.o_in_param   :: varchar(64)   as   o_out_param     ,
    tb_main.o_in_param   :: text          as   o_out_algebra   ,
    false                                 as   is_decimal      -- 用于运算化简
  from sm_sc._vt_fn_grad__graph tb_main
  left join sm_sc._vt_fn_grad__graph tb_a_comp
  on tb_main.o_in_param = tb_a_comp.o_out_param
    and tb_a_comp.sess_id = v_sess_id
  where tb_a_comp.o_out_param is null
    and tb_main.o_in_param is not null
    and tb_main.sess_id = v_sess_id
  group by tb_main.sess_id, tb_main.o_in_param
  ; 

  -- select * from sm_sc._vt_fn_grad__graph where sess_id = v_sess_id
  -- select * from sm_sc._vt_fn_grad__algebra where sess_id = v_sess_id

  if exists (select  from sm_sc._vt_fn_grad__algebra where sess_id = v_sess_id)
  then
    while not exists(select  from sm_sc._vt_fn_grad__algebra where o_out_param = v_root_out_param and sess_id = v_sess_id)
    loop
      insert into sm_sc._vt_fn_grad__algebra
      (
        sess_id      ,
        o_out_param   ,
        o_out_algebra ,
        is_decimal
      )
      with 
      cte_algebra as
      (
        select 
          tb_a_front_point.o_out_param      ,
          case
            when  
                -- 化简单一入参直接代入的场景一，包括直传单目非负常量、直传单目变量
                count(*) = 1 
                and (tb_a_front_point.o_out_opr = '' or tb_a_front_point.o_out_opr in ('sm_sc.fv_opr_add', 'sm_sc.fv_opr_mul'))
              then
                max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value))
            when  
                -- 化简为单一入参直接代入的场景三，包括减零、除以一、幂一
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_sub'
                  and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 2) || '%'
                or
                tb_a_front_point.o_out_opr in ('sm_sc.fv_opr_div', 'sm_sc.fv_opr_pow') 
                  and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 2) || '%'
              then
                max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value))
        
            when 
                -- 化简为单一入参直接代入的场景二，包括 n 目中加 n-1 个零、 n 目中乘 n-1 个一的场景
                tb_a_front_point.o_out_opr in ('sm_sc.fv_opr_add', 'sm_sc.fv_opr_mul')
                and
                count(*) 
                  filter 
                  (
                    where tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_add' and '0.0000000000000000000' like (coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value) || '%')
                      or tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_mul' and '1.0000000000000000000' like (coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value) || '%')
                  ) 
                >= count(*) - 1
              then
                case tb_a_front_point.o_out_opr
                  when 'sm_sc.fv_opr_add'
                    then
                      coalesce
                      (
                        max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) 
                          filter 
                          (
                            where '0.0000000000000000000' not like (coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value) || '%')
                          )
                        , '0.0'
                      )
                  when 'sm_sc.fv_opr_mul'
                    then
                      coalesce
                      (
                        max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) 
                          filter 
                          (
                            where '1.0000000000000000000' not like (coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value) || '%')
                          )
                        , '1.0'
                      )
                end
        
            -- 化简场景四，包括一幂得一、对数一得零、幂零得一、零幂得零，其中幂函数包括 pow, exp, 对数函数包括 log, ln
            when
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_pow'
                  and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_pow'
                  and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 2) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_exp'
                  and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
              then
                '1.0'
            when
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_pow'
                  and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_log'
                  and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 2) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_ln'
                  and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
              then
                '0.0'
        
            -- 运算符表达式，包括四则运算、幂指运算、对数运算
            when tb_a_front_point.o_out_opr in ('sm_sc.fv_opr_add', 'sm_sc.fv_opr_sub', 'sm_sc.fv_opr_mul', 'sm_sc.fv_opr_div', 'sm_sc.fv_opr_pow'/*, 'sm_sc.fv_opr_log'*/)
              then 
                '(' 
                || string_agg
                   (
                     -- 化简多目加零、多目乘一场景
                     case 
                       when 
                           -- tb_a_front_point.o_in_value::float = 0.0 and tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_add'
                           -- or tb_a_front_point.o_in_value::float = 1.0 :: floatand tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_mul'
                           tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_add' and '0.0000000000000000000' like (coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value) || '%')
                           or tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_mul' and '1.0000000000000000000' like (coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value) || '%')
                         then null :: text
                       else coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)
                     end
                     , case tb_a_front_point.o_out_opr 
                         when 'sm_sc.fv_opr_add' then ' + ' 
                         when 'sm_sc.fv_opr_sub' then ' - ' 
                         when 'sm_sc.fv_opr_mul' then ' * ' 
                         when 'sm_sc.fv_opr_div' then ' / ' 
                         when 'sm_sc.fv_opr_pow' then ' ^ ' 
                         /*when 'sm_sc.fv_opr_log' then ' ^! '*/  
                       end
                     order by tb_a_front_point.o_param_loc
                   ) 
                || ')'
        
            -- 函数式表达
            else
              case tb_a_front_point.o_out_opr
                when 'sm_sc.fv_opr_add'   then 'add'        
                when 'sm_sc.fv_opr_sub'   then 'sub'        
                when 'sm_sc.fv_opr_mul'   then 'mul'        
                when 'sm_sc.fv_opr_div'   then 'div'        
                when 'sm_sc.fv_opr_pow'   then 'pow'        
                when 'sm_sc.fv_opr_pow'   then 'power'      
                when 'sm_sc.fv_opr_exp'   then 'exp'        
                when 'sm_sc.fv_opr_log'   then 'log'        
                when 'sm_sc.fv_opr_ln'    then 'ln'         
                when 'sm_sc.fv_sin'       then 'sin'        
                when 'sm_sc.fv_cos'       then 'cos'        
                when 'sm_sc.fv_tan'       then 'tan'        
                when 'sm_sc.fv_cot'       then 'cot'        
                when 'sm_sc.fv_sec'       then 'sec'        
                when 'sm_sc.fv_csc'       then 'csc'        
                when 'sm_sc.fv_asin'      then 'asin'       
                when 'sm_sc.fv_acos'      then 'acos'       
                when 'sm_sc.fv_atan'      then 'atan'       
                when 'sm_sc.fv_acot'      then 'acot'       
                when 'sm_sc.fv_asec'      then 'asec'       
                when 'sm_sc.fv_acsc'      then 'acsc'       
                when 'sm_sc.fv_sinh'      then 'sinh'       
                when 'sm_sc.fv_cosh'      then 'cosh'       
                when 'sm_sc.fv_tanh'      then 'tanh'       
                when 'sm_sc.fv_asinh'     then 'asinh'      
                when 'sm_sc.fv_acosh'     then 'acosh'      
                when 'sm_sc.fv_atanh'     then 'atanh'      
                else coalesce(tb_a_front_point.o_out_opr, '')
              end
              || '(' 
              || string_agg
                 (
                   coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)
                   , ', ' 
                   order by tb_a_front_point.o_param_loc
                 ) 
              || ')'
          end 
            as o_out_algebra,
          case
            -- 化简场景四，包括一幂得一、对数一得零、幂零得一、零幂得零，此时 is_decimal 亦要更新为 true
            when
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_pow'
                  and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_pow'
                  and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 2) || '%'
                -- or
                -- tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_exp'
                --   and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_pow'
                  and '0.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
                or
                tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_log'
                  and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 2) || '%'
                -- or
                -- tb_a_front_point.o_out_opr = 'sm_sc.fv_opr_ln'
                --   and '1.0000000000000000000' like max(coalesce(tb_a_back_point.o_out_algebra, tb_a_front_point.o_in_value)) filter (where tb_a_front_point.o_param_loc = 1) || '%'
              then
                true
            else
              (false <> all(array_agg(coalesce(tb_a_back_point.is_decimal, tb_a_front_point.is_decimal))))
          end
            as is_decimal
        from sm_sc._vt_fn_grad__graph tb_a_front_point
        left join sm_sc._vt_fn_grad__algebra tb_a_back_point
        on tb_a_front_point.o_in_param = tb_a_back_point.o_out_param
          and tb_a_back_point.sess_id = v_sess_id
        where tb_a_front_point.o_out_param <> ''
          -- 避免重复代入
          and tb_a_front_point.o_out_param not in (select o_out_param from sm_sc._vt_fn_grad__algebra where sess_id = v_sess_id)
          and tb_a_front_point.sess_id = v_sess_id
        group by tb_a_front_point.o_out_param, tb_a_front_point.o_out_opr, tb_a_front_point.sess_id
        having count(*) filter (where tb_a_back_point.o_out_param is null and tb_a_front_point.o_in_value is null and tb_a_back_point.sess_id is null) = 0
      )
      select
        v_sess_id, 
        o_out_param,
        case when is_decimal then sm_sc.fv_algebra_execute(o_out_algebra)::text else o_out_algebra end as o_out_algebra,
        is_decimal
      from cte_algebra
      ;
    end loop;
  end if;

  select 
    o_out_algebra into v_ret
  from sm_sc._vt_fn_grad__algebra
  where o_out_param = v_root_out_param
    and sess_id = v_sess_id
  limit 1;
  
  -- 清理释放表变量
  delete from sm_sc._vt_fn_grad__graph where sess_id = v_sess_id;
  delete from sm_sc._vt_fn_grad__algebra where sess_id = v_sess_id;

  return coalesce(v_ret, '0');

end
$$
language plpgsql volatile
cost 100;

-- -- 代数式的求导：
-- -- 返回推导出来的导数代数式
-- -- 计算图入参为 代数式
-- select sm_sc.fv_gradient('v_x1_in', 'w1 * v_x1_in + w2 * v_x2 + w3 * v_x3'::text)
-- select sm_sc.fv_gradient('v_x_in', '(v_x_in * v_y) + exp(v_x_in * v_y) + power(v_x_in, 2)'::text)

-- -- 计算图为 json 配置
-- -- select pgv_set('vars', 'a_opr_chain_03', 
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
-- --     },
-- --     {
-- --       "opr": "sm_sc.fv_opr_pow",
-- --       "in_params": 
-- --       [
-- --         {
-- --           "out_param": "v_x_in"
-- --         },
-- --         {
-- --           "out_value": 2
-- --         }
-- --       ]
-- --     }
-- --   ]
-- -- }
-- -- '::jsonb);

-- select sm_sc.fv_gradient('v_x_in'::text, pgv_get('vars', 'a_opr_chain_03', NULL::jsonb));
