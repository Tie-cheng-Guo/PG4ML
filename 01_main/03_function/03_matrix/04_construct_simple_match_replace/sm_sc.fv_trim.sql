-- drop function if exists sm_sc.fv_trim(anyarray, anyelement);
create or replace function sm_sc.fv_trim
(
  i_array               anyarray,
  i_trim_element        anyelement
)
returns anyarray
as
$$
declare -- here
  v_y_cur                 int  ;
  v_x_cur                 int  ;
begin
  -- log(null :: float[][], float) = null :: float[][]
  if array_length(i_array, array_ndims(i_array)) is null
  then 
    return i_array;
  end if;

  -- ([][])
  if array_ndims(i_array) =  2
  then
    return sm_sc.fv_ltrim(sm_sc.fv_rtrim(sm_sc.fv_atrim(sm_sc.fv_btrim(i_array, i_trim_element), i_trim_element), i_trim_element), i_trim_element);

  -- []
  elsif array_ndims(i_array) = 1
  then
    return sm_sc.fv_ltrim(sm_sc.fv_rtrim(i_array, i_trim_element), i_trim_element);

  else
    return null; raise notice 'no method for such length!  Ndim: %; len_1: %; len_2: %;', array_ndims(i_array), array_length(i_array, 1), array_length(i_array, 2);
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- select sm_sc.fv_trim(array[[2,0,0,0,0,0], [1,2,0,4,0,0], [0,0,1,0,2,0], [0,1,2,0,0,0], [1,0,1,0,0,3]], 0)
-- select sm_sc.fv_trim(array[0,1,2,3,4,5, 0, 0], 0)