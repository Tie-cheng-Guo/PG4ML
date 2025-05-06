-- drop function if exists sm_sc.ufv_prod_mx_based_org_chunk(float[], float[], int, float[]);
create or replace function sm_sc.ufv_prod_mx_based_org_chunk
(
  i_left                            float[]
, i_right                           float[]
, i_l_w_r_h_chunk_pos               int
, i_chunk_above_left_above_left     float[]  default null
)
returns float[]
as
$$
declare
  v_h   int   :=  array_length(i_chunk_above_left_above_left, 1);
  v_w   int   :=  array_length(i_chunk_above_left_above_left, 2);
begin
  if i_chunk_above_left_above_left is null
  then
    return
      i_left |**| i_right
    ;
  else
    return 
      (
        (
          i_chunk_above_left_above_left 
          +` 
          (i_left[:v_h][i_l_w_r_h_chunk_pos+1:] |**| i_right[i_l_w_r_h_chunk_pos+1:][:v_w])
        )                                                -- a. * .l = al    -- (i_left[:v_h][:] |**| i_right[:][:v_w])
        ||||                                                                                
        (i_left[:v_h][:] |**| i_right[:][v_w+1:])        -- a. * .r = ar
      )
      |-||
      (
        (i_left[v_h+1:][:] |**| i_right[:][:v_w])        -- b. * .l = bl
        ||||
        (i_left[v_h+1:][:] |**| i_right[:][v_w+1:])      -- b. * .r = br
      )
    ;
  end if;
end
$$
language plpgsql stable
parallel safe
;
-- with 
-- cte_input as 
-- (
--   select 
--     sm_sc.fv_new_randn(0.0, 1.1, array[5,8]) as a_left
--   , sm_sc.fv_new_randn(0.0, 1.1, array[8,7]) as a_right
--   , 6 as a_l_w_r_h_chunk_pos
-- )
-- select 
--   (
--     sm_sc.ufv_prod_mx_based_org_chunk
--     (
--       a_left
--     , a_right
--     , a_l_w_r_h_chunk_pos
--     ) :: decimal[] ~=` 6
--   )
--   ==`
--   (
--     sm_sc.ufv_prod_mx_based_org_chunk
--     (
--       a_left
--     , a_right
--     , a_l_w_r_h_chunk_pos
--     , a_left[ : 4][ : a_l_w_r_h_chunk_pos] |**| a_right[ : a_l_w_r_h_chunk_pos][ : 5]
--     ) :: decimal[] ~=` 6
--   )
-- from cte_input