-- drop function if exists sm_sc.fv_aggr_slice_is_exists_null(anyarray);
create or replace function sm_sc.fv_aggr_slice_is_exists_null
(
  i_array anyarray,
  i_ele   anyelement   default  null
)
returns boolean
as
$$
declare
  v_len_y    int       :=   array_length(i_array, 1);
  v_len_x    int       :=   array_length(i_array, 2);
  v_ret      boolean   :=   false;
begin
  if i_array is null
  then
    raise exception 'i_array is null';
  else
    foreach i_ele in array i_array
    loop 
      if i_ele is null 
      then 
        v_ret = true;
        exit;
      end if;
    end loop;
  end if;
  return v_ret;
end
$$
language plpgsql volatile
parallel safe
cost 100;


-- select sm_sc.fv_aggr_slice_is_exists_null(array[4, 6, 9, null])
-- select sm_sc.fv_aggr_slice_is_exists_null(array[[4, 6, 9, null], [5, 7, 3, 3]])