-- set search_path to schm_cpx;
-- drop function if exists ceil(sm_sc.typ_l_complex, int);
create or replace function ceil
(
  i_left     sm_sc.typ_l_complex    ,
  i_right    int
)
returns sm_sc.typ_l_complex
as
$$
declare -- here
  v_balan   float  := 5.0 * power(0.1, i_right + 1) :: float  ;
begin
  return 
    (

      case 
        when i_left.m_re = round(i_left.m_re, i_num_digits) 
          then i_left.m_re
        else round(i_left.m_re + v_balan, i_num_digits) 
      end,
      case 
        when i_left.m_im = round(i_left.m_im, i_num_digits) 
          then i_left.m_im
        else round(i_left.m_im + v_balan, i_num_digits) 
      end
    )::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select ceil
--   (
--     (12.35464645, -12.30325015),
--     2
--   );

-- -------------------------------------------------------------------------------------
-- set search_path to schm_cpx;
-- drop function if exists ceil(sm_sc.typ_l_complex);
create or replace function ceil
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return (ceil(i_right.m_re), ceil(i_right.m_im))::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select ceil
--   (
--     (-45.6, -45.6)
--   );