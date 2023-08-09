-- set search_path to schm_cpx;
-- drop function if exists sm_sc.fv_opr_ln(sm_sc.typ_l_complex);
create or replace function sm_sc.fv_opr_ln
(
  i_right    sm_sc.typ_l_complex
)
returns sm_sc.typ_l_complex
as
$$
-- declare 
begin
  return 
    row
    (
      ln(sm_sc.fv_opr_norm(i_right)),
      case 
        when i_right.m_re = 0.0 and i_right.m_im > 0.0 
          then atan('Infinity') ::double precision
        when i_right.m_re = 0.0 and i_right.m_im < 0.0 
          then atan('-Infinity') ::double precision
        when i_right.m_re = 0.0 and i_right.m_im = 0.0 
          then null -- ln(0)
        else
          -- atan(i_right.m_im::double precision / i_right.m_re::double precision)   --   + k * pi()   -- 可以获得多个结果，其中k为整数
          -- 简化在 ( -pi(), pi() ] 半开半闭区间，绝对值最小的取值
          atan(i_right.m_im::double precision / i_right.m_re::double precision) 
          + case 
              when i_right.m_re < 0.0 and i_right.m_im >= 0 then pi()
              when i_right.m_re < 0.0 and i_right.m_im < 0 then -pi()
              else 0.0
            end
       end
    )::sm_sc.typ_l_complex;
end
$$
language plpgsql stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_ln
--   (
--     (45.6, -45.6)
--   );
-- select sm_sc.fv_opr_ln
--   (
--     100.0
--   );
-- select sm_sc.fv_opr_ln
--   (
--     (0, -16.0)
--   );
-- -- select sm_sc.fv_opr_ln
-- --   (
-- --     0.0
-- --   );