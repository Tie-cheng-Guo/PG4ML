-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_new_rand_enum(anyarray, int[2]);
create or replace function sm_sc.fv_new_rand_enum
(
  i_dispersed_array   anyarray    ,
  i_yx_len            int[]
)
returns anyarray
as
$$
declare -- here
  v_enum_dic    name[]  :=  
  (
    select 
      array_agg(distinct enumlabel)
    from unnest(i_dispersed_array) tb_a_enum(enumlabel)
  );
  v_dic_len     int      :=  array_length(v_enum_dic, 1);

begin
  -- set search_path to sm_sc;
  if 1 > any(i_yx_len) or array_ndims(i_yx_len) > 1
  then
    raise exception 'unmatched length!';
  end if;

  if array_length(i_yx_len, 1) = 1
  then
    return 
    (
      select 
        array_agg(v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int])
      from generate_series(1, i_yx_len[1])
    );
  elsif array_length(i_yx_len, 1) = 2
  then
    return 
    (
      with 
      cte_y_slice as
      (
        select 
          a_y,
          array_agg(v_enum_dic[round(random() * v_dic_len + 0.5 :: float) :: int]) as a_slice_y
        from generate_series(1, i_yx_len[1]) tb_a_y(a_y)
          , generate_series(1, i_yx_len[2]) tb_a_x(a_x)
        group by a_y
      )
      select array_agg(a_slice_y) from cte_y_slice
    );
  else
    raise exception 'unsupport ndims!';
  end if;
end
$$
language plpgsql volatile
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_new_rand_enum
--   (
--     array['abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'efg', 'fgh', 'cde', 'cde', 'cde'],
--     array[5, 6]
--   );
-- select sm_sc.fv_new_rand_enum
--   (
--     array['abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'efg', 'fgh', 'cde', 'cde', 'cde'],
--     array[5]
--   );