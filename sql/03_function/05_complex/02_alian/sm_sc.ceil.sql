-- set search_path to sm_sc;
-- drop function if exists sm_sc.ceil(sm_sc.typ_l_complex, int);
create or replace function sm_sc.ceil
(
  i_left     sm_sc.typ_l_complex    ,
  i_num_digits    int
)
returns sm_sc.typ_l_complex
as
$$
declare -- here
  v_balan   decimal  := 5.0 * power(0.1, i_num_digits + 1)  ;
begin
  return 
    (

      case 
        when i_left.m_re = round(i_left.m_re :: decimal, i_num_digits) 
          then i_left.m_re
        else round(i_left.m_re :: decimal + v_balan, i_num_digits) 
      end,
      case 
        when i_left.m_im = round(i_left.m_im :: decimal, i_num_digits) 
          then i_left.m_im
        else round(i_left.m_im :: decimal + v_balan, i_num_digits) 
      end
    )::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.ceil
--   (
--     (12.35464645, -12.30325015),
--     2
--   );

-- -------------------------------------------------------------------------------------
-- set search_path to sm_sc;
-- drop function if exists sm_sc.ceil(sm_sc.typ_l_complex);
create or replace function sm_sc.ceil
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return (ceil(i_right.m_re :: decimal), ceil(i_right.m_im :: decimal))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.ceil
--   (
--     (-45.6, -45.6)
--   );