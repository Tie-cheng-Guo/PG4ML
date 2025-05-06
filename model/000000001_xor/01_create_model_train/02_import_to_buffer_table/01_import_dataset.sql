-- 用例1：xor 分类
-- https://blog.csdn.net/weixin_42788078/article/details/88783880
-- https://www.cnblogs.com/Belter/p/6711160.html
-- https://blog.csdn.net/sinat_28178805/article/details/118764250
    do
    $$
    declare
      -- 获得一个训练任务序号
      v_work_no   bigint  :=  -000000001;   -- lower(sm_sc.fv_get_global_seq());   -- 假定获得的序号为 -000000001
    begin
      -- 记下 v_work_no，后期匿名块以外要用到
      raise notice 'v_work_no: %', v_work_no;
      delete from sm_sc.tb_nn_train_input_buff where work_no = -000000001;  --v_work_no;
      -- 准备 xor 数据集，两个分类，四组数据，每组各4条数据
      insert into sm_sc.tb_nn_train_input_buff
      (
        work_no
      , ord_no
      , i_depdt_01     -- 因变量 - 真实值
      , i_indepdt_01   -- 自变量 - 属性
      )
      -- 有偏数据第一组
      select 
        v_work_no
      , a_ord
      , array[0.0]
      , array[0.0 - 0.25, 0.0 - 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(1, 100) tb_a_00_0(a_ord)   -- 0, 0 异或为 0
      union all
      select 
        v_work_no
      , a_ord
      , array[1.0]
      , array[0.0 + 0.25, 1.0 - 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(101, 200) tb_a_01_1(a_ord)   -- 0, 1 异或为 1
      union all
      select 
        v_work_no
      , a_ord
      , array[1.0]
      , array[1.0 - 0.25, 0.0 + 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(201, 300) tb_a_10_1(a_ord)  -- 1, 0 异或为 1
      union all
      select 
        v_work_no
      , a_ord
      , array[0.0]
      , array[1.0 + 0.25, 1.0 + 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(301, 400) tb_a_11_0(a_ord) -- 1, 1 异或为 0
      union all
      -- 有偏数据第二组
      select 
        v_work_no
      , a_ord
      , array[0.0]
      , array[0.0 + 0.25, 0.0 + 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(401, 500) tb_a_00_0(a_ord)   -- 0, 0 异或为 0
      union all
      select 
        v_work_no
      , a_ord
      , array[1.0]
      , array[0.0 - 0.25, 1.0 + 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(501, 600) tb_a_01_1(a_ord)   -- 0, 1 异或为 1
      union all
      select 
        v_work_no
      , a_ord
      , array[1.0]
      , array[1.0 + 0.25, 0.0 - 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(601, 700) tb_a_10_1(a_ord)  -- 1, 0 异或为 1
      union all
      select 
        v_work_no
      , a_ord
      , array[0.0]
      , array[1.0 - 0.25, 1.0 - 0.25] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(701, 800) tb_a_11_0(a_ord) -- 1, 1 异或为 0
      union all
      -- 无偏数据
      select 
        v_work_no
      , a_ord
      , array[0.0]
      , array[0.0, 0.0] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(801, 900) tb_a_00_0(a_ord)   -- 0, 0 异或为 0
      union all
      select 
        v_work_no
      , a_ord
      , array[1.0]
      , array[0.0, 1.0] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(901, 1000) tb_a_01_1(a_ord)   -- 0, 1 异或为 1
      union all
      select 
        v_work_no
      , a_ord
      , array[1.0]
      , array[1.0, 0.0] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(1001, 1100) tb_a_10_1(a_ord)  -- 1, 0 异或为 1
      union all
      select 
        v_work_no
      , a_ord
      , array[0.0]
      , array[1.0, 1.0] :: float[] +` sm_sc.fv_new_randn(0.0, 0.1, array[2])
      from generate_series(1101, 1200) tb_a_11_0(a_ord) -- 1, 1 异或为 0
      ;
    end
    $$
    language plpgsql    