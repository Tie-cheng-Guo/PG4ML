-- drop function if exists sm_sc.ft_bpe(text[], int, int, int, int, intboolean);
create or replace function sm_sc.ft_bpe
(
  i_seq_code                             text[]                  -- 原始输入序列数组
, i_threshold_loop_cnt                   int                     -- 约束：迭代合并 token 的次数做为循环结束的阈值
, i_threshold_token_list_cnt             int       default 0     -- 约束：token list 的字典规模做为循环结束的阈值，缺省 0 代表不约束循环结束阈值
, i_threshold_seq_token_len              int       default 0     -- 期望：编码后，每个 seq 包含 token 数量的最大值做为循环结束的阈值，缺省 0 代表不约束循环结束阈值
, i_threshold_avg_token_len_4_seq        int       default 0     -- 初步评估：对于某一个 seq 来说，当包含的 token 数已经小于 i_threshold_seq_token_len，那么判断：其包含的 token 的平均长度超过该阈值，则不再参与 bpe。缺省 0 代表不做此判断
, i_is_match_begin_end                   boolean   default false -- 是否区分匹配 seq 的起始和终止。如果区分，则要对 seq 中的两个逃逸字符 '^$' 做特殊处理
)
returns table 
(
  o_ret_seq_code              text[]                  -- 输出序列数组。元素顺序与原始输入一一对应
, o_ret_token_list            text[]                  -- token 清单，字典表
)
as
$$
declare 
  v_sess_id                   bigint        :=  lower(sm_sc.fv_get_global_seq());
  v_token_ex                  text          ;    -- 每次循环寄存被发现的频率最高的 2gram，带有一个空格
  v_token_ex_freq             int           ;    -- 每次循环寄存被发现的频率最高的 2gram 的频率次数(该频次仅用于单次审查，可能不包含已经满足阈值的成熟 seq 的 token 片段)
  v_seq_code_no_arr           int[]         ;    -- 每次循环寄存被 token 合并更新的 seq_no 清单
  v_ret_seq_token             text[]        ;    -- 返回结构一
  v_ret_token_list            text[]        ;    -- 返回结构二
  
  v_token_merge_cnt_cur       int           := 1;
  -- v_token_ex_freq_ex          int           ;    -- 被发现的频率最高的 2gram 的频率次数(实际次数，包含包含已经满足阈值的成熟 seq 的 token 片段)
begin 
  -- 审计三个逃逸字符"^ $"(起始、空格、结尾)
  if (|@|`| (i_seq_code ~` case when i_is_match_begin_end then '[\^ \$]' :: text else ' ' end))
  then 
    raise exception 'can''t support these 3 char "^ $" in sequence_code.  ';
  end if;

  -- 原始 seq 导入 buff 表
  insert into sm_sc.__vt_tmp_bpe_seq(sess_id, seq_code, seq_code_no)
  select 
    v_sess_id
  , case 
      when i_is_match_begin_end 
        then '^' || i_seq_code[a_cur] || '$' 
      else i_seq_code[a_cur] 
    end
  , a_cur
  from generate_series(1, array_length(i_seq_code, 1)) tb_a_cur(a_cur)
  ;
  
  -- 初始化其他信息：空格为间隔符，切分 seq；初始化序列被分成 token 的数量
  update sm_sc.__vt_tmp_bpe_seq
  set 
    seq_token     = rtrim(regexp_replace(seq_code, '(.)', '\1 ', 'g'))
  , seq_split_cnt = length(seq_code)
  ;
  
  -- 初始化 token list
  insert into sm_sc.__vt_tmp_bpe_token_list(sess_id, token, token_freq)
  select 
    v_sess_id
  , a_token
  , count(a_token) -- as token_freq
  from sm_sc.__vt_tmp_bpe_seq, regexp_split_to_table(seq_token, ' ') tb_a(a_token)
  group by a_token
  ;
  
  -- 初始化 2gram
  update sm_sc.__vt_tmp_bpe_seq
  set 
    seq_token_2gram = 
      (
        select 
          array_agg(a_split_arr_token[a_cur] || ' ' || a_split_arr_token[a_cur + 1] order by a_cur)
        from regexp_split_to_array(seq_token, ' ') as a_split_arr_token
          , generate_series(1, array_length(a_split_arr_token, 1) - 1) tb_a_cur(a_cur)
      )
  where sess_id = v_sess_id
  ;
  
  -- 开始迭代更新
  --   每次都全量统计，不是很优雅的实现，
  --   如果增量统计实现，过滤代价也不小。
  --   如果 seq 和 token 规模特别大，也可以考虑分组 bpe 和 token 采样计算出现频率等策略
  while 
    exists
    (
      select  from sm_sc.__vt_tmp_bpe_seq
      where sess_id = v_sess_id 
        and seq_split_cnt > greatest(2, i_threshold_seq_token_len)
    )
    and (v_token_merge_cnt_cur <= i_threshold_loop_cnt or i_threshold_loop_cnt = 0)
    and 
      (
        (select count(token) from sm_sc.__vt_tmp_bpe_token_list where token_freq > 0) < i_threshold_token_list_cnt 
        or i_threshold_token_list_cnt = 0
      )
  loop         
    -- 找到频率最高，长度较长的 2gram 加入 token 清单
    with
    -- -- cte_filter_seq as 
    -- -- (
    -- --   select 
    -- --     seq_token_2gram
    -- --   from sm_sc.__vt_tmp_bpe_seq
    -- --   where sess_id = v_sess_id
    -- --     and seq_token_2gram is not null
    -- --     and 
    -- --       (
    -- --         i_threshold_seq_token_len = 0 
    -- --         or i_threshold_avg_token_len_4_seq = 0
    -- --         -- 参与 bpe 的条件：要么包含 token 还有很多；要么这个 seq 里，各个 token 的包含的原始子 token 平均还很少
    -- --         or seq_split_cnt > i_threshold_seq_token_len    
    -- --         or length(seq_code) / (greatest(seq_split_cnt, 2) - 1) <= i_threshold_avg_token_len_4_seq   -- 减一：还能经得起一次合并，仍然在阈值范围内
    -- --       )
    -- -- ), 
    -- -- cte_low_aggr_2gram as 
    -- -- (
    -- --   select 
    -- --     a_token_ex
    -- --   , count(a_token_ex) as a_token_ex_freq
    -- --   from cte_filter_seq, unnest(seq_token_2gram) tb_a(a_token_ex)
    -- --   group by a_token_ex
    -- -- )
    cte_low_aggr_2gram as 
    (
      select 
        a_token_ex
      , count(a_token_ex) as a_token_ex_freq
      , max(seq_split_cnt) as a_max_seq_split_cnt
      , min(least(seq_token_2gram[1], seq_token_2gram[2])) as a_min_sub_token_len
      from sm_sc.__vt_tmp_bpe_seq, unnest(seq_token_2gram) tb_a(a_token_ex)
      where sess_id = v_sess_id
        and seq_token_2gram is not null
        and 
          (
            i_threshold_seq_token_len = 0 
            or i_threshold_avg_token_len_4_seq = 0
            -- 参与 bpe 的条件：要么包含 token 还有很多；要么这个 seq 里，各个 token 的包含的原始子 token 平均还很少
            or seq_split_cnt > i_threshold_seq_token_len    
            or length(seq_code) / (greatest(seq_split_cnt, 2) - 1) <= i_threshold_avg_token_len_4_seq   -- 减一：还能经得起一次合并，仍然在阈值范围内
          )
      group by a_token_ex
    )
    select 
      a_token_ex          
    , a_token_ex_freq   
    into 
      v_token_ex
    , v_token_ex_freq
    from cte_low_aggr_2gram
    order by     -- tf-idf 为大原则，尽量满足阈值为策略
      a_token_ex_freq desc
    , greatest(a_max_seq_split_cnt, i_threshold_seq_token_len) desc
    , length(a_token_ex) desc
    , a_min_sub_token_len desc
    limit 1
    ;

    -- v_token_ex_freq_ex := -- v_token_ex_freq
    --   (
    --     select 
    --       count(a_token)
    --     from sm_sc.__vt_tmp_bpe_seq tb_a_seq, unnest(tb_a_seq.seq_token_2gram) tb_a_token(a_token)
    --     where v_token_ex = any(tb_a_seq.seq_token_2gram)  -- 可以 gin + tsvector 优化
    --       and a_token = v_token_ex
    --   )
    -- ;

-- -- -- debug
-- -- raise notice 'v_token_merge_cnt_cur: %; v_token_ex: %; v_token_ex_freq: %;', v_token_merge_cnt_cur, v_token_ex, v_token_ex_freq;   -- v_token_ex_freq_ex

    exit when v_token_ex is null;
    
    insert into sm_sc.__vt_tmp_bpe_token_list as tb_a_tar
    (
      sess_id
    , token
    , token_freq
    )
    values 
    (
      v_sess_id
    , replace(v_token_ex, ' ', '')
    , v_token_ex_freq        -- v_token_ex_freq_ex
    )
    on conflict(sess_id, token) do update set
      token_freq = tb_a_tar.token_freq + excluded.token_freq
    ;
    
    -- 被并入新 token 的 sub-token 的次数要从 sub-token 总次数中减计
    update sm_sc.__vt_tmp_bpe_token_list
    -- 如果只“更新满足阈值的记录”，那么 - v_token_ex_freq，否则 - v_token_ex_freq_ex
    set token_freq = token_freq - v_token_ex_freq          -- token_freq - v_token_ex_freq_ex
    where token in (split_part(v_token_ex, ' ', 1), split_part(v_token_ex, ' ', 2))
      and sess_id = v_sess_id
    ;
    
    -- 更新含有新 token 的 seq_token
    with
    cte_upd_seq_token as 
    (
      update sm_sc.__vt_tmp_bpe_seq
      set 
        seq_token = 
          regexp_replace
          (
            seq_token
          , ('(?<=^| )' || regexp_replace(v_token_ex, '([\^\$])', '\\\1', 'g') || '(?= |$)')
          , replace(v_token_ex, ' ', '')
          , 'g'
          )                                                                                                 -- replace(seq_token, v_token_ex, replace(v_token_ex, ' ', ''))
      where sess_id = v_sess_id
        and v_token_ex = any(seq_token_2gram)   -- and seq_token ~ ('(?<=^| )' || regexp_replace(v_token_ex, '([\^\$])', '\\\1', 'g') || '(?= |$)')    -- seq_token like ('%' || v_token_ex || '%')
        -- 下面过滤条件注释掉，表示不只是“更新满足阈值的记录”
        -- and 
        --   (
        --     i_threshold_seq_token_len = 0 
        --     or i_threshold_avg_token_len_4_seq = 0
        --     -- 参与 bpe 的条件：要么包含 token 还有很多；要么这个 seq 里，各个 token 的包含的原始子 token 平均还很少
        --     or seq_split_cnt > i_threshold_seq_token_len    
        --     or length(seq_code) / (greatest(seq_split_cnt, 2) - 1) <= i_threshold_avg_token_len_4_seq   -- 减一：还能经得起一次合并，仍然在阈值范围内
        --   )
      returning seq_code_no
    )
    select 
      array_agg(seq_code_no) into v_seq_code_no_arr
    from cte_upd_seq_token
    ;
    
    -- 再更新序列被分成 token 的数量，用于判断循环终止
    update sm_sc.__vt_tmp_bpe_seq tb_a_tar
    set 
      seq_split_cnt = length(seq_token) - length(replace(seq_token, ' ', '')) + 1
    , seq_token_2gram = 
        (
          select 
            array_agg(a_split_arr_token[a_cur] || ' ' || a_split_arr_token[a_cur + 1] order by a_cur)
          from regexp_split_to_array(seq_token, ' ') as a_split_arr_token
            , generate_series(1, array_length(a_split_arr_token, 1) - 1) tb_a_cur(a_cur)
        )
    from unnest(v_seq_code_no_arr) tb_a_sour(seq_code_no)
    where tb_a_tar.sess_id = v_sess_id
      and tb_a_tar.seq_code_no = tb_a_sour.seq_code_no
    ;
    
    -- 循环次数计数，用于判断循环终止
    v_token_merge_cnt_cur := v_token_merge_cnt_cur + 1;
  end loop;
  
  -- 收尾返回
  v_ret_seq_token := 
    (
      select 
        array_agg(seq_token order by seq_code_no) 
      from sm_sc.__vt_tmp_bpe_seq 
      where sess_id = v_sess_id 
    )
  ;
  v_ret_token_list := 
    (
      select 
        array_agg(token) 
      from sm_sc.__vt_tmp_bpe_token_list 
      where sess_id = v_sess_id 
        and token_freq > 0
        and token not in ('^', '$')
    )
  ;
  delete from sm_sc.__vt_tmp_bpe_seq where sess_id = v_sess_id;
  delete from sm_sc.__vt_tmp_bpe_token_list where sess_id = v_sess_id;
  
  return query
    select v_ret_seq_token, v_ret_token_list
  ;
end 
$$
language plpgsql volatile 
parallel unsafe
;

-- with 
-- cte_seq_code as
-- (
--   select 
--     cn_chr
--   , row_number(order by cn_chr) over() as a_no
--   , cn_write_ord_no 
--   from sm_sc.tb_lang_cn_chr_dic 
--   where cn_write_ord_no is not null
--   -- order by cn_chr 
--   -- limit 100
-- ),
-- cte_bpe_arr as 
-- (
--   select 
--     o_ret_seq_code  
--   , o_ret_token_list
--   from 
--     sm_sc.ft_bpe
--     (
--       (
--         select array_agg(cn_write_ord_no) 
--         from cte_seq_code
--       )
--     , 5000   -- 循环次数
--     , 2048   -- 字典规模                                                           -- 字典里多少类偏旁
--     , 4      -- bpe 后，seq 长度，包含 token 个数                                  -- 一个汉字(seq)包含多少个偏旁结构
--     , 3      -- bpe 后，一个 seq 中，各个 token 包含原始 sub-token 的个数均值      -- 偏旁笔划数
--     )
-- )
-- select 
--   cn_chr
-- , o_ret_seq_code[a_no]
-- from cte_bpe_arr, cte_seq_code


-- -- -- delete from sm_sc.__vt_tmp_bpe_seq;
-- -- -- delete from sm_sc.__vt_tmp_bpe_token_list;
-- -- 
-- -- select seq_split_cnt, count(seq_split_cnt)
-- --   -- * 
-- -- from sm_sc.__vt_tmp_bpe_seq 
-- -- 
-- -- group by seq_split_cnt
-- -- limit 50
-- -- 
-- -- select * from sm_sc.__vt_tmp_bpe_token_list 
-- -- -- where token_freq > 0
-- -- limit 50

-- create table __vt_tmp_bpe_seq_1101 as select * from sm_sc.__vt_tmp_bpe_seq;
-- create table __vt_tmp_bpe_token_list_1101 as select * from sm_sc.__vt_tmp_bpe_token_list;