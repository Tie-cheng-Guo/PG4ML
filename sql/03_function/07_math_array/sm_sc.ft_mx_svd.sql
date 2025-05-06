-- drop function if exists sm_sc.ft_mx_svd(float[][]);
create or replace function sm_sc.ft_mx_svd
(
  in i_matrix float[][]
)
  returns table
  (
    o_singular_values     float[]           ,
    o_singular_matrix_u    float[][]         ,
    o_singular_matrix_v    float[][]
  )
as
$$
-- declare here
declare 
  v_len_u int := array_length(i_matrix, 1);
  v_len_v int := array_length(i_matrix, 2);

begin

  return query
    with 
    cte_singular_u as
    (
      select
        array_agg(sqrt(o_eigen_value) order by o_eigen_value desc) as o_eigen_values_sqrt,
        array_agg(o_eigen_array order by o_eigen_value desc) as o_eigen_arrays
      from sm_sc.ft_mx_evd(i_matrix |**| (|^~| i_matrix))
    ),
    cte_singular_v as
    (
      select
        -- array_agg(o_eigen_value order by o_eigen_value desc) as o_eigen_values,
        array_agg(o_eigen_array order by o_eigen_value desc) as o_eigen_arrays
      from sm_sc.ft_mx_evd((|^~| i_matrix) |**| i_matrix)
    )
    select 
      t_u.o_eigen_values_sqrt[ 1 : least(v_len_u, v_len_v) ]    as o_singular_values      ,
      |^~| t_u.o_eigen_arrays              as o_singular_matrix_u    ,
      |^~| t_v.o_eigen_arrays              as o_singular_matrix_v
    from cte_singular_u t_u
      , cte_singular_v t_v
  ;

end
$$
  language plpgsql volatile
  cost 100;

-- select o_singular_values, o_singular_matrix_u, o_singular_matrix_v from sm_sc.ft_mx_svd(array[
--     [1,1,1],
--     [1,2,3],
--     [1,10,100],
--     [1,0,0]
--   ])



