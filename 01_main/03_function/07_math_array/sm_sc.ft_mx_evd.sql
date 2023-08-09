-- -- https://www.zhihu.com/question/35199474

-- -- ① 来自不同特征值的特征向量线性无关。
-- -- ② n 重特征值最多有 n-r(λiE-A) 个特征值。特别的，一重特征值有且仅有一个线性无关的特征向量。
-- -- n重根如果有n个线性无关的特征向量,则也可对角化

-- -- 方阵特征值对应的基础解系包含的向量个数不大于特征根的重数。比如说一个二重特征根它对应的特征向量基础解系的个数可能为2也可能为1。有的课本把特征根的重数叫做特征值的代数重数，把特征值对应特征向量的基础解系个数叫做特征值的几何重数，于是刚才所描述的原理也可以这么叙述：方阵特征根的几何重数不大于代数重数。那么题主可能要问，特征根几何重数等于代数重数的方阵，和特征根几何重数小于代数重数的方阵有什么区别呢？区别在于，如果一个方阵的所有特征根的几何重数均等于其代数重数，那么这个方阵是可以相似对角化的，如果这个方阵中只要有一个（或以上）的特征值的几何重数小于其代数重数，那么这个方阵就是无法相似对角化的。

-- -- 假设可对角化，基础解系相关x数量判定，
-- -- https://zhidao.baidu.com/question/1367688294526474059.html

-- -- define return eigen_values + eigen_arrays struct
-- drop type if exists cls_mx_eigen_return;
-- create type cls_mx_eigen_return as
-- (
--   mx_eigen_values    float[]      ,   -- 特征值，按大小排序
--   mx_eigen_arrays    float[][]        -- 特征向量，与mx_eigen_values一一对应；转置后便是特征分解的左边矩阵；再取逆后便是右边矩阵
-- );
-- 
-- -- --------------------------------

-- drop function sm_sc.ft_mx_evd(float[][]);
create or replace function sm_sc.ft_mx_evd
(
  in i_matrix float[][]
)
  returns table
  (
    o_eigen_value    float         ,
    o_eigen_array    float[]
  )
as
$$
-- declare here
declare 
  v_len                        int                   := array_length(i_matrix, 1);   -- 入参矩阵阶数
  v_eigen_values               float[];                                      -- 出参所有特征值
  v_eigen_values_distinct      float[];                                      -- 出参去重特征值
  v_len_distinct               int;                                                  -- 去重特征值个数（循环求解特征向量次数）
  v_eigen_arrays               float[][];                                    -- 出参所有特征向量
  v_eigen_array                float[];                                      -- 临时变量，满秩特征方程的特解(特征向量)
 
  v_loop_cur                   int                   := 1;                           -- 循环自增控制变量
  v_determinant_mx             float[][];                                    -- 行列式矩阵
  v_determinant_mx_sim         float[][];                                    -- 行列式矩阵最简行阶梯矩阵
  v_related_xs                 int[];                                                -- 相关列元编号清单
  v_unrelated_xs               int[];                                                -- 无关列元编号清单
  v_related_xs_len             int;                                                  -- 相关列元个数（当次特征值对应特征向量个数）
  v_sess_id   bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)     :=   replace(gen_random_uuid()::text, '-', '')::char(32);

begin
  -- -- drop table if exists sm_sc.__vt_tmp_eigen_arrays;
  -- -- create temp table sm_sc.__vt_tmp_eigen_arrays
  -- -- (
  -- --   sess_id        char(32)    ,
  -- --   eigen_value    float     ,
  -- --   eigen_array    float[]
  -- -- ) with (parallel_workers = 4);

  v_eigen_values = sm_sc.fv_mx_evd_value(i_matrix);

  -- 重复特征值，只循环计算一次，可能会算出对应多个特征向量。
  -- 基于8位精度特征值，以5位精度归零足够小的特征值，发现相同的零特征值归为一组，使代数重数与几何重数更准确
  v_eigen_values_distinct = (select array_agg(distinct round(eigen_value, 5) order by round(eigen_value, 5) desc) from unnest(v_eigen_values) eigen_value);
  v_len_distinct = array_length(v_eigen_values_distinct, 1);
  
  -- 代入每个特征值，求特征向量
  while v_loop_cur <= v_len_distinct
  loop
    -- 代入特征值，生成行列式矩阵
    v_determinant_mx = 
      sm_sc.fv_eye_unit
      (
        v_len
        , v_eigen_values_distinct[v_loop_cur]
      )
      -` i_matrix
    ;

    v_determinant_mx_sim = 
      sm_sc.fv_mx_rows_step_simple
      (
        v_determinant_mx
      );

    -- 查找非独立相关x编号清单（v_len - 行列式矩阵的秩）
    -- 非独立相关x的个数上限为当次特征值重复值出现次数，按上三角数值大小倒序选取；上三角数值约束绝对值远大于0；
    -- 期望非独立相关x的个数就是当次特征值重复值出现次数，否则几何重数小于代数重数，该矩阵不是可对角化矩阵；
    -- 如果存在上三角数值绝对值远大于0，却未入选非独立相关x，会是误差引起
    v_related_xs = 
      (
        with 
        cte_related_xs as
        (
          select 
            v_cur_x,
            max(abs(v_determinant_mx_sim[v_cur_y][v_cur_x])) as max_x   -- 同一个相关column x可能出现在多行，以绝对值最大的行值作为入选相关x依据
          from generate_series(1, v_len) v_cur_y
            , generate_series(v_cur_y + 1, v_len) v_cur_x
          where abs(v_determinant_mx_sim[v_cur_y][v_cur_x]) >= 1e-128 :: float
          group by v_cur_x
        ),
        cte_related_xs_grp as
        (
          select 
            v_cur_x
          from cte_related_xs
          order by max_x desc
          -- 未出现重复，则v_related_xs为空
          -- 权衡取舍后，绝对值小于0.00001的真实特征值，都将近似为0
          limit coalesce(nullif((select count(cur) from generate_series(1, v_len) cur where v_eigen_values_distinct[v_loop_cur] = round(v_eigen_values[cur], 5)), 1), 0)  
        )
        select 
          array_agg(distinct v_cur_x order by v_cur_x)
        from cte_related_xs_grp
      );

    -- 生成独立无关x编号清单
    v_unrelated_xs = 
      (
        select 
          array_agg(v_related_cur order by v_related_cur) 
        from generate_series(1, v_len) v_related_cur
        left join unnest(v_related_xs) v_unrelated
        on v_unrelated = v_related_cur
        where v_unrelated is null
      );

    -- 求解基础解系
    v_related_xs_len = array_length(v_related_xs, 1);
    if v_related_xs_len is null
    then
      -- 满秩，求解非零独立x，除以L2范数正交化
      v_eigen_array = 
        sm_sc.fv_mx_ele_2d_2_1d
        (
          |^~|
          (
            sm_sc.fv_mx_rows_step_simple
            (
              v_determinant_mx |||| array_fill(1.0 :: float, array[v_len])  -- 方程右侧全是等值，得出的求解和基础解系同比例，为啥呢？
            )
          )[:][v_len + 1 : v_len + 1]
        )
      ;

      insert into sm_sc.__vt_tmp_eigen_arrays(sess_id, eigen_value, eigen_array)
      select 
        v_sess_id,
        v_eigen_values_distinct[v_loop_cur],
        v_eigen_array /` sm_sc.fv_arr_norm_2(v_eigen_array)
       ;

    else
      -- 欠秩，且假设可对角化
      -- 构造基础解系方程组
      with 
      cte_basic_solute 
      (
        eigen_array_grp    ,
        pos                ,
        array_meta_val
      )
      as
      (
        select 
          -- -- -- -- 相关x的序号清单
          -- -- -- ,
          -- 用相关列做自由变量，求取基础解系中无关x的值
          related_x_cur, array_meta_related.*
        from 
          generate_series(1, v_related_xs_len) related_x_cur,
          unnest
          (
            v_unrelated_xs,
            ( -- 相关列移动到方程等号右边，变号
              -` 
              sm_sc.fv_mx_ele_2d_2_1d 
              ( -- 找到所有相关x列
                |^~| v_determinant_mx_sim[1 : v_len - v_related_xs_len][v_related_xs[related_x_cur] : v_related_xs[related_x_cur]]
              )
            )
          ) array_meta_related
        union all
        -- 自然基底1作为相关x值，然后和无关x值按照x_no顺序合并
        select 
          -- 当次cur的自然基底向量
          related_x_cur as eigen_array_grp
          , v_unrelated_xs[related_x_cur] as pos
          , array_meta_unrelated as array_meta_val
        from generate_series(1, v_related_xs_len) related_x_cur
          , unnest(sm_sc.fv_mx_ele_2d_2_1d((sm_sc.fv_eye_unit(v_related_xs_len, 1.0 :: float))[related_x_cur:related_x_cur][:])) as array_meta_unrelated
      )
      insert into sm_sc.__vt_tmp_eigen_arrays(sess_id, eigen_value, eigen_array)
      select 
        v_sess_id,
        eigen_value, 
        eigen_array_x /` sm_sc.fv_arr_norm_2(eigen_array_x)  as eigen_array   -- 除以L2范数正交化
      from 
      (
        select 
          v_eigen_values_distinct[v_loop_cur]     as eigen_value   ,
          array_agg(array_meta_val order by pos)      as eigen_array_x
        from cte_basic_solute
        group by eigen_array_grp
      )  t_tmp
      ;

    end if;
    

    v_loop_cur = v_loop_cur + 1;
  end loop;

  return query
    select 
      eigen_value    as o_eigen_value    ,
      eigen_array    as o_eigen_array
    from sm_sc.__vt_tmp_eigen_arrays
    where sess_id = v_sess_id
  ;

  delete from sm_sc.__vt_tmp_eigen_arrays where sess_id = v_sess_id;
end
$$
  language plpgsql volatile
  parallel unsafe
  cost 100;

-- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[1,2],[3,4]])
-- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[1,2,3],[0,8,9],[4,5,6]])
-- -- https://jingyan.baidu.com/article/27fa7326afb4c146f8271ff3.html
-- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[-1,1,0],[-4,3,0],[1,0,2]])  -- 特征值相同例子，无法对角化
-- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[-2,1,1],[0,2,0],[-4,1,3]])  -- 特征值相同例子，可对角化
-- -- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[1,2,3,4],[0,8,9,10],[4,5,6,7],[5,7,2,10]])  -- 本算法不支持求解复数特征值
-- -- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[0,1,2],[1,1,4],[2,-1,0]])  -- 本算法不支持求解复数特征值
-- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[
--   [1.0000,2.0000,3.0000,4.0000,5.0000,6.0000,7.0000],  
--   [2.0000,3.0000,4.0000,5.0000,6.0000,7.0000,8.0000],  
--   [3.0000,4.0000,5.0000,6.0000,7.0000,8.0000,9.0000],  
--   [4.0000,5.0000,6.0000,7.0000,8.0000,9.0000,10.000],   
--   [5.0000,6.0000,7.0000,8.0000,9.0000,10.000,11.000],   
--   [6.0000,7.0000,8.0000,9.0000,10.000,11.000,12.000],   
--   [7.0000,8.0000,9.0000,10.000,11.000,12.000,13.000]
--   ])


-- select o_eigen_value, o_eigen_array from sm_sc.ft_mx_evd(array[[2,3],[1,7]])
-- truncate table t_tmp_debug_info
-- select * from t_tmp_debug_info



