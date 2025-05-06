-- 标量 scalar 运算，而非张量矩阵运算的求导
-- 张量运算的求导，需构建雅可比矩阵
-- https://blog.csdn.net/bitcarmanlee/article/details/78819025

-- 计算图的设计
-- https://www.zhihu.com/question/66200879/answer/317086336
-- https://blog.csdn.net/hohaizx/article/details/82313143
--    1. 图中一个顶点对另一个顶点的导数等于该顶点到另一个顶点的路径上所有导数的乘积；
--    2. 当存在从一个顶点到另一个顶点的多条路径时，那么这个顶点对另一个顶点的导数等于所有路径上导数的和；
--    3. 计算图的三套结构
--      a. 原始运算结构: 
--           y = fn(x), 对应本程序参数引用名：i_depdt_var_name = fn(i_indepdt_var_name)
--      b. 原子运算求导结构
--           d_forword/d_back = d_fn(v_back)
--      c. 链式求导结构
--           d_forword/d_x = d_fn_ex(x)
-- drop function if exists sm_sc.ft_gradient_graph(varchar(64), anynonarray, varchar(64));
create or replace function sm_sc.ft_gradient_graph
(
  i_indepdt_var_name             varchar(64),
  -- i_depdt_var_name               varchar(64),
  i_opr_chart                    anynonarray,    -- 仅支持 text (代数式) 或 json (计算关系 chart ) 类型,
  i_grad_name                    varchar(64)      default null        -- 最终微分结果变量名
)
returns -- sm_sc.fv_computational_graph_serialize   return jsonb
  -- 约定：如果 i_grad_name is null, 那么返回结果有且只有唯一一条记录 where o_out_param is null，表示计算图的根结果
  table
  (
    o_out_param_x              varchar(64)      ,
    o_in_param_x               varchar(64)      ,
    o_in_value_x               float   ,
    o_param_loc_x              int              ,
    o_out_opr_x                varchar(64)
  )
as
$$
-- declare
begin
  return query
    with recursive
    -- 01. jsonb 配置反序列化为表记录
    --   原始运算计算图 关系
    cte_cfg_chain as
    (
      select
        o_out_param  ::varchar(64)     as out_param  ,
        o_in_param   ::varchar(64)     as in_param     ,
        o_in_value   ::float  as in_value     ,
        o_param_loc  ::int             as param_loc      ,
        o_out_opr    ::varchar(64)     as out_opr  
      from sm_sc.ft_computational_graph_deserialize(i_opr_chart)   -- (pgv_get('vars', 'a_opr_chain_03', NULL::jsonb))
    ),
    -- 02. 配置表去重为原始计算关系表
    --   原始运算计算图 关系
    cte_cfg_graph as
    (
      select
        out_param                        as    out_param                ,
        max(in_param) :: varchar(64)     as    in_param                 ,
        max(in_value) :: float  as    in_value                 ,
        param_loc                        as    param_loc                ,
        max(out_opr)  :: varchar(64)     as    out_opr
      from cte_cfg_chain
      group by out_param, param_loc
    ),
    -- 03. 前向传播，从有向无环图，过滤出目标自变量-因变量的路径
    --   原始运算计算图 关系 子集
    -- recursive
    cte_cfg_graph_forward as
    (
      select 
        tb_a_init.out_param             as out_param          ,
        tb_a_init.in_param              as in_param           ,
        tb_a_init.in_value              as in_value           ,
        tb_a_init.param_loc             as param_loc          ,
        tb_a_init.out_opr               as out_opr            ,
        -- 以下字段，控制递归
        1                                 as recur_dept         ,
        array[tb_a_init.out_param::varchar(64)]::varchar(64)[]
                                          as cycle_path_check   ,
        false                             as is_cycle  
      from cte_cfg_graph tb_a_init
      where in_param = i_indepdt_var_name    -- 'v_x_in'
      union    -- 前向传播路径去重
      select 
        tb_a_incre.out_param            as out_param          ,
        tb_a_incre.in_param             as in_param           ,
        tb_a_incre.in_value             as in_value           ,
        tb_a_incre.param_loc            as param_loc          ,
        tb_a_incre.out_opr              as out_opr            ,
        -- 以下字段，控制递归
        tb_a_cur.recur_dept + 1         as recur_dept         ,
        (tb_a_cur.cycle_path_check || (array[tb_a_incre.in_param::varchar(64)]::varchar(64)[]))::varchar(64)[]
                                          as   cycle_path_check,
        tb_a_incre.in_param = any(cycle_path_check)
                                          as is_cycle
      from cte_cfg_graph_forward tb_a_cur
      inner join cte_cfg_graph tb_a_incre
        on tb_a_incre.in_param = tb_a_cur.out_param
          and tb_a_incre.in_param <> ''   -- i_depdt_var_name        -- 'v_z_in'
      -- where tb_a_cur.recur_dept <= 100    -- for safe
      --  and not tb_a_cur.is_cycle
    ),
    -- 04. 协参准备, sm_sc.ft_gradient_opr_graph 要用到, group 等操作避免重复求导
    --   原始运算计算图 节点 子集
    cte_opr_gragh as
    (
      select 
        tb_a_depdt_var.out_param          as     out_param,
        max(tb_a_depdt_var.in_param)::varchar(64)      
                                            as     in_param,
        max(tb_a_depdt_var.out_opr)::varchar(64)
                                            as     out_opr,
        tb_a_depdt_var.param_loc          as     param_loc,
        array_agg(tb_a_co_var.in_param) filter(where tb_a_co_var.in_param is not null) :: varchar(64)[]  --  order by tb_a_co_var.param_loc)  -- 双目运算符的协参只有一个，多目运算符（加法、乘法）的协参可能有多个，对排序不敏感
                                            as     co_params,
        array_agg(tb_a_co_var.in_value) filter(where tb_a_co_var.in_value is not null) :: varchar(64)[]  --  order by tb_a_co_var.param_loc)  -- 双目运算符的协参只有一个，多目运算符（加法、乘法）的协参可能有多个，对排序不敏感
                                            as     co_values
      from cte_cfg_graph tb_a_depdt_var
      inner join cte_cfg_graph_forward tb_a_delt_depdt_var
        on tb_a_depdt_var.out_param = tb_a_delt_depdt_var.out_param
          and tb_a_depdt_var.param_loc = tb_a_delt_depdt_var.param_loc
          and tb_a_depdt_var.out_opr = tb_a_delt_depdt_var.out_opr
          and tb_a_depdt_var.in_param = tb_a_delt_depdt_var.in_param
      left join cte_cfg_graph tb_a_co_var
        on tb_a_co_var.out_param = tb_a_depdt_var.out_param
          and tb_a_co_var.param_loc <> tb_a_depdt_var.param_loc
      where tb_a_depdt_var.in_param is not null    -- 常量的微分无用，过滤掉
      group by 
        tb_a_depdt_var.out_param,
        tb_a_depdt_var.param_loc
    ),
    -- 05. 对原子运算求导
    --   原子运算求导计算图 关系
    cte_gradient as
    (
      select 
        tb_a_opr.out_param,
        tb_a_opr.in_param,
        tb_a_opr.out_opr,
        tb_a_opr.param_loc,
        tb_a_opr_grad.o_out_param  :: varchar(64)      as o_out_param,
        tb_a_opr_grad.o_in_param   :: varchar(64)      as o_in_param ,
        tb_a_opr_grad.o_in_value   :: float   as o_in_value ,
        tb_a_opr_grad.o_param_loc  :: int              as o_param_loc,
        tb_a_opr_grad.o_out_opr    :: varchar(64)      as o_out_opr  
      from cte_opr_gragh tb_a_opr
        ,sm_sc.ft_gradient_opr_graph
          (
            tb_a_opr.in_param::varchar(64), 
            tb_a_opr.out_opr::varchar(64), 
            tb_a_opr.param_loc::int, 
            tb_a_opr.co_params::varchar(64)[], 
            tb_a_opr.co_values::float[],
            md5('d_' || tb_a_opr.out_param || '_d_' || tb_a_opr.in_param || '_loc_' || (tb_a_opr.param_loc::int))
          ) tb_a_opr_grad
    ),
    -- 06. 计算关系查询总表，包含原始计算关系、导数计算关系的所有中间引用、自变量入参引用、因变量出参引用和目标导数引用
    --   原始运算计算图、原子运算求导计算图汇总 关系
    cte_opr_dic as
    (
      select 
        out_param     ,
        in_param      ,
        in_value      ,
        param_loc     ,
        out_opr
      from cte_cfg_graph
      union
      select 
        o_out_param   as   out_param     ,
        o_in_param    as   in_param      ,
        o_in_value    as   in_value      ,
        o_param_loc   as   param_loc     ,
        o_out_opr     as   out_opr
      from cte_gradient
    ),
    -- 07. 原子运算导数对象列表
    --   原子运算求导计算图汇总 节点
    cte_gradient_graph as
    (
      select 
        out_param    ,
        in_param     ,
        out_opr      ,
        param_loc    ,
        o_out_param  ,
        array_agg(o_in_param) filter(where o_in_param is not null)  --  order by o_param_loc)  -- 双目运算符的协参只有一个，多目运算符（加法、乘法）的协参可能有多个，对排序不敏感
          as     o_co_params,
        array_agg(o_in_value) filter(where o_in_value is not null)  --  order by o_param_loc)  -- 双目运算符的协参只有一个，多目运算符（加法、乘法）的协参可能有多个，对排序不敏感
          as     o_co_values
      from cte_gradient
      where o_out_param = md5('d_' || out_param || '_d_' || in_param || '_loc_' || (param_loc::int))
      group by 
        out_param    ,
        in_param     ,
        out_opr      ,
        param_loc    ,
        o_out_param
    ),
    
    -- 08. 反向传播，链式求导
    --   链式求导计算图 反向乘法链
    -- recursive
    cte_gradient_graph_back as
    (
      select 
        ''::varchar(64)                   as out_param          ,
        ''::varchar(64)                   as in_param           ,                  -- i_depdt_var_name  -- 'v_z_in'
        ''  ::varchar(64)                 as out_opr            ,
        1 :: int                          as param_loc          ,
        array[]::varchar(64)[]            as o_clain_mul        ,
        -- 以下字段，控制递归
        1                                 as recur_dept         ,
        array[]::varchar(64)[]            as cycle_path_check   ,
        false                             as is_cycle  
      -- -- -- where exists (select  from cte_cfg_graph_forward where in_param = i_indepdt_var_name)
      union all    -- 反向传播路径不去重
      select 
        tb_a_cur.in_param               as out_param          ,
        tb_a_incre.in_param             as in_param           ,
        tb_a_incre.out_opr              as out_opr            ,
        tb_a_incre.param_loc            as param_loc          ,
        (tb_a_cur.o_clain_mul || tb_a_incre.o_out_param)::varchar(64)[]
                                          as o_clain_mul        ,
        -- 以下字段，控制递归
        tb_a_cur.recur_dept + 1         as recur_dept         ,
        (tb_a_cur.cycle_path_check || (array[tb_a_incre.in_param::varchar(64)]::varchar(64)[]))::varchar(64)[]
                                          as   cycle_path_check,
        tb_a_incre.in_param = any(cycle_path_check)
                                          as is_cycle
      from cte_gradient_graph_back tb_a_cur
      inner join cte_gradient_graph tb_a_incre
        on tb_a_incre.out_param = tb_a_cur.in_param
      -- where tb_a_cur.recur_dept <= 100    -- for safe
      --  and not tb_a_cur.is_cycle
      --   and tb_a_cur.in_param <> i_indepdt_var_name             -- 'v_x_in'
    ),
    -- 09. 反向传播，分支合计操作
    --   链式求导计算图 关系 根节点：d_indepdt_var_d_depdt_var
    cte_gradient_graph_sum as
    (
      select 
        ''::varchar(64)                   as out_param          ,
        md5('d__d_' || i_indepdt_var_name || '_1_{}')::varchar(64)     -- 'v_z_in'     -- 'v_x_in'
                                          as in_param           ,
        null::float              as in_value           ,
        1   ::int                         as param_loc          ,
        ''  ::varchar(64)                 as out_opr
      where i_grad_name is null
        and exists (select  from cte_cfg_graph_forward where in_param = i_indepdt_var_name)   -- 'v_x_in'
      union all
      select 
        coalesce(i_grad_name, md5('d__d_' || i_indepdt_var_name || '_1_{}')::varchar(64))     -- 'v_z_in'     -- 'v_x_in'
                                          as out_param          ,
        md5(out_param || in_param || (param_loc::text) || (o_clain_mul::text))::varchar(64)
                                          as in_param           ,
        null::float              as in_value           ,
        row_number() over()::int          as param_loc          ,
        'sm_sc.fv_opr_add' as out_opr
      from cte_gradient_graph_back
      where in_param = i_indepdt_var_name                               -- 'v_x_in' 
      union all
      select 
        md5(out_param || in_param || (param_loc::text) || (o_clain_mul::text))::varchar(64)
                                          as out_param          ,
        a_clain_in_param::varchar(64)
                                          as in_param           ,
        null::float              as in_value           ,
        row_number() over(partition by o_clain_mul)::int
                                          as param_loc          ,
        'sm_sc.fv_opr_mul' as out_opr
      from cte_gradient_graph_back, unnest(o_clain_mul) tb_a_clain(a_clain_in_param)
      where in_param = i_indepdt_var_name                              -- 'v_x_in' 
    ),
    -- 10. 补齐求导计算图协变量，组合成求导计算全图、算数运算化简
    --   链式求导计算图 关系
    -- recursive
    cte_gradient_graph_ful as
    (
      select 
        out_param                                               ,
        in_param                                                ,
        in_value                                                ,
        param_loc                                               ,
        out_opr                                                 ,
        -- 以下字段，控制递归
        1                                 as recur_dept         ,
        array[in_param]::varchar(64)[]    as cycle_path_check   ,
        false                             as is_cycle  
      from cte_gradient_graph_sum
      union  -- 需要去重
      select 
        tb_a_incre.out_param                                  ,
        tb_a_incre.in_param                                   ,
        tb_a_incre.in_value                                   ,
        tb_a_incre.param_loc                                  ,
        tb_a_incre.out_opr                                    ,
        -- 以下字段，控制递归
        tb_a_cur.recur_dept + 1         as recur_dept         ,
        (tb_a_cur.cycle_path_check || (array[tb_a_incre.in_param::varchar(64)]))::varchar(64)[]
                                          as   cycle_path_check,
        tb_a_incre.in_param = any(cycle_path_check)
                                          as is_cycle
      from cte_gradient_graph_ful tb_a_cur
      inner join cte_opr_dic tb_a_incre
      on tb_a_incre.out_param = tb_a_cur.in_param
      where not tb_a_cur.is_cycle
      --   and tb_a_cur.recur_dept <= 100    -- for safe
      --  and not tb_a_cur.is_cycle
    )
    select
      out_param            as o_out_param  ,
      in_param             as o_in_param   ,
      in_value             as o_in_value   ,
      param_loc            as o_param_loc  ,
      out_opr              as o_out_opr
    from cte_gradient_graph_ful
    order by out_param, param_loc
  ;
end
$$
language plpgsql volatile
cost 100;


-- select * from sm_sc.ft_gradient_graph('v_x1_in', 'w1 * v_x1_in + w2 * v_x2 + w3 * v_x3'::text)
-- select * from sm_sc.ft_gradient_graph('v_x_in', '(v_x_in * v_y) + exp(v_x_in * v_y) + power(v_x_in, 2)'::text)


-- -- select pgv_set('vars', 'a_opr_chain', 
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

-- select * from sm_sc.ft_gradient_graph('v_x1_in', pgv_get('vars', 'a_opr_chain', NULL::jsonb))

-- -----------------------------------------------------------------------------------------------------

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

-- select * from sm_sc.ft_gradient_graph('v_x_in', pgv_get('vars', 'a_opr_chain', NULL::jsonb))

