-- -- 参考 https://baike.baidu.com/item/%E9%9B%85%E5%8F%AF%E6%AF%94%E7%9F%A9%E9%98%B5/10753754
-- drop function if exists sm_sc.fv_gradient_jacobi(varchar(64)[], text[]);
create or replace function sm_sc.fv_gradient_jacobi
(
  i_indepdt_var_names               varchar(64)[],
  i_depdt_var_opr_charts            text[]
)
returns text[]
as
$$
begin
  return 
  (
    with
    cte_arr_indepdt as
    (
      select 
        a_idx_depdt,
        array_agg(sm_sc.fv_gradient(i_indepdt_var_names[a_idx_indepdt], i_depdt_var_opr_charts[a_idx_depdt]) order by a_idx_indepdt) as a_arr_indepdt
      from generate_series(1, array_length(i_depdt_var_opr_charts, 1)) tb_a_idx_depdt(a_idx_depdt)
        , generate_series(1, array_length(i_indepdt_var_names, 1)) tb_a_idx_indepdt(a_idx_indepdt)
      group by a_idx_depdt
    )
    select  
      array_agg(a_arr_indepdt order by a_idx_depdt)
    from cte_arr_indepdt
  );
end
$$
language plpgsql volatile
cost 100;

-- select sm_sc.fv_gradient_jacobi(array['v_x1_in'], array['w1 * v_x1_in + w2 * v_x2 + w3 * v_x3'])
-- select sm_sc.fv_gradient_jacobi(array['r', 'a', 'b'], array['r*cos(a)*sin(b)', 'r*sin(a)*sin(b)', 'r*cos(b)'])