drop procedure if exists sm_sc.prc_dbscan_pp(typ_arr_point[], float);
create or replace procedure sm_sc.prc_dbscan_pp
(
  i_work_no                bigint                      -- 任务编号
)
as
$$
declare 
  v_sess_id   bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)          := replace(gen_random_uuid()::char(36), '-', '')::char(32);
-- cnt of points
  v_point_cnt bigint := (select count(*) from sm_sc.tb_nn_train_input_buff where work_no = i_work_no);
-- amt of points' dimensions
  v_dimension_amt bigint;

-- for cursor of circle
  v_point_id_cur   bigint;
  v_i_cur  bigint := 1;

-- --- func body ----------
begin
  insert into sm_sc.__vt_dbscan_ods_array
  (
    sess_id  ,
    point_id ,
    point_arr
  )
  select 
    v_sess_id,
    ord_no   ,
    i_indepdt
  from sm_sc.tb_nn_train_input_buff
  where work_no = i_work_no
  ;
  -- select * from sm_sc.__vt_dbscan_ods_array limit 50

  -- calcu v_dimension_amt
  select 
    array_length(point_arr, 1) into v_dimension_amt
  from sm_sc.__vt_dbscan_ods_array
  where sess_id = v_sess_id
  limit 1
  ;

  insert into sm_sc.__vt_dbscan_nearby_point_idx
  (
    sess_id          ,
    point_id         ,
    dimension_no   ,
    point_arr_n      ,
    point_arr
  )
  -- pivot point array
  select 
    v_sess_id                                            ,
    tb_a_ods.point_id                                         ,
    a_dimension_no                                       ,
    tb_a_ods.point_arr[a_dimension_no] as point_arr_n         ,
    case when a_dimension_no = 1 then tb_a_ods.point_arr end
  from
    generate_series(1, v_dimension_amt) a_dimension_no,
    sm_sc.__vt_dbscan_ods_array tb_a_ods
  where tb_a_ods.sess_id = v_sess_id
  ;

  -- polar coordinate the arr as dimension_0
  insert into sm_sc.__vt_dbscan_nearby_point_idx
  (
    sess_id                 ,
    point_id                ,
    dimension_no          ,
    point_arr_n
  )
  select 
    v_sess_id    ,
    sour.point_id,
    0 as dimension_no,
    power(sum(power(sour.point_arr_n, 2)), 0.5) as point_arr_n
  from sm_sc.__vt_dbscan_nearby_point_idx sour
  where sess_id = v_sess_id
  group by sour.point_id
  ;
  -- select * from sm_sc.__vt_dbscan_nearby_point_idx where dimension_no = 0 limit 50

  -- ---- prepare done  ------

  -- spread
  while
    exists (select  from sm_sc.__vt_dbscan_ods_array where dbscan_grp is null and sess_id = v_sess_id limit 1)
    and v_i_cur <= v_point_cnt
  loop
    -- cursor point: v_point_id_cur
    select 
      point_id into v_point_id_cur
    from sm_sc.__vt_dbscan_ods_array
    where dbscan_grp is null
      and sess_id = v_sess_id
    limit 1
    ;

    with
    -- find all grp_labeled points of the grp which v_point_id_cur belong to
    cte_tar_point_with_cur as
    (
      select 
        incre.point_id
      from
      (
        select distinct
          t_a_guest_incre_0.point_id,
          array[max(t_a_host_incre_0.point_arr), max(t_a_guest_incre_0.point_arr)] as host_guest_arrs
        from sm_sc.__vt_dbscan_nearby_point_idx t_a_host_incre_0
        inner join sm_sc.__vt_dbscan_nearby_point_idx t_a_guest_incre_0
          on t_a_guest_incre_0.dimension_no = t_a_host_incre_0.dimension_no
            and t_a_guest_incre_0.point_arr_n between t_a_host_incre_0.point_arr_n - i_max_point_distance
                                          and t_a_host_incre_0.point_arr_n + i_max_point_distance
        where t_a_host_incre_0.point_id = v_point_id_cur
          and t_a_host_incre_0.sess_id = v_sess_id
          and t_a_guest_incre_0.sess_id = v_sess_id
        group by t_a_guest_incre_0.point_id, t_a_host_incre_0.point_id
        having count(t_a_guest_incre_0.dimension_no) = v_dimension_amt + 1 
      ) incre
      where sm_sc.fv_o_distance(incre.host_guest_arrs, v_dimension_amt) <= i_max_point_distance
    )
    -- select * from cte_tar_point_with_cur limit 50
    ,
    cte_tar_grp_with_cur as
    (
      select distinct
        tb_a_ods.dbscan_grp as old_dbscan_grp
      from cte_tar_point_with_cur t_a_tar_point
      inner join sm_sc.__vt_dbscan_ods_array tb_a_ods
        on t_a_tar_point.point_id = tb_a_ods.point_id
      where tb_a_ods.sess_id = v_sess_id
    )
    -- select * from cte_tar_grp_with_cur limit 50
    ,
    cte_tar_upd_old_grp_with_cur as
    (
      update sm_sc.__vt_dbscan_ods_array ods
      set dbscan_grp = v_point_id_cur
      from cte_tar_grp_with_cur grp_cur
      where grp_cur.old_dbscan_grp = ods.dbscan_grp
        and ods.dbscan_grp <> v_point_id_cur
        and ods.sess_id = v_sess_id
    )

    -- update dbscan_grp in ods
    update sm_sc.__vt_dbscan_ods_array ods
    set dbscan_grp = v_point_id_cur
    from cte_tar_point_with_cur point_cur
    where point_cur.point_id = ods.point_id
      and ods.dbscan_grp is null
      and ods.sess_id = v_sess_id
    ;

    -- break circle once v_i_cur > cnt of points
    select v_i_cur + 1 into v_i_cur;
  end loop;

  update sm_sc.tb_nn_train_input_buff t_a_tar
  set 
    i_depdt = tb_a_mid.i_indepdt
  from sm_sc.__vt_dbscan_ods_array tb_a_sour, sm_sc.tb_nn_train_input_buff tb_a_mid
  where tb_a_sour.sess_id = v_sess_id
    and t_a_tar.work_no = i_work_no
	and tb_a_mid.work_no = i_work_no
	and tb_a_mid.ord_no = tb_a_sour.dbscan_grp
	and t_a_tar.ord_no = tb_a_sour.point_id
  ;

  -- delete temp data
  delete from sm_sc.__vt_dbscan_ods_array where sess_id = v_sess_id;
  commit;
  delete from sm_sc.__vt_dbscan_nearby_point_idx where sess_id = v_sess_id;
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
--   -2,
--   null,   -- 2,
--   5,
--   2,
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
-- call sm_sc.prc_kmeans_pp(-2);