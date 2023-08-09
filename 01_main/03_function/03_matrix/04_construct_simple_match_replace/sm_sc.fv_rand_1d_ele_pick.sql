-- -- 从若干个样本中，随机拣取一个
-- drop function if exists sm_sc.fv_rand_ele_pick(anyarray);
create or replace function sm_sc.fv_rand_ele_pick
(
  i_all_eles                anyarray
)
returns table 
(
  o_remain_arr      anyarray   ,
  o_pick_arr        anyarray
)
as
$$
declare -- here
  v_pick_no   int   := round(random() * array_length(i_all_eles, 1) + 0.5 :: float)::int;
begin
  if array_ndims(i_all_eles) > 1
  then
    raise exception 'i_all_eles should be 1-d array';
  end if;
  
  return query
    select 
      i_all_eles[ : v_pick_no - 1] || i_all_eles[v_pick_no + 1 :]   as  o_remain_arr,
      i_all_eles[v_pick_no : v_pick_no]                                        as  o_pick_arr
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select o_remain_arr, o_pick_arr from sm_sc.fv_rand_ele_pick(array[1,2,3,4,5,6,7,8,9]);

-- -----------------------------------------------------

-- drop function if exists sm_sc.fv_rand_1d_ele_pick(anyarray, bigint);
create or replace function sm_sc.fv_rand_1d_ele_pick
(
  i_all_eles               anyarray,
  i_pick_cnt               bigint
)
returns table 
(
  o_remain_arr      anyarray   ,
  o_pick_arr        anyarray
)
as
$$
-- declare -- here

begin
  -- 审计是一维
  if array_ndims(i_all_eles) > 1
  then
    raise exception 'i_all_eles should be 1-d array. ';
  end if;

  -- 审计 拣取数量 大于 0
  if i_pick_cnt < 0
  then
    raise exception 'should i_pick_cnt >= 0. ';
  end if;
  
  -- 审计 拣取数量 不大于样本数
  if i_pick_cnt > array_length(i_all_eles, 1)
  then
    raise exception 'pick_cnt must be less than all_cnt.';  
  end if;

  -- 开始排列组合拣取算法
  -- 拣取数等于样本数，则拣取全部
  if i_pick_cnt = array_length(i_all_eles, 1)
  then
    return query
      select i_all_eles[0 : 0], i_all_eles
    ;
  -- 拣取数大于1时，则递归拣取
  elsif i_pick_cnt < array_length(i_all_eles, 1) and i_pick_cnt > 1
  then 
    -- 拣取数大于样本数的一半以上，则反向拣取
    if i_pick_cnt <= array_length(i_all_eles, 1) / 2
    then 
      return query
        select 
          tb_a_recur.a_remain_arr                           as o_remain_arr    ,
          tb_a_cur.a_pick_arr || tb_a_recur.a_pick_arr      as o_pick_arr  
        from sm_sc.fv_rand_ele_pick(i_all_eles) tb_a_cur(a_remain_arr, a_pick_arr)    -- 本次
          , sm_sc.fv_rand_1d_ele_pick(tb_a_cur.a_remain_arr, i_pick_cnt - 1) tb_a_recur(a_remain_arr, a_pick_arr)
      ;
    else
      return query
        select 
          tb_a_cur.a_pick_arr || tb_a_recur.a_pick_arr      as o_remain_arr   ,
          tb_a_recur.a_remain_arr                           as o_pick_arr 
        from sm_sc.fv_rand_ele_pick(i_all_eles) tb_a_cur(a_remain_arr, a_pick_arr)    -- 本次
          , sm_sc.fv_rand_1d_ele_pick(tb_a_cur.a_remain_arr, array_length(i_all_eles, 1) - i_pick_cnt - 1) tb_a_recur(a_remain_arr, a_pick_arr)
      ;
    end if;
  -- 拣取数为1时，则拣取一个
  elsif i_pick_cnt = 1
  then 
    return query
      select 
        tb_a.o_remain_arr    ,
        tb_a.o_pick_arr  
      from sm_sc.fv_rand_ele_pick(i_all_eles) tb_a(o_remain_arr, o_pick_arr)
    ;
  -- 拣取数为0时，则拣取集合为空
  elsif i_pick_cnt = 0
  then 
    return query
      select i_all_eles, i_all_eles[0 : 0]
    ;
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select o_remain_arr, o_pick_arr from sm_sc.fv_rand_1d_ele_pick(array[1,2,3,4,5,6,7,8,9], 0);
-- select o_remain_arr, o_pick_arr from sm_sc.fv_rand_1d_ele_pick(array[1,2,3,4,5,6,7,8,9], 1);
-- select o_remain_arr, o_pick_arr from sm_sc.fv_rand_1d_ele_pick(array[1,2,3,4,5,6,7,8,9], 3);
-- select o_remain_arr, o_pick_arr from sm_sc.fv_rand_1d_ele_pick(array[1,2,3,4,5,6,7,8,9], 7);
-- select o_remain_arr, o_pick_arr from sm_sc.fv_rand_1d_ele_pick(array[1,2,3,4,5,6,7,8,9], 9);

-- ---------------------------------------------------------------------------

-- drop function if exists sm_sc.fv_rand_1d_ele_pick(bigint, bigint);
create or replace function sm_sc.fv_rand_1d_ele_pick
(
  i_all_cnt                bigint,
  i_pick_cnt               bigint
)
returns bigint[]
as
$$
-- declare -- here

begin
  return 
  (
    select 
      o_pick_arr
    from sm_sc.fv_rand_1d_ele_pick((select array_agg(a_no) from generate_series(1, i_all_cnt) tb_a_no(a_no)), i_pick_cnt) tb_a
  )
  ;
end
$$
language plpgsql volatile
parallel safe
cost 100;

-- select sm_sc.fv_rand_1d_ele_pick(8, 3);


-- -------------------------------------------------------------------------


-- -- -- drop function if exists sm_sc.fv_rand_1d_ele_pick(int, int);
-- -- create or replace function sm_sc.fv_rand_1d_ele_pick
-- -- (
-- --   i_all_cnt                int,
-- --   i_pick_cnt               int
-- -- )
-- -- returns int[]
-- -- as
-- -- $$
-- -- declare -- here
-- --   v_sess_id          bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)   :=    replace(gen_random_uuid()::char(36), '-', '')::char(32);
-- --   v_cur_no           int        :=    i_pick_cnt;
-- --   v_cur_ele_no       int;
-- --   v_remain_final     int        := i_all_cnt - i_pick_cnt;
-- --   v_return           int[];
-- -- 
-- -- begin
-- -- 
-- --   if i_pick_cnt > i_all_cnt
-- --   then
-- --     raise exception 'pick_cnt must be less than all_cnt.';
-- --   end if;
-- -- 
-- --   -- create temp table if not exists sm_sc.__vt_rand_1d_ele
-- --   -- (
-- --   --   sess_id     char(32)    ,     -- 会话 id
-- --   --   arr_picked  int[]       ,     -- 已捡取元素编号
-- --   --   arr_remain  int[]       ,     -- 剩余元素编号
-- --   --   primary key (sess_id)
-- --   -- );
-- -- 
-- --   insert into sm_sc.__vt_rand_1d_ele
-- --   (
-- --     sess_id            ,
-- --     arr_remain         ,
-- --     arr_picked         
-- --   )                    
-- --   select               
-- --     v_sess_id          ,
-- --     array_agg(a_ele_no),
-- --     array[] :: int[]
-- --   from generate_series(1, i_all_cnt) tb_a(a_ele_no)
-- --   ;
-- -- 
-- --   while v_cur_no >= 1
-- --   loop 
-- --     v_cur_ele_no := round(random() * (v_remain_final + v_cur_no) + 0.5 :: float)::int;
-- -- 
-- -- -- -- debug
-- -- -- raise notice 'v_cur_ele_no: %; v_cur_no: %; ', v_cur_ele_no, v_cur_no;
-- -- 
-- --     update sm_sc.__vt_rand_1d_ele
-- --     set 
-- --       arr_picked = array_append(arr_picked, arr_remain[v_cur_ele_no]),
-- --       arr_remain[v_cur_ele_no : greatest(v_cur_ele_no, v_remain_final + v_cur_no - 1)] = arr_remain[least(v_cur_ele_no + 1, i_all_cnt) : least(greatest(v_cur_ele_no + 1, v_remain_final + v_cur_no), i_all_cnt)]
-- --     where sess_id = v_sess_id
-- --     ;
-- -- 
-- --     v_cur_no := v_cur_no - 1;
-- --   end loop;
-- -- 
-- --   v_return := 
-- --   (
-- --     select 
-- --       arr_picked
-- --     from sm_sc.__vt_rand_1d_ele
-- --     where sess_id = v_sess_id
-- --   );
-- -- 
-- --   delete from sm_sc.__vt_rand_1d_ele where sess_id = v_sess_id;
-- --   
-- --   return v_return;
-- -- end
-- -- $$
-- -- language plpgsql volatile
-- -- parallel unsafe
-- -- cost 100;
-- -- 
-- -- -- -- set force_parallel_mode = 'off';
-- -- -- select sm_sc.fv_rand_1d_ele_pick(8, 3);