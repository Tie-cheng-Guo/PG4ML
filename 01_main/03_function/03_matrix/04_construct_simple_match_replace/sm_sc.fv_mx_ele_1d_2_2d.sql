-- drop function if exists sm_sc.fv_mx_ele_1d_2_2d(anyarray, int);
create or replace function sm_sc.fv_mx_ele_1d_2_2d
(
  i_ele_1d           anyarray     ,
  i_cnt_per_grp      int  -- 对于单行多列，将向下堆砌多行；对于多行单列，将向右堆砌多列
)
returns anyarray
as
$$
-- declare

begin
  if i_cnt_per_grp > 1
    and coalesce(nullif(array_length(i_ele_1d, 1), 1), array_length(i_ele_1d, 2)) % i_cnt_per_grp > 0
  then 
    raise exception 'unsupported count of groups. len_ele_1d_y: %; len_ele_1d_x: %; cnt_per_grp: %; i_ele_1d: %;', array_length(i_ele_1d, 1), array_length(i_ele_1d, 2), i_cnt_per_grp, i_ele_1d;
  elsif array_ndims(i_ele_1d) = 1
  then 
    return 
    (
      select 
        array_agg(i_ele_1d[a_grp_no * i_cnt_per_grp + 1 : (a_grp_no + 1) * i_cnt_per_grp])
      from generate_series(0, (array_length(i_ele_1d, 1) - 1) / i_cnt_per_grp) tb_a_grp(a_grp_no)
    );
  elsif array_ndims(i_ele_1d) = 2 and array_length(i_ele_1d, 1) = 1
  then 
    return 
    (
      select 
        sm_sc.fa_mx_concat_y(i_ele_1d[1 : 1][a_grp_no * i_cnt_per_grp + 1 : (a_grp_no + 1) * i_cnt_per_grp])
      from generate_series(0, (array_length(i_ele_1d, 2) - 1) / i_cnt_per_grp) tb_a_grp(a_grp_no)
    )
    ;
  elsif array_ndims(i_ele_1d) = 2 and array_length(i_ele_1d, 2) = 1
  then 
    return
    (
      select 
        sm_sc.fa_mx_concat_x(i_ele_1d[a_grp_no * i_cnt_per_grp + 1 : (a_grp_no + 1) * i_cnt_per_grp][1 : 1])
      from generate_series(0, (array_length(i_ele_1d, 1) - 2) / i_cnt_per_grp) tb_a_grp(a_grp_no)
    )    
    ;
  else 
    return null;
    -- raise exception 'unsupported ndims or length.';
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_mx_ele_1d_2_2d
--   (
--     array[1, 2, 3, 4, 5, 6, 7, 8, 9]
--     , 3
--   );
-- select sm_sc.fv_mx_ele_1d_2_2d
--   (
--     array[array[1, 2, 3, 4, 5, 6, 7, 8, 9]]
--     , 3
--   );
-- select sm_sc.fv_mx_ele_1d_2_2d
--   (
--     array[array[1], array[2], array[3], array[4], array[5], array[6]]
--     , 3
--   );
-- select sm_sc.fv_mx_ele_1d_2_2d
--   (
--     array[array[1], array[2], array[3], array[4], array[5]]
--     , 2
--   );