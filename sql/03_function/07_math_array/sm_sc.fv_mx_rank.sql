-- drop function if exists sm_sc.fv_mx_rank(float[][]);
create or replace function sm_sc.fv_mx_rank
(
  in i_matrix float[][]
)
  returns int
as
$$
-- declare here
declare v_cur_loop_1       int         :=   1;
declare v_cur_loop_2       int;
declare v_y_len            int         :=   array_length(i_matrix, 1);
declare v_x_len            int         :=   array_length(i_matrix, 2);
declare v_row_no           int;
declare v_compare_val      float;
declare v_cur_part_array   float[];
declare v_sess_id   bigint        :=       lower(sm_sc.fv_get_global_seq());  -- char(32)     :=   replace(gen_random_uuid()::text, '-', '')::char(32);

begin
  -- -- -- pg的多维数组服务操纵切片，转化为一维数组表
  -- -- drop table if exists sm_sc.__vt_tmp_matrix;
  -- -- create temp table sm_sc.__vt_tmp_matrix
  -- -- (
  -- --   sess_id                char(32)        ,  
  -- --   -- org_row_no       int            ,    -- 原行号
  -- --   new_row_no       int            ,    -- 新行号
  -- --   array_x          float[]      -- ,    -- 行向量
  -- --   -- transform_desc   text           ,    -- 初等变换轨迹描述
  -- --   -- primary key(sess_id, org_row_no)
  -- -- ) with (parallel_workers = 4);
  -- -- 
  -- -- create index idx_tmp_matrix on sm_sc.__vt_tmp_matrix (sess_id, new_row_no);

  insert into sm_sc.__vt_tmp_matrix
  (
    sess_id,
    -- org_row_no  ,
    new_row_no  ,
    array_x
  )
  select 
    v_sess_id,
    -- v_cur_loop_1_y,
    v_cur_loop_1_y,
    array_agg(i_matrix[v_cur_loop_1_y][v_cur_loop_1_x] order by v_cur_loop_1_x)
  from generate_series(1, v_y_len) v_cur_loop_1_y
    , generate_series(1, v_x_len) v_cur_loop_1_x
  group by v_cur_loop_1_y
  ;

  -- 沿主对角线，逐行化简为上梯形
  while v_cur_loop_1 < v_y_len
  loop 
    -- 判断后续行，该列元是否都为0。存在非零则进入该行该列元判断；不存在非零则跳过该列；
    if exists (select  from sm_sc.__vt_tmp_matrix where new_row_no > v_cur_loop_1 and array_x[v_cur_loop_1] <> 0.0 and sess_id = v_sess_id)
    then 
      -- 如果当前行当前列元为零，则需换行
      if exists (select  from sm_sc.__vt_tmp_matrix where new_row_no = v_cur_loop_1 and array_x[v_cur_loop_1] = 0.0 and sess_id = v_sess_id)
      then
        v_row_no = (select new_row_no from sm_sc.__vt_tmp_matrix where new_row_no > v_cur_loop_1 and array_x[v_cur_loop_1] <> 0.0 and sess_id = v_sess_id limit 1);

        update sm_sc.__vt_tmp_matrix
        set new_row_no = case new_row_no 
                           when v_row_no then v_cur_loop_1 
                           else v_row_no
                         end
        where new_row_no in (v_row_no, v_cur_loop_1)
          and sess_id = v_sess_id
		;

        -- -- 换行变号
        -- update sm_sc.__vt_tmp_matrix
        -- set array_x[v_cur_loop_1 : ] = -` array_x[v_cur_loop_1 : ]
        -- where new_row_no = v_cur_loop_1
        --   and sess_id = v_sess_id
        -- ;
      end if;

      -- 由方阵左上角，后续行逐行消元，成为0左下三角
      v_compare_val = (select array_x[v_cur_loop_1] from sm_sc.__vt_tmp_matrix where new_row_no = v_cur_loop_1 and sess_id = v_sess_id);
      v_cur_part_array = (select array_x[v_cur_loop_1 + 1 : ] from sm_sc.__vt_tmp_matrix where new_row_no = v_cur_loop_1 and sess_id = v_sess_id);
      update sm_sc.__vt_tmp_matrix
      set array_x[v_cur_loop_1 : ] 
            = array[0.0 :: float] ||
              (
                array_x[v_cur_loop_1 + 1 : ]
                -` 
                (
                  (array_x[v_cur_loop_1] / v_compare_val)
                  *` v_cur_part_array
                )
              )
      where new_row_no > v_cur_loop_1 
        and array_x[v_cur_loop_1] <> 0.0
        and sess_id = v_sess_id
      ;

    end if;

    v_cur_loop_1 = v_cur_loop_1 + 1;
  end loop;

  return
  (
    select 
      count(*)
    from generate_series(1, greatest(v_y_len, v_x_len)) diagonal_cur
    inner join sm_sc.__vt_tmp_matrix mx
    on mx.new_row_no = diagonal_cur
    where mx.array_x[diagonal_cur] <> 0
      and mx.sess_id = v_sess_id
  )
  ;

  delete from sm_sc.__vt_tmp_matrix where sess_id = v_sess_id;
end
$$
  language plpgsql volatile
  parallel unsafe
  cost 100;

-- select sm_sc.fv_mx_rank(array[[1,2],[3,4]])
-- select sm_sc.fv_mx_rank(array[[1,2,3],[0,8,9],[4,5,6]])