drop operator if exists + (sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create operator + 
(
  leftarg     =    sm_sc.typ_l_complex           ,
  rightarg    =    sm_sc.typ_l_complex           ,
  function    =    sm_sc.fv_opr_add  ,
  commutator  =    +
);
-- select (12.3, -56.6)::sm_sc.typ_l_complex + (-2.3, 6.6)::sm_sc.typ_l_complex
-- select 12.3 + (-2.3, 6.6)::sm_sc.typ_l_complex
-- select (12.3, -56.6)::sm_sc.typ_l_complex + 6.6
-- -------------------------------------------------------------------------------------------------------
drop operator if exists - (sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create operator - 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    sm_sc.typ_l_complex           ,
  function  =    sm_sc.fv_opr_sub
);
-- select (12.3, -56.6)::sm_sc.typ_l_complex - (-2.3, 6.6)::sm_sc.typ_l_complex
-- select 12.3 - (-2.3, 6.6)::sm_sc.typ_l_complex
-- select (12.3, -56.6)::sm_sc.typ_l_complex - 6.6
  drop operator if exists - (none, sm_sc.typ_l_complex);
  create operator - 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_sub
  );
  -- select - (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select - 56.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists * (sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create operator * 
(
  leftarg     =    sm_sc.typ_l_complex           ,
  rightarg    =    sm_sc.typ_l_complex           ,
  function    =    sm_sc.fv_opr_mul  ,
  commutator  =    *
);
-- select (12.3, -56.6)::sm_sc.typ_l_complex * (-2.3, 6.6)::sm_sc.typ_l_complex
-- select 12.3 * (-2.3, 6.6)::sm_sc.typ_l_complex
-- select (12.3, -56.6)::sm_sc.typ_l_complex * 6.6
-- -------------------------------------------------------------------------------------------------------
drop operator if exists ~ (none, sm_sc.typ_l_complex);
create operator ~ 
(
  rightarg  =    sm_sc.typ_l_complex           ,
  function  =    sm_sc.fv_opr_conjugate
);
-- select ~ (-2.3, 6.6)::sm_sc.typ_l_complex
-- select ~ 56.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists @ (none, sm_sc.typ_l_complex);
create operator @ 
(
  rightarg  =    sm_sc.typ_l_complex           ,
  function  =    sm_sc.fv_opr_norm
);
-- select @ (-2.3, 6.6)::sm_sc.typ_l_complex
-- select @ 56.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists / (sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create operator / 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    sm_sc.typ_l_complex           ,
  function  =    sm_sc.fv_opr_div
);
-- select (12.3, -56.6)::sm_sc.typ_l_complex / (-2.3, 6.6)::sm_sc.typ_l_complex
-- select 12.3 / (-2.3, 6.6)::sm_sc.typ_l_complex
-- select (12.3, -56.6)::sm_sc.typ_l_complex / 6.6
  -- -- -- 不支持 / 做为单目运算符，会出现语法错误
  -- -- -- https://www.imooc.com/wenda/detail/564806
  -- -- -- https://www.linuxidc.com/Linux/2012-02/53783.htm
  -- -- drop operator if exists / (none, sm_sc.typ_l_complex);
  -- -- create operator / 
  -- -- (
  -- --   rightarg  =    sm_sc.typ_l_complex           ,
  -- --   function  =    sm_sc.fv_opr_div
  -- -- );
  -- -- -- select / (-2.3, 6.6)::sm_sc.typ_l_complex
  -- -- -- select / 56.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists ^ (sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create operator ^ 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    sm_sc.typ_l_complex           ,
  function  =    sm_sc.fv_opr_pow
);
-- select (2.3, -5.6)::sm_sc.typ_l_complex ^ (-2.3, 6.6)::sm_sc.typ_l_complex
-- select 2.3 ^ (-2.3, 2)::sm_sc.typ_l_complex
-- select (12.3, -56.6)::sm_sc.typ_l_complex ^ 3.0

  -- -- -- -- 不支持 ^ 作为单目运算符，会出现语法错误
  -- -- -- drop operator if exists ^ (none, sm_sc.typ_l_complex);
  -- -- -- create operator ^ 
  -- -- -- (
  -- -- --   rightarg  =    sm_sc.typ_l_complex           ,
  -- -- --   function  =    sm_sc.fv_opr_exp
  -- -- -- );
  -- -- -- -- select ^ (-2.3, 6.6)::sm_sc.typ_l_complex
  -- -- -- -- select ^ 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists ^! (sm_sc.typ_l_complex, sm_sc.typ_l_complex);
create operator ^! 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    sm_sc.typ_l_complex           ,
  function  =    sm_sc.fv_opr_log
);
-- select (2.3, -5.6)::sm_sc.typ_l_complex ^! (-2.3, 6.6)::sm_sc.typ_l_complex
-- select 2.3 ^! (-2.3, 2)::sm_sc.typ_l_complex
-- select (12.3, -56.6)::sm_sc.typ_l_complex ^! 3.0
  drop operator if exists ^! (none, sm_sc.typ_l_complex);
  create operator ^! 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_ln
  );
  -- select ^! (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select ^! 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
  drop operator if exists @~ (none, sm_sc.typ_l_complex);
  create operator @~ 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_real
  );
  -- select @~ (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select @~ 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
  drop operator if exists ~@ (none, sm_sc.typ_l_complex);
  create operator ~@ 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_imaginary
  );
  -- select ~@ (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select ~@ 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
  drop operator if exists ~^ (none, sm_sc.typ_l_complex);
  create operator ~^ 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_conjugate_45
  );
  -- select ~^ (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select ~^ 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists ~= (sm_sc.typ_l_complex, int);
create operator ~= 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_round
);
-- select (12.39678, -56.656466)::sm_sc.typ_l_complex ~= 3
  drop operator if exists ~= (none, sm_sc.typ_l_complex);
  create operator ~= 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_round
  );
  -- select ~= (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select ~= 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists ~< (sm_sc.typ_l_complex, int);
create operator ~< 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_floor
);
-- select (12.39678, -56.656466)::sm_sc.typ_l_complex ~< 3
  drop operator if exists ~< (none, sm_sc.typ_l_complex);
  create operator ~< 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_floor
  );
  -- select ~< (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select ~< 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists ~> (sm_sc.typ_l_complex, int);
create operator ~> 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_ceil
);
-- select (12.39678, -56.656466)::sm_sc.typ_l_complex ~> 3
  drop operator if exists ~> (none, sm_sc.typ_l_complex);
  create operator ~> 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_ceil
  );
  -- select ~> (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select ~> 6.6::sm_sc.typ_l_complex
-- -------------------------------------------------------------------------------------------------------
drop operator if exists >< (sm_sc.typ_l_complex, int);
create operator >< 
(
  leftarg   =    sm_sc.typ_l_complex           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_trunc
);
-- select (12.39678, -56.656466)::sm_sc.typ_l_complex >< 3
  drop operator if exists >< (none, sm_sc.typ_l_complex);
  create operator >< 
  (
    rightarg  =    sm_sc.typ_l_complex           ,
    function  =    sm_sc.fv_opr_trunc
  );
  -- select >< (-2.3, 6.6)::sm_sc.typ_l_complex
  -- select >< 6.6::sm_sc.typ_l_complex