drop procedure if exists sm_sc.prc_kmeans_pp(typ_arr_point[], float);
create or replace procedure sm_sc.prc_kmeans_pp
(
  i_work_no                bigint                      -- 任务编号
)
as
$$

-- -------------------- declare part --------------------------------------------------
declare
  v_sess_id   bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)        :=       replace(gen_random_uuid()::char(36), '-', '')::char(32);

-- cnt of points
  v_point_cnt int := (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
-- amt of points' demensions
  v_dimension_amt int;

-- for cursor of loop
  v_loop_cnt int := 1;

-- -------------------- func part --------------------------------------------------
begin
  insert into sm_sc.__vt_kmean_ods_array
  (
    sess_id   ,
    point_id  ,
    point_arr
  )
  -- parse to point_id, point_arr
  select 
    v_sess_id,
    ord_no   ,
    i_indepdt
  from sm_sc.tb_nn_train_input_buff
  where work_no = i_work_no
  ;
  -- select * from sm_sc.__vt_kmean_ods_array limit 50

  -- calcu v_dimension_amt
  select 
    array_length(point_arr, 1) into v_dimension_amt 
  from sm_sc.__vt_kmean_ods_array
  where sess_id = v_sess_id
  limit 1
  ;

  -- a random point as the first cluster point
  insert into sm_sc.__vt_kmean_list_cluster(sess_id, cluster_point_no)
  select 
    v_sess_id,
    v_cluster_point_no as cluster_point_no
  from generate_series(1, i_cluster_cnt) v_cluster_point_no
  ;

  update sm_sc.__vt_kmean_list_cluster tar
  set cluster_point_arr = (select point_arr from sm_sc.__vt_kmean_ods_array where sess_id = v_sess_id limit 1)
  where tar.cluster_point_no = 1
    and tar.sess_id = v_sess_id
  ;
  -- ------------------- prepare done ------------------------------------------
  
  -- find all cluster points one by one
  while v_loop_cnt <= least(i_cluster_cnt, v_point_cnt)
  loop
    with
    cte_point_cluster_distance_pre as
    (
      select 
        tb_a_ods.point_id 
        , tb_a_ods.point_arr
        , min(sm_sc.fv_o_distance(tb_a_ods.point_arr, tb_a_clusters.cluster_point_arr, v_dimension_amt)) as point_cluster_distance_pre
      from sm_sc.__vt_kmean_ods_array tb_a_ods, sm_sc.__vt_kmean_list_cluster tb_a_clusters
      where tb_a_ods.sess_id = v_sess_id
        and tb_a_clusters.sess_id = v_sess_id
      group by tb_a_ods.point_id
    )
    ,
    cte_point_cluster_weight_position as
    (
      select
        point_id,
        point_arr,
        sum(point_cluster_distance_pre) over(order by point_id rows between UNBOUNDED preceding and 0 following) as point_cluster_weight_position
      from cte_point_cluster_distance_pre
      where point_cluster_distance_pre > 0
    )
    ,
    cte_random_position as
    (
      select sum(point_cluster_distance_pre) * random() as random_position
      from cte_point_cluster_distance_pre
    )
    ,
    cte_cluster_point as
    (
      select 
        point_id
        , point_arr
        , point_cluster_weight_position
        , random_position
      from cte_point_cluster_weight_position, cte_random_position
      where point_cluster_weight_position >= random_position
      order by point_cluster_weight_position
      limit 1
    )
    update sm_sc.__vt_kmean_list_cluster tar
    set cluster_point_arr = sour.point_arr
    from cte_cluster_point sour
    where tar.cluster_point_no = v_loop_cnt
      and tar.sess_id = v_sess_id
    ;
    select v_loop_cnt + 1 into v_loop_cnt;

  end loop; 
  -- find cluster points down ---------------------------------
  
  -- reset cluster_point_no for all point_id's
  with
  cte_point_cluster_distance_post as
  (
    select
      tb_a_ods.point_id,
      tb_a_clusters.cluster_point_no,
      row_number() over(partition by tb_a_ods.point_id order by sm_sc.fv_o_distance(tb_a_ods.point_arr, tb_a_clusters.cluster_point_arr, v_dimension_amt)) as point_cluster_distance_ord
    from sm_sc.__vt_kmean_ods_array tb_a_ods
    cross join sm_sc.__vt_kmean_list_cluster tb_a_clusters
    where tb_a_ods.sess_id = v_sess_id
      and tb_a_clusters.sess_id = v_sess_id
  )
  update sm_sc.__vt_kmean_ods_array tar
  set cluster_point_no = cte_distance.cluster_point_no
  from cte_point_cluster_distance_post cte_distance
  where cte_distance.point_cluster_distance_ord = 1
    and cte_distance.point_id = tar.point_id
    and tar.sess_id = v_sess_id
  ;

  -- spread
  select 1 into v_loop_cnt;
  while
    exists(select  from sm_sc.__vt_kmean_list_cluster tb_a_clusters 
           inner join sm_sc.__vt_kmean_ods_array tb_a_ods 
             on tb_a_clusters.cluster_point_no = tb_a_ods.cluster_point_no 
           where is_loop_done is not true
             and tb_a_ods.sess_id = v_sess_id
             and tb_a_clusters.sess_id = v_sess_id
          )
    -- and v_loop_cnt <= i_loop_cnt
  loop
    -- re-calcu cluster_point_arr for all cluster_point_no
    with
    cte_cluster_dimention_arr as
    (
      select 
        cluster_point_no,
        a_cur_dim_no as dim_no,
        avg(point_arr[a_cur_dim_no]) as cluster_dimention_arr
      from sm_sc.__vt_kmean_ods_array tb_a_ods, generate_series(1, v_dimension_amt) tb_a_cur_dim_no(a_cur_dim_no)
      where tb_a_ods.sess_id = v_sess_id
      group by cluster_point_no, a_cur_dim_no
    )
    ,
    cte_cluster_point_arr as
    (
      select 
        cluster_point_no,
        array_agg(cluster_dimention_arr order by dim_no) as cluster_point_arr
      from cte_cluster_dimention_arr
      group by cluster_point_no
    )   
    update sm_sc.__vt_kmean_list_cluster tar
    set is_loop_done = case when sm_sc.fv_o_distance(tar.cluster_point_arr, cte_c_arr.cluster_point_arr, v_dimension_amt) < 0.001
                              then true
                            else false
                       end
      , cluster_point_arr = cte_c_arr.cluster_point_arr
      , loop_cnt = v_loop_cnt
    from cte_cluster_point_arr cte_c_arr
    where cte_c_arr.cluster_point_no = tar.cluster_point_no
      and tar.sess_id = v_sess_id
    ;

    -- reset cluster_point_no for all point_id
    with
    cte_point_cluster_distance as 
    (
      select 
        tb_a_ods.point_id,
        tb_a_clusters.cluster_point_no,
        row_number() over(partition by tb_a_ods.point_id order by sm_sc.fv_o_distance(tb_a_ods.point_arr, tb_a_clusters.cluster_point_arr, v_dimension_amt)) as point_cluster_distance_ord
      from sm_sc.__vt_kmean_ods_array tb_a_ods
      cross join sm_sc.__vt_kmean_list_cluster tb_a_clusters
      where tb_a_ods.sess_id = v_sess_id
        and tb_a_clusters.sess_id = v_sess_id
    )
    update sm_sc.__vt_kmean_ods_array tar
    set cluster_point_no = cte_distance.cluster_point_no
    from cte_point_cluster_distance cte_distance
    where cte_distance.point_id = tar.point_id
      and tar.sess_id = v_sess_id
    ;

    select v_loop_cnt + 1 into v_loop_cnt;
  end loop;

  -- output of func
  update sm_sc.tb_nn_train_input_buff t_a_tar
  set 
    i_depdt = tb_a_mid.i_indepdt,
    i_depdt = tb_a_clusters.cluster_point_arr
  from sm_sc.__vt_kmean_ods_array tb_a_ods
  inner join sm_sc.__vt_kmean_list_cluster tb_a_clusters
    on tb_a_ods.cluster_point_no = tb_a_clusters.cluster_point_no
  where tb_a_ods.sess_id = v_sess_id
    and tb_a_clusters.sess_id = v_sess_id
	and t_a_tar.work_no = i_work_no
	and t_a_tar.ord_no = tb_a_ods.point_id
  ;
  
  delete from sm_sc.__vt_kmean_list_cluster where sess_id = v_sess_id;
  commit;
  delete from sm_sc.__vt_kmean_ods_array where sess_id = v_sess_id;
  commit;

end
$$
language plpgsql;

-- ---------------

-- insert into sm_sc.tb_cluster_task
-- (
--   work_no               ,
--   cluster_cnt           ,
--   max_point_distance    ,
--   cluster_type      
-- )
-- select 
--   -1,
--   2,
--   null,   -- 5,
--   1,
-- ;
-- 
-- insert into sm_sc.tb_nn_train_input_buff
-- (
--   ord_no,
--   i_indepdt
-- )
-- select 1, array[11.0, 22.1, 33.4]
-- union all
-- select 1, array[11.1, 22.2, 33.3]
-- union all
-- select 1, array[44.4, 55.5, 66.6]
-- union all
-- select 1, array[44.6, 55.7, 66.4]
-- union all
-- select 1, array[44.5, 55.4, 66.2]
-- return 
-- ;
-- 
-- call sm_sc.prc_kmeans_pp(-1);

