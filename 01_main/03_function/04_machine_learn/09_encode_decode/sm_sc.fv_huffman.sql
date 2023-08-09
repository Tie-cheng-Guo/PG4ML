-- -- 参考
-- --   https://blog.csdn.net/qq_36653505/article/details/81701181

-- -- create sequence if not exists huffman_seq start 1000000000;

-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_huffman(float[]);
create or replace function sm_sc.fv_huffman
(
  i_weights     float[]
)
returns varbit[]
as
$$
declare 
  v_sess_id   bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)     :=   replace(gen_random_uuid()::text, '-', '')::char(32);
  v_ret       varbit[];
begin

  -- -- create temp table if not exists sm_sc.__vt_tmp_huffman
  -- -- (
  -- --   sess_id         char(32)                                          ,    -- 回话id
  -- --   node_no         bigint       default nextval('huffman_seq')       ,    -- 自然序列编号
  -- --   is_compared     boolean      default false                        ,    -- 是否已经比较入树
  -- --   node_weight     float                                    ,    -- 权值
  -- --   is_org          boolean                                           ,    -- 是否是原始 input 的节点
  -- --   tree_code       varbit                                            ,    -- 单次比较后入树结果，左子树为0，右子树为1，
  -- --   father_node_no  bigint                                               ,    -- 父节点
  -- --   primary key (sess_id, node_no)
  -- -- )
  -- -- ;
  -- -- 
  -- -- create index if not exists __idx_huffman_node_weight
  -- --   on sm_sc.__vt_tmp_huffman(sess_id, is_compared, node_weight);  
  -- -- create index if not exists __idx_huffman_father
  -- --   on sm_sc.__vt_tmp_huffman(sess_id, father_node_no);
  
  -- i_weights 当做初始 node
  insert into sm_sc.__vt_tmp_huffman
  (
    sess_id             ,
    node_no             ,
    is_compared         ,
    node_weight         ,
    is_org
  )
  select 
    v_sess_id                  as sess_id          ,
    row_number() over()        as node_no          ,
    false                      as is_compared      ,
    a_node_weight              as node_weight      ,
    true                       as is_org
  from unnest(i_weights) tb_a(a_node_weight)
  ;
  
  while exists (select from sm_sc.__vt_tmp_huffman where sess_id = v_sess_id and is_compared = false having count(*) > 1)
  loop
    with
    -- 根据 weight 排序，查找 weight 最小的两个 
    cte_min_2 as
    (
      select 
        node_no                                             ,
        (~ (row_number() over() - 1) :: bit) :: varbit    as tree_code ,
        node_weight
      from sm_sc.__vt_tmp_huffman
      where sess_id = v_sess_id
        and is_compared is false
      order by node_weight 
      limit 2
    ),
    -- 插入新的父节点记录
    cte_insert as
    (
      insert into sm_sc.__vt_tmp_huffman
      (
        sess_id,
        is_compared,
        node_weight,
        is_org
      )
      select 
        v_sess_id        as  sess_id       ,
        false            as  is_compared   ,
        sum(node_weight) as  node_weight   ,
        false            as  is_org
      from cte_min_2
      returning node_no
    )
    -- 更新入树标记和父节点路径关系
    update sm_sc.__vt_tmp_huffman tb_a_sour
    set 
      is_compared = true,
      tree_code = tb_a_min.tree_code,
      father_node_no = tb_a_insert.node_no
    from cte_min_2 tb_a_min, cte_insert tb_a_insert
    where tb_a_min.node_no = tb_a_sour.node_no
      and tb_a_sour.sess_id = v_sess_id
    ;
  end loop;

  -- 从顶点，迭代树的深度，拼接 huffman 编码，最终输出
  with recursive
  cte_nodes as
  (
    select 
      node_no,
      '' :: varbit as huffman_tree_code,
      is_org
    from sm_sc.__vt_tmp_huffman
    where sess_id = v_sess_id
      and is_compared is false 
    union all 
    select 
      tb_a_incre.node_no,
      tb_a_main.huffman_tree_code || tb_a_incre.tree_code as huffman_tree_code,
      tb_a_incre.is_org
    from cte_nodes tb_a_main
    inner join sm_sc.__vt_tmp_huffman tb_a_incre
      on tb_a_incre.sess_id = v_sess_id
        and tb_a_incre.father_node_no = tb_a_main.node_no
  )
  select 
    array_agg(huffman_tree_code order by node_no) into v_ret
  from cte_nodes
  where is_org is true
  ;
  
  delete from sm_sc.__vt_tmp_huffman;
  return v_ret;

end
$$
language plpgsql volatile 
parallel unsafe
cost 100;

-- -- set force_parallel_mode = 'off';
-- select sm_sc.fv_huffman(array[1, 3, 8, 2, 9, 13, 19])
