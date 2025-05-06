-- drop function if exists sm_sc.ft_nn_node2node_path(bigint, bigint, bigint);
create or replace function sm_sc.ft_nn_node2node_path
(
  i_work_no         bigint    , 
  i_begin_node_no   bigint    , 
  i_end_node_no     bigint      
)
returns table
(
  o_back_node_no    bigint    ,
  o_fore_node_no    bigint    ,
  o_path_ord_no     int       ,
  o_node_type       varchar(16)
)
as 
$$
declare
  v_begin_depth     int        :=  (select nn_depth_no from sm_sc.tb_nn_node where work_no = i_work_no and node_no = i_begin_node_no);
  v_end_depth       int        :=  (select nn_depth_no from sm_sc.tb_nn_node where work_no = i_work_no and node_no = i_end_node_no);
  
begin

  if exists (select  from sm_sc.tb_nn_node where work_no = i_work_no and nn_depth_no is null and node_type <> 'input')
  then
    raise exception 'NN depth exception!  There are nodes without nn_depth_no value.';
  end if;
  
  if v_begin_depth >= v_end_depth
  then
    raise exception 'NN depth exception!  nn_depth_no of i_begin_node_no must be <= i_end_node_no''s.';
  end if;
  
  return query
    with recursive 
    cte_aggr_fore as 
    (
      select 
        tb_a_base.back_node_no,
        tb_a_base.fore_node_no,
        tb_a_base.path_ord_no
      from sm_sc.tb_nn_path tb_a_base
      where back_node_no = i_begin_node_no         -- 103010025
        and tb_a_base.work_no = i_work_no     -- 2022030501
      union
      select 
        tb_a_incre.back_node_no,
    	tb_a_incre.fore_node_no,
        tb_a_incre.path_ord_no
      from cte_aggr_fore tb_a_base
      inner join sm_sc.tb_nn_path tb_a_incre
        on tb_a_incre.work_no = i_work_no     -- 2022030501
        and tb_a_incre.back_node_no = tb_a_base.fore_node_no
      inner join sm_sc.tb_nn_node tb_a_node_incre
        on tb_a_node_incre.work_no = i_work_no     -- 2022030501
        and tb_a_node_incre.node_no = tb_a_incre.fore_node_no
        and tb_a_node_incre.nn_depth_no <= v_end_depth      -- 60
    ),
    cte_aggr_back as 
    (
      select 
        tb_a_base.back_node_no,
        tb_a_base.fore_node_no,
        tb_a_base.path_ord_no
      from sm_sc.tb_nn_path tb_a_base
      inner join cte_aggr_fore tb_a_fore
        on tb_a_fore.back_node_no = tb_a_base.back_node_no
        and tb_a_fore.fore_node_no = tb_a_base.fore_node_no
      where tb_a_base.fore_node_no = i_end_node_no         -- 106020001
        and tb_a_base.work_no = i_work_no     -- 2022030501
      union
      select 
        tb_a_decre.back_node_no,
    	tb_a_decre.fore_node_no,
        tb_a_decre.path_ord_no
      from cte_aggr_back tb_a_base
      -- 有向无环图的局部两节点之间遍历：两节点深度之间的 前向扩散 与 反向扩散 的交集就是局部遍历
      inner join sm_sc.tb_nn_path tb_a_decre
        on tb_a_decre.work_no = i_work_no     -- 2022030501
        and tb_a_decre.fore_node_no = tb_a_base.back_node_no
      inner join cte_aggr_fore tb_a_fore
        on tb_a_fore.back_node_no = tb_a_decre.back_node_no
        and tb_a_fore.fore_node_no = tb_a_decre.fore_node_no
      inner join sm_sc.tb_nn_node tb_a_node_decre
        on tb_a_node_decre.work_no = i_work_no     -- 2022030501
        and tb_a_node_decre.node_no = tb_a_decre.back_node_no
        and tb_a_node_decre.nn_depth_no >= v_begin_depth      -- 1
    )
    select 
      back_node_no, 
      fore_node_no,
      path_ord_no ,
      'main' :: varchar(16) as node_type
    from cte_aggr_back
    union 
    select 
      tb_a_asso.back_node_no, 
      tb_a_asso.fore_node_no,
      tb_a_asso.path_ord_no ,
      'leaf' :: varchar(16) as node_type
    from cte_aggr_back tb_a_back_tail
    inner join sm_sc.tb_nn_path tb_a_asso
      on tb_a_asso.fore_node_no = tb_a_back_tail.back_node_no
      and tb_a_asso.work_no = i_work_no     -- 2022030501
    left join cte_aggr_back tb_a_main
      on tb_a_main.fore_node_no = tb_a_asso.fore_node_no
      and tb_a_main.back_node_no = tb_a_asso.back_node_no
    where tb_a_main.back_node_no is null
      and tb_a_asso.fore_node_no <> i_begin_node_no         -- 103010025
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;


-- -- select * from sm_sc.tb_nn_path
-- -- select * from sm_sc.tb_nn_node where node_no in (103010025, 106020001)
-- select o_back_node_no, o_fore_node_no, o_path_ord_no, o_node_type from sm_sc.ft_nn_node2node_path(2022030501, 103010025, 106020001)