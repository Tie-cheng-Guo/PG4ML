-- drop function if exists sm_sc.fv_eye(anyelement, int, variadic anyarray);
create or replace function sm_sc.fv_eye
(
           i_fill_idle_value           anyelement, 
           i_dim                       int       ,
  variadic i_identity_values           anyarray
)
  returns anyarray
as
$$
declare -- here
  v_len    int                         :=    array_length(i_identity_values, 1);
  v_ret    i_identity_values%type      ;
  v_cur    int;
begin
  if i_dim not between 2 and 4
  then 
    raise exception 'unsupport dim > 4';
  end if;
  
  v_ret :=    array_fill(i_fill_idle_value, array_fill(v_len, array[i_dim]));
  
  if i_dim = 2
  then
    for v_cur in 1 .. v_len
    loop 
      v_ret[v_cur][v_cur] := i_identity_values[v_cur];
    end loop;
  elsif i_dim = 3
  then
    for v_cur in 1 .. v_len
    loop 
      v_ret[v_cur][v_cur][v_cur] := i_identity_values[v_cur];
    end loop;
  elsif i_dim = 4
  then
    for v_cur in 1 .. v_len
    loop 
      v_ret[v_cur][v_cur][v_cur][v_cur] := i_identity_values[v_cur];
    end loop;
  end if;
  
  return v_ret;
end
$$
  language plpgsql stable
parallel safe
  cost 100;

-- select sm_sc.fv_eye(0.2 :: float, 3, variadic array[1,2,3,4,5] :: float[])
-- select sm_sc.fv_eye(0.0 :: float, 4, variadic array[1.2, 2.3, 5.6, 52.1] :: float[])
