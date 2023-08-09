-- drop function if exists sm_sc.fv_eye(anyelement, variadic anyarray);
create or replace function sm_sc.fv_eye
(
           i_fill_idle_value           anyelement, 
  variadic i_identity_values           anyarray
)
  returns anyarray
as
$$
-- declare here

begin
  return     
    (
      select 
        array_agg
        (
          array_x
          order by v_cur_y
        )
      from 
      (
        select v_cur_y,
          array_agg(case when v_cur_x = v_cur_y then i_identity_values[v_cur_y] else i_fill_idle_value end order by v_cur_x) as array_x
        from 
          generate_series(1,array_length(i_identity_values, 1)) as v_cur_x
        , generate_series(1,array_length(i_identity_values, 1)) as v_cur_y
        group by v_cur_y
      ) t_a_array_x
    )	
    ;
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_eye(1.2, 2.3, 5.6, 52.1)
-- select sm_sc.fv_eye(0.0 :: float, variadic array[1.2, 2.3, 5.6, 52.1])
