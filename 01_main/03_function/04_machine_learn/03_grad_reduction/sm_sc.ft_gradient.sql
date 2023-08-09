-- 计算图的设计
-- https://www.zhihu.com/question/66200879/answer/317086336
-- https://blog.csdn.net/hohaizx/article/details/82313143
-- -- 图中一个顶点对另一个顶点的导数等于该顶点到另一个顶点的路径上所有导数的乘积
-- -- 当存在从一个顶点到另一个顶点的多条路径时，那么这个顶点对另一个顶点的导数等于所有路径上导数的和
-- --------------------------------------------------------------------------------------------------------------------------------
-- 标量 scalar 运算，而非张量矩阵运算的求导
-- 返回微分数值

-- 张量运算的求导，需构建雅可比矩阵
-- https://blog.csdn.net/bitcarmanlee/article/details/78819025

-- drop function if exists sm_sc.ft_gradient(varchar(64)[], jsonb);
create or replace function sm_sc.ft_gradient
(
  i_indepdt_vars_names           varchar(64)[],
  -- i_indepdt_var_name           varchar(64),
  i_opr_chain                  jsonb   -- 假定入参值已全部写入 out_value
)                              
returns table                  
(                              
  o_indepdt_vars_name            varchar(64),
  o_grad                       float
)
as
$$
declare -- here
  v_sess_id               bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)       := replace(gen_random_uuid()::char(36), '-', '')::char(32);
  v_cur_out_params        varchar(64)[];
  v_cur_opr_var_params    varchar(64)[]  := i_indepdt_vars_names;
  v_cur_indepdt_var_name    varchar(64);
  v_o_grads               float[];
  v_cur_no                int  := 1;

-- debug
  v_debug_1   text;
  v_debug_2   text;


begin
  -- 计算图反序列化至缓存表
  insert into sm_sc._vt_fn_grad__chain
  (
    sess_id              ,
    out_param             ,
    param_loc             ,
    in_param              ,
    in_value              ,
    out_opr
  )
  select
    v_sess_id                     ,
    o_out_param    as out_param    ,
    o_param_loc    as param_loc    ,
    o_in_param     as in_param     ,
    o_in_value     as in_value     ,
    o_out_opr      as out_opr  
  from sm_sc.ft_computational_graph_deserialize(i_opr_chain)   -- (pgv_get('vars', 'a_opr_chain_03', NULL::jsonb))
  ;

  insert into sm_sc._vt_fn_grad__forward
  (
    sess_id              ,
    out_param             ,
    in_params             ,
    in_values             ,
    out_opr
  )
  -- 化作函数式形式，准备执行函数式计算
  select 
    v_sess_id,
    out_param,
    array_agg(in_param order by param_loc) as in_params,
    array_agg(in_value order by param_loc) as in_values,
    out_opr
  from sm_sc._vt_fn_grad__chain
  where sess_id = v_sess_id
  group by out_param, out_opr
  ;

  -- 前向运算结果
  while exists (select  from sm_sc._vt_fn_grad__forward where sess_id = v_sess_id and out_param = '' and calcu_val is null) and v_cur_no <= 100
  loop

    -- 找到本轮入参已经齐备、又尚未做前向计算的计算关系，本轮函数式数学计算
    with
    cte_forward as
    (
      update sm_sc._vt_fn_grad__forward
      set calcu_val = sm_sc.fv_algebra_execute(out_opr, in_values)
      where sess_id = v_sess_id
        and array_position(in_values, null) is null
        and calcu_val is null
      returning out_param
    )
    select array_agg(distinct out_param) :: varchar(64)[] into v_cur_out_params from cte_forward
    ;

    -- 本轮计算结果代入下一轮 in_param, 更新至计算链寄存表
    with 
    cte_upd_in_param as
    (
      update sm_sc._vt_fn_grad__chain tar
      set in_value = sour.calcu_val
      from sm_sc._vt_fn_grad__forward sour
      where sour.out_param = tar.in_param
        and tar.sess_id = v_sess_id
        and sour.sess_id = v_sess_id
        and tar.in_param = any(v_cur_out_params)
      returning tar.out_param
    )
    select array_agg(distinct out_param) into v_cur_out_params from cte_upd_in_param
    ;

    -- 本轮计算结果代入下一轮函数式
    with 
    cte_in_values as
    (
      select 
        out_param,
        array_agg(in_value order by param_loc) as in_values
      from sm_sc._vt_fn_grad__chain
      where sess_id = v_sess_id
        and out_param = any(v_cur_out_params)
      group by sess_id, out_param
    )
    update sm_sc._vt_fn_grad__forward tar
    set in_values = sour.in_values
    from cte_in_values sour
    where tar.sess_id = v_sess_id
      and sour.out_param = tar.out_param
    ;

    -- update sm_sc._vt_fn_grad__forward tar
    -- set in_values = sm_sc.fv_pos_replaces(tar.in_values, array_positions(tar.in_params, sour.out_param), sour.calcu_val)  -- -- 无法更新多行多个 sour.calcu_val 到 in_values，_vt_fn_grad__forward 单表更新不可行
    -- from sm_sc._vt_fn_grad__forward sour
    -- where sour.out_param = any(tar.in_params)
    --   and sour.out_param = any(v_cur_out_params)
    --   and tar.sess_id = v_sess_id
    --   and sour.sess_id = v_sess_id
    -- ;
    v_cur_no := v_cur_no + 1;
  end loop;

  -- 更新协参
  update sm_sc._vt_fn_grad__chain tar
  set co_vals = nullif(sour.in_values[ : tar.param_loc - 1] || sour.in_values[tar.param_loc + 1 : ], array[]::float[])
  from sm_sc._vt_fn_grad__forward sour
  where sour.out_param = tar.out_param
    and tar.sess_id = v_sess_id
    and sour.sess_id = v_sess_id
  ;

  v_cur_no := 1;

  -- 神经元内前向梯度
  -- -- 求每步(边)原子运算梯度
  while v_cur_opr_var_params is not null and v_cur_no <= 100
  loop
    with cte_front as
    (
      update sm_sc._vt_fn_grad__chain
      set grad_val = 
            sm_sc.fv_gradient_opr
            (
              in_value, 
              out_opr, 
              param_loc, 
              calcu_val, 
              co_vals
            )
      where sess_id = v_sess_id
        and in_param = any(v_cur_opr_var_params)
        and grad_val is null
      returning out_param
    )
    select array_agg(distinct out_param) :: varchar(64)[] into v_cur_opr_var_params from cte_front
    ;
    v_cur_no := v_cur_no + 1;
  end loop;


  foreach v_cur_indepdt_var_name in array i_indepdt_vars_names
  loop 
    with recursive
    cte_front as
    (
      select 
        out_param,
        in_param,
        param_loc,
        grad_val as chain_grad_val
      from sm_sc._vt_fn_grad__chain
      where sess_id = v_sess_id
        and in_param = v_cur_indepdt_var_name
      union all
      select 
        tb_a_incre.out_param,
        tb_a_incre.in_param,
        tb_a_incre.param_loc,
        (tb_a_main.chain_grad_val * tb_a_incre.grad_val)::float as chain_grad_val
      from cte_front tb_a_main
      inner join sm_sc._vt_fn_grad__chain tb_a_incre
      on tb_a_incre.in_param = tb_a_main.out_param
      where tb_a_incre.sess_id = v_sess_id
    )
    select 
      array_append(v_o_grads, sum(chain_grad_val)) into v_o_grads
    from cte_front
	where out_param = ''
    ;
  end loop;

  delete from sm_sc._vt_fn_grad__forward where sess_id = v_sess_id;
  delete from sm_sc._vt_fn_grad__chain where sess_id = v_sess_id;

  return query
    select 
      depdt_vars_name, grad
    from unnest(i_indepdt_vars_names, v_o_grads) tb_a_ret(depdt_vars_name, grad);

end
$$
language plpgsql volatile
cost 100;



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
-- --           "out_param": "v_x_in",
-- --           "out_value": 1.5
-- --         },
-- --         {
-- --           "out_param": "v_y_in",
-- --           "out_value": 1.5
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
-- --               "out_param": "v_x_in",
-- --               "out_value": 1.5
-- --             },
-- --             {
-- --               "out_param": "v_y_in",
-- --               "out_value": 1.5
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
-- --           "out_param": "v_x_in",
-- --           "out_value": 1.5
-- --         },
-- --         {
-- --           "out_value": 2
-- --         }
-- --       ]
-- --     }
-- --   ]
-- -- }
-- -- '::jsonb);

-- select * from sm_sc.ft_gradient(array['v_x_in'], pgv_get('vars', 'a_opr_chain_03', NULL::jsonb))
-- select * from sm_sc.ft_gradient(array['v_x_in', 'v_y_in'], pgv_get('vars', 'a_opr_chain_03', NULL::jsonb))
