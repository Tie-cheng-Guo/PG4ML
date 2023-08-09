-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists +` (anyarray, anyarray);
create operator +` 
(
  leftarg     =    anyarray           ,
  rightarg    =    anyarray           ,
  function    =    sm_sc.fv_opr_add  ,
  commutator  =    +`
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] +` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[-9.1]] +` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] +` array[array[12.5], array[-19.1]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] +` array[12.5, -19.1, 1.11]
-- select array[12.5, -19.1, 1.11] +` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- 重载
  drop operator if exists +` (anyelement, anyarray);
  create operator +` 
  (
    leftarg     =    anyelement             ,
    rightarg    =    anyarray           ,
    function    =    sm_sc.fv_opr_add  ,
    commutator  =    +`
  );
  -- select 8.8 +` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
  drop operator if exists +` (anyarray, anyelement);
  create operator +` 
  (
    leftarg     =    anyarray           ,
    rightarg    =    anyelement             ,
    function    =    sm_sc.fv_opr_add  ,
    commutator  =    +`
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] +` 8.9
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists -` (anyarray, anyarray);
create operator -` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_sub
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] -` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[-9.1]] -` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] -` array[array[12.5], array[-19.1]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] -` array[12.5, -19.1, 1.11]
-- select array[12.5, -19.1, 1.11] -` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- 重载
  drop operator if exists -` (anyarray, anyelement);
  create operator -` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_sub
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] -` 2.66
  drop operator if exists -` (anyelement, anyarray);
  create operator -` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_sub
  );
  -- select 2.66 -` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  drop operator if exists -` (none, anyarray);
  create operator -` 
  (
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_sub
  );
  -- select -` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists *` (anyarray, anyarray);
create operator *` 
(
  leftarg     =    anyarray           ,
  rightarg    =    anyarray           ,
  function    =    sm_sc.fv_opr_mul  ,
  commutator  =    *`
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] *` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[-9.1]] *` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] *` array[array[12.5], array[-19.1]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] *` array[12.5, -19.1, 1.11]
-- select array[12.5, -19.1, 1.11] *` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- 重载
  drop operator if exists *` (anyelement, anyarray);
  create operator *` 
  (
    leftarg     =    anyelement             ,
    rightarg    =    anyarray           ,
    function    =    sm_sc.fv_opr_mul  ,
    commutator  =    *`
  );
  -- select 52.3 *` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
  drop operator if exists *` (anyarray, anyelement);
  create operator *` 
  (
    leftarg     =    anyarray           ,
    rightarg    =    anyelement             ,
    function    =    sm_sc.fv_opr_mul  ,
    commutator  =    *`
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] *` 2.55
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists /` (anyarray, anyarray);
create operator /` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_div
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] /` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[-9.1]] /` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] /` array[array[12.5], array[-19.1]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] /` array[12.5, -19.1, 1.11]
-- select array[12.5, -19.1, 1.11] /` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- select array[12.5, -19.1, 1.11] /` array[array[0, 0, 0], array[0, 0, 0]]
  -- 重载
  drop operator if exists /` (anyelement, anyarray);
  create operator /` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_div
  );
  -- select 100.66 /` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
  -- select 100.66 /` array[array[12.5, 0, 43.6], array[-19.1, 28.6, 64.69]]
  drop operator if exists /` (anyarray, anyelement);
  create operator /` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_div
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] /` (-32.5)
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] /` 0
  drop operator if exists /` (none, anyarray);
  create operator /` 
  (
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_div
  );
  -- select /` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- select /` array[array[32.5, 1.26, 33.6], array[-9.1, 0, 4.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists %` (anyarray, anyarray);
create operator %` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_mod
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] %` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[-9.1]] %` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] %` array[array[12.5], array[-19.1]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] %` array[12.5, -19.1, 1.11]
-- select array[12.5, -19.1, 1.11] %` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- select array[12.5, -19.1, 1.11] %` array[array[0, 0, 0], array[0, 0, 0]]
  -- 重载
  drop operator if exists %` (anyelement, anyarray);
  create operator %` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_mod
  );
  -- select 100.66 %` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
  -- select 100.66 %` array[array[12.5, 0, 43.6], array[-19.1, 28.6, 64.69]]
  drop operator if exists %` (anyarray, anyelement);
  create operator %` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_mod
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] %` (-32.5)
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] %` 0
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists ^` (anyarray, anyarray);
create operator ^` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_pow
);
-- select array[array[32.5, 1.26, 33.6], array[9.1, 8.6, 4.69]] ^` array[array[2, 3, -1], array[-0.5, 1.5, 0]]
-- select array[array[32.5, 1.26, 33.6], array[9.1, 8.6, 4.69]] ^` array[array[2], array[-0.5]]
-- select array[array[32.5], array[9.1]] ^` array[array[2, 3, -1], array[-0.5, 1.5, 0]]
-- select array[32.5, 9.1, 3.2] ^` array[array[2, 3, -1], array[-0.5, 1.5, 0]]
-- select array[array[32.5, 9.1, 3.2], array[7.7, 8.2, 32.1]] ^` array[-0.5, 1.5, 0]
  -- 重载
  drop operator if exists ^` (anyelement, anyarray);
  create operator ^` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_pow
  );
  -- select 16.88 ^` array[array[2.5, 1.26, 3.6], array[9.1, 8.6, 4.69]]
  drop operator if exists ^` (anyarray, anyelement);
  create operator ^` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_pow
  );
  -- select array[array[32.5, 1.26, 33.6], array[9.1, 8.6, 4.69]] ^` (-1.5)
  drop operator if exists ^` (none, anyarray);
  create operator ^` 
  (
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_exp
  );
  -- select ^!` array[array[32.5, 1, 33.6], array[9.1, 8.6, 4.69]] 
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists ^!` (anyarray, anyarray);
create operator ^!` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_log
);
-- select array[array[32.5, 1, 33.6], array[9.1, 8.6, 4.69]] ^!` array[array[2, 3, 1.26], array[0.5, 1.5, 36]] 
-- select array[array[32.5, 1.26, 33.6], array[9.1, 8.6, 4.69]] ^!` array[array[2], array[0.5]]
-- select array[array[32.5], array[9.1]] ^!` array[array[2, 3, 1.26], array[0.5, 1.5, 1.5]]
-- select array[32.5, 9.1, 1] ^!` array[array[2, 3, 1.26], array[0.5, 1.5, 0.3]]
-- select array[array[32.5, 9.1, 3.2], array[7.7, 8.2, 1]] ^!` array[0.5, 1.5, 0.8]
  -- 重载
  drop operator if exists ^!` (anyelement, anyarray);
  create operator ^!` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_log
  );
  -- select 85.4 ^!` array[array[2, 3, 1.3], array[0.5, 1.5, 36]]
  drop operator if exists ^!` (anyarray, anyelement);
  create operator ^!` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_log
  );
  -- select array[array[32.5, 1, 33.6], array[9.1, 8.6, 4.69]] ^!` 2.5
  drop operator if exists ^!` (none, anyarray);
  create operator ^!` 
  (
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_ln
  );
  -- select ^!` array[array[32.5, 1, 33.6], array[9.1, 8.6, 4.69]] 
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists |` (boolean[], boolean[]);
create operator |` 
(
  leftarg     =    boolean[]           ,
  rightarg    =    boolean[]           ,
  function    =    sm_sc.fv_opr_or  ,
  commutator  =    |`
);
-- select array[array[true, false, true], array[false, false, true]] |` array[array[true, true, true], array[false, true, true]]
-- select array[array[true], array[false]] |` array[array[false, true, true], array[false, true, true]]
-- select array[array[true, false, true], array[false, false, true]] |` array[array[true], array[false]]
-- select array[array[true, false, true], array[false, false, true]] |` array[true, false, false]
-- select array[true, false, false] |` array[array[true, false, true], array[false, false, true]]
  -- 重载
  drop operator if exists |` (boolean, boolean[]);
  create operator |` 
  (
    leftarg     =    boolean             ,
    rightarg    =    boolean[]           ,
    function    =    sm_sc.fv_opr_or  ,
    commutator  =    |`
  );
  -- select true |` array[array[true, false, true], array[false, true, true]]
  drop operator if exists |` (boolean[], boolean);
  create operator |` 
  (
    leftarg     =    boolean[]           ,
    rightarg    =    boolean             ,
    function    =    sm_sc.fv_opr_or  ,
    commutator  =    |`
  );
  -- select array[array[true, false, true], array[false, false, true]] |` false

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists |` (varbit[], varbit[]);
create operator |` 
(
  leftarg     =    varbit[]           ,
  rightarg    =    varbit[]           ,
  function    =    sm_sc.fv_opr_or  ,
  commutator  =    |`
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] |` array[array[B'001', B'010', B'100'], array[B'110', B'011', B'110']]
-- select array[array[B'101'], array[B'001']] |` array[array[B'100', B'101', B'010'], array[B'100', B'000', B'010']]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] |` array[array[B'100'], array[B'100']]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] |` array[B'010', B'100', B'100']
-- select array[B'010', B'100', B'100'] |` array[array[B'110', B'010', B'100'], array[B'100', B'110', B'001']]
  -- 重载
  drop operator if exists |` (varbit, varbit[]);
  create operator |` 
  (
    leftarg     =    varbit             ,
    rightarg    =    varbit[]           ,
    function    =    sm_sc.fv_opr_or  ,
    commutator  =    |`
  );
  -- select B'001' |` array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']]
  drop operator if exists |` (varbit[], varbit);
  create operator |` 
  (
    leftarg     =    varbit[]           ,
    rightarg    =    varbit             ,
    function    =    sm_sc.fv_opr_or  ,
    commutator  =    |`
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] |` B'001'
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists &` (boolean[], boolean[]);
create operator &` 
(
  leftarg     =    boolean[]           ,
  rightarg    =    boolean[]           ,
  function    =    sm_sc.fv_opr_and  ,
  commutator  =    &`
);
-- select array[array[true, false, true], array[false, false, true]] &` array[array[true, true, true], array[false, true, true]]
-- select array[array[true], array[false]] &` array[array[false, true, true], array[false, true, true]]
-- select array[array[true, false, true], array[false, false, true]] &` array[array[true], array[false]]
-- select array[array[true, false, true], array[false, false, true]] &` array[true, false, false]
-- select array[true, false, false] &` array[array[true, false, true], array[false, false, true]]
  -- 重载
  drop operator if exists &` (boolean, boolean[]);
  create operator &` 
  (
    leftarg     =    boolean             ,
    rightarg    =    boolean[]           ,
    function    =    sm_sc.fv_opr_and  ,
    commutator  =    &`
  );
  -- select true &` array[array[true, false, true], array[false, true, true]]
  drop operator if exists &` (boolean[], boolean);
  create operator &` 
  (
    leftarg     =    boolean[]           ,
    rightarg    =    boolean             ,
    function    =    sm_sc.fv_opr_and  ,
    commutator  =    &`
  );
  -- select array[array[true, false, true], array[false, false, true]] &` false

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists &` (varbit[], varbit[]);
create operator &` 
(
  leftarg     =    varbit[]           ,
  rightarg    =    varbit[]           ,
  function    =    sm_sc.fv_opr_and  ,
  commutator  =    &`
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] &` array[array[B'001', B'010', B'100'], array[B'110', B'011', B'110']]
-- select array[array[B'101'], array[B'001']] &` array[array[B'100', B'101', B'010'], array[B'100', B'000', B'010']]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] &` array[array[B'100'], array[B'100']]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] &` array[B'010', B'100', B'100']
-- select array[B'010', B'100', B'100'] &` array[array[B'110', B'010', B'100'], array[B'100', B'110', B'001']]
  -- 重载
  drop operator if exists &` (varbit, varbit[]);
  create operator &` 
  (
    leftarg     =    varbit             ,
    rightarg    =    varbit[]           ,
    function    =    sm_sc.fv_opr_and  ,
    commutator  =    &`
  );
  -- select B'001' &` array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']]
  drop operator if exists &` (varbit[], varbit);
  create operator &` 
  (
    leftarg     =    varbit[]           ,
    rightarg    =    varbit             ,
    function    =    sm_sc.fv_opr_and  ,
    commutator  =    &`
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] &` B'001'
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ~` (none, boolean[]);
create operator ~` 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_opr_not
);
-- select ~` array[array[true, true, false], array[false, true, false]] 
drop operator if exists ~` (none, varbit[]);
create operator ~` 
(
  rightarg  =    varbit[]           ,
  function  =    sm_sc.fv_opr_not
);
-- select ~` array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] 
-- -----------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists ~` (text[], text[]);
create operator ~` 
(
  leftarg     =    text[]           ,
  rightarg    =    text[]           ,
  function    =    sm_sc.fv_opr_is_regexp_match  ,
  commutator  =    ~`
);
-- select array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']] ~` array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
-- select array[array['abbbbbc122223'], array['abc123']] ~` array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
-- select array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']] ~` array[array[a.c], array[1.*?3]]
-- select array[array['abbbbbc122223', 'abc123']] ~` array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
-- select array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']] ~` array[array['1.3', 'a.*?c']]
-- select array['abbbbbc122223', 'abc123', 'abc123', 'ac13'] ~` array['a.c', '1.*?3', '1.3', 'a.*?c']
  -- 重载
  drop operator if exists ~` (text, text[]);
  create operator ~` 
  (
    leftarg     =    text             ,
    rightarg    =    text[]           ,
    function    =    sm_sc.fv_opr_is_regexp_match  ,
    commutator  =    ~`
  );
  -- select 'abbbbbc122223'::text ~` array[array['a.c', '1.*?3'], array['1.3', 'a.*?c']]
  drop operator if exists ~` (text[], text);
  create operator ~` 
  (
    leftarg     =    text[]           ,
    rightarg    =    text             ,
    function    =    sm_sc.fv_opr_is_regexp_match  ,
    commutator  =    ~`
  );
  -- select array[array['abbbbbc122223', 'abc123'], array['abc123', 'ac13']] ~` 'a.c'::text
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ~` (none, sm_sc.typ_l_complex[]);
create operator ~` 
(
  rightarg  =    sm_sc.typ_l_complex[]           ,
  function  =    sm_sc.fv_opr_conjugate
);
-- select ~` array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex]
-- select ~` array[array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex], array[(12.3, 0.0)::sm_sc.typ_l_complex, (0.0, 3.25)::sm_sc.typ_l_complex]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists @~` (none, sm_sc.typ_l_complex[]);
create operator @~` 
(
  rightarg  =    sm_sc.typ_l_complex[]           ,
  function  =    sm_sc.fv_opr_real
);
-- select @~` array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex]
-- select @~` array[array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex], array[(12.3, 0.0)::sm_sc.typ_l_complex, (0.0, 3.25)::sm_sc.typ_l_complex]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ~@` (none, sm_sc.typ_l_complex[]);
create operator ~@` 
(
  rightarg  =    sm_sc.typ_l_complex[]           ,
  function  =    sm_sc.fv_opr_imaginary
);
-- select ~@` array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex]
-- select ~@` array[array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex], array[(12.3, 0.0)::sm_sc.typ_l_complex, (0.0, 3.25)::sm_sc.typ_l_complex]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ~^` (none, sm_sc.typ_l_complex[]);
create operator ~^` 
(
  rightarg  =    sm_sc.typ_l_complex[]           ,
  function  =    sm_sc.fv_opr_conjugate_45
);
-- select ~^` array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex]
-- select ~^` array[array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex], array[(12.3, 0.0)::sm_sc.typ_l_complex, (0.0, 3.25)::sm_sc.typ_l_complex]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists #` (boolean[], boolean[]);
create operator #` 
(
  leftarg     =    boolean[]           ,
  rightarg    =    boolean[]           ,
  function    =    sm_sc.fv_opr_xor  ,
  commutator  =    #`
);
-- select array[array[true, false, true], array[false, false, true]] #` array[array[true, true, true], array[false, true, true]]
-- select array[array[true], array[false]] #` array[array[false, true, true], array[false, true, true]]
-- select array[array[true, false, true], array[false, false, true]] #` array[array[true], array[false]]
-- select array[array[true, false, true], array[false, false, true]] #` array[true, false, false]
-- select array[true, false, false] #` array[array[true, false, true], array[false, false, true]]
  -- 重载
  drop operator if exists #` (boolean, boolean[]);
  create operator #` 
  (
    leftarg     =    boolean             ,
    rightarg    =    boolean[]           ,
    function    =    sm_sc.fv_opr_xor  ,
    commutator  =    #`
  );
  -- select true #` array[array[true, false, true], array[false, true, true]]
  drop operator if exists #` (boolean[], boolean);
  create operator #` 
  (
    leftarg     =    boolean[]           ,
    rightarg    =    boolean             ,
    function    =    sm_sc.fv_opr_xor  ,
    commutator  =    #`
  );
  -- select array[array[true, false, true], array[false, false, true]] #` false

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists #` (varbit[], varbit[]);
create operator #` 
(
  leftarg     =    varbit[]           ,
  rightarg    =    varbit[]           ,
  function    =    sm_sc.fv_opr_xor  ,
  commutator  =    #`
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] #` array[array[B'001', B'010', B'100'], array[B'110', B'011', B'110']]
-- select array[array[B'101'], array[B'001']] #` array[array[B'100', B'101', B'010'], array[B'100', B'000', B'010']]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] #` array[array[B'100'], array[B'100']]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] #` array[B'010', B'100', B'100']
-- select array[B'010', B'100', B'100'] #` array[array[B'110', B'010', B'100'], array[B'100', B'110', B'001']]
  -- 重载
  drop operator if exists #` (varbit, varbit[]);
  create operator #` 
  (
    leftarg     =    varbit             ,
    rightarg    =    varbit[]           ,
    function    =    sm_sc.fv_opr_xor  ,
    commutator  =    #`
  );
  -- select B'001' #` array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']]
  drop operator if exists #` (varbit[], varbit);
  create operator #` 
  (
    leftarg     =    varbit[]           ,
    rightarg    =    varbit             ,
    function    =    sm_sc.fv_opr_xor  ,
    commutator  =    #`
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] # B'001'
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists !#` (boolean[], boolean[]);
create operator !#` 
(
  leftarg     =    boolean[]           ,
  rightarg    =    boolean[]           ,
  function    =    sm_sc.fv_opr_xnor  ,
  commutator  =    !#`
);
-- select array[array[true, false, true], array[false, false, true]] !#` array[array[true, true, true], array[false, true, true]]
-- select array[array[true], array[false]] !#` array[array[false, true, true], array[false, true, true]]
-- select array[array[true, false, true], array[false, false, true]] !#` array[array[true], array[false]]
-- select array[array[true, false, true], array[false, false, true]] !#` array[true, false, false]
-- select array[true, false, false] !#` array[array[true, false, true], array[false, false, true]]
  -- 重载
  drop operator if exists !#` (boolean, boolean[]);
  create operator !#` 
  (
    leftarg     =    boolean             ,
    rightarg    =    boolean[]           ,
    function    =    sm_sc.fv_opr_xnor  ,
    commutator  =    !#`
  );
  -- select true !#` array[array[true, false, true], array[false, true, true]]
  drop operator if exists !#` (boolean[], boolean);
  create operator !#` 
  (
    leftarg     =    boolean[]           ,
    rightarg    =    boolean             ,
    function    =    sm_sc.fv_opr_xnor  ,
    commutator  =    !#`
  );
  -- select array[array[true, false, true], array[false, false, true]] !#` false

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists !#` (varbit[], varbit[]);
create operator !#` 
(
  leftarg     =    varbit[]           ,
  rightarg    =    varbit[]           ,
  function    =    sm_sc.fv_opr_xnor  ,
  commutator  =    !#`
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] !#` array[array[B'001', B'010', B'100'], array[B'110', B'011', B'110']]
-- select array[array[B'101'], array[B'001']] !#` array[array[B'100', B'101', B'010'], array[B'100', B'000', B'010']]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] !#` array[array[B'100'], array[B'100']]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] !#` array[B'010', B'100', B'100']
-- select array[B'010', B'100', B'100'] !#` array[array[B'110', B'010', B'100'], array[B'100', B'110', B'001']]
  -- 重载
  drop operator if exists !#` (varbit, varbit[]);
  create operator !#` 
  (
    leftarg     =    varbit             ,
    rightarg    =    varbit[]           ,
    function    =    sm_sc.fv_opr_xnor  ,
    commutator  =    !#`
  );
  -- select B'001' !#` array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']]
  drop operator if exists !#` (varbit[], varbit);
  create operator !#` 
  (
    leftarg     =    varbit[]           ,
    rightarg    =    varbit             ,
    function    =    sm_sc.fv_opr_xnor  ,
    commutator  =    !#`
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] !#` B'001'
-- -------------------------------------------------------------------------------------------------------
-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists ||` (anyarray, anyarray);
create operator ||` 
(
  leftarg     =    anyarray           ,
  rightarg    =    anyarray           ,
  function    =    sm_sc.fv_opr_concat  ,
  commutator  =    ||`
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] ||` array[array[B'001', B'010', B'100'], array[B'110', B'011', B'110']]
-- select array[array[B'101'], array[B'001']] ||` array[array[B'100', B'101', B'010'], array[B'100', B'000', B'010']]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] ||` array[array[B'100'], array[B'100']]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] ||` array[B'010', B'100', B'100']
-- select array[B'010', B'100', B'100'] ||` array[array[B'110', B'010', B'100'], array[B'100', B'110', B'001']]
  -- 重载
  drop operator if exists ||` (anyelement, anyarray);
  create operator ||` 
  (
    leftarg     =    anyelement             ,
    rightarg    =    anyarray           ,
    function    =    sm_sc.fv_opr_concat  ,
    commutator  =    ||`
  );
  -- select B'001' ||` array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']]
  drop operator if exists ||` (anyarray, anyelement);
  create operator ||` 
  (
    leftarg     =    anyarray           ,
    rightarg    =    anyelement             ,
    function    =    sm_sc.fv_opr_concat  ,
    commutator  =    ||`
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] ||` B'001'
-- -------------------------------------------------------------------------------------------------------
-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists <<` (varbit[], int[]);
create operator <<` 
(
  leftarg     =    varbit[]           ,
  rightarg    =    int[]           ,
  function    =    sm_sc.fv_opr_shift_left
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] <<` array[array[1, 2, -1], array[-2, 2, 1]]
-- select array[array[B'101'], array[B'001']] <<` array[array[1, 2, -1], array[-2, 2, 1]]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] <<` array[array[2], array[-1]]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] <<` array[1, -2, -1]
-- select array[B'010', B'100', B'100'] <<` array[array[1, 2, -1], array[-2, 2, 1]]
  -- 重载
  drop operator if exists <<` (varbit, int[]);
  create operator <<` 
  (
    leftarg     =    varbit             ,
    rightarg    =    int[]           ,
    function    =    sm_sc.fv_opr_shift_left
  );
  -- select B'001' <<` array[array[1, 2, -1], array[-2, 2, 1]]
  drop operator if exists <<` (varbit[], int);
  create operator <<` 
  (
    leftarg     =    varbit[]           ,
    rightarg    =    int             ,
    function    =    sm_sc.fv_opr_shift_left
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] <<` 2
-- -------------------------------------------------------------------------------------------------------
-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists >>` (varbit[], int[]);
create operator >>` 
(
  leftarg     =    varbit[]           ,
  rightarg    =    int[]           ,
  function    =    sm_sc.fv_opr_shift_right
);
-- select array[array[B'101', B'110', B'011'], array[B'010', B'101', B'111']] >>` array[array[1, 2, -1], array[-2, 2, 1]]
-- select array[array[B'101'], array[B'001']] >>` array[array[1, 2, -1], array[-2, 2, 1]]
-- select array[array[B'100', B'110', B'100'], array[B'100', B'001', B'010']] >>` array[array[2], array[-1]]
-- select array[array[B'100', B'100', B'110'], array[B'001', B'010', B'100']] >>` array[1, -2, -1]
-- select array[B'010', B'100', B'100'] >>` array[array[1, 2, -1], array[-2, 2, 1]]
  -- 重载
  drop operator if exists >>` (varbit, int[]);
  create operator >>` 
  (
    leftarg     =    varbit             ,
    rightarg    =    int[]           ,
    function    =    sm_sc.fv_opr_shift_right
  );
  -- select B'001' >>` array[array[1, 2, -1], array[-2, 2, 1]]
  drop operator if exists >>` (varbit[], int);
  create operator >>` 
  (
    leftarg     =    varbit[]           ,
    rightarg    =    int             ,
    function    =    sm_sc.fv_opr_shift_right
  );
  -- select array[array[B'110', B'010', B'100'], array[B'101', B'100', B'110']] >>` 2
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists ==` (anyarray, anyarray);
create operator ==` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_is_equal
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] ==` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] ==` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] ==` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] ==` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] ==` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists ==` (anyarray, anyelement);
  create operator ==` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_is_equal
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] ==` 12.5
  drop operator if exists ==` (anyelement, anyarray);
  create operator ==` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_is_equal
  );
  -- select (-15.6) ==` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists <` (anyarray, anyarray);
create operator <` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_is_less
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] <` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] <` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] <` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists <` (anyarray, anyelement);
  create operator <` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_is_less
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <` 12.5
  drop operator if exists <` (anyelement, anyarray);
  create operator <` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_is_less
  );
  -- select (-15.6) <` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists >` (anyarray, anyarray);
create operator >` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_is_greater
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] >` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] >` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] >` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] >` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] >` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists >` (anyarray, anyelement);
  create operator >` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_is_greater
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] >` 12.5
  drop operator if exists >` (anyelement, anyarray);
  create operator >` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_is_greater
  );
  -- select (-15.6) >` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists <=` (anyarray, anyarray);
create operator <=` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_is_less_ex
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <=` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] <=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] <=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] <=` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists <=` (anyarray, anyelement);
  create operator <=` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_is_less_ex
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <=` 12.5
  drop operator if exists <=` (anyelement, anyarray);
  create operator <=` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_is_less_ex
  );
  -- select (-15.6) <=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists >=` (anyarray, anyarray);
create operator >=` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_is_greater_ex
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] >=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] >=` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] >=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] >=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] >=` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists >=` (anyarray, anyelement);
  create operator >=` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_is_greater_ex
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] >=` 12.5
  drop operator if exists >=` (anyelement, anyarray);
  create operator >=` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_is_greater_ex
  );
  -- select (-15.6) >=` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists <>` (anyarray, anyarray);
create operator <>` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_compare
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <>` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] <>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] <>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] <>` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists <>` (anyarray, anyelement);
  create operator <>` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_compare
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] <>` 12.5
  drop operator if exists <>` (anyelement, anyarray);
  create operator <>` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_compare
  );
  -- select (-15.6) <>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]

drop operator if exists <>` (none, anyarray);
create operator <>` 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_sign
);
-- select <>` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] 
-- select <>` - array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] 
-- select <>` (- array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] )
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists @<` (anyarray, anyarray);
create operator @<` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_least  ,
  commutator  =    @<`
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] @<` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] @<` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] @<` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] @<` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] @<` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists @<` (anyarray, anyelement);
  create operator @<` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_least  ,
    commutator  =    @<`
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] @<` 12.5
  drop operator if exists @<` (anyelement, anyarray);
  create operator @<` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_least  ,
    commutator  =    @<`
  );
  -- select (-15.6) @<` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

-- 支持单列延拓情况，即 array_length(rightarg, 2) = 1
drop operator if exists @>` (anyarray, anyarray);
create operator @>` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_greatest  ,
  commutator  =    @>`
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] @>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] @>` array[12.5, 21.26, 43.6]
-- select array[32.5, 1.26, 33.6] @>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[33.6]] @>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]] @>` array[array[32.5], array[33.6]]
  -- 重载
  drop operator if exists @>` (anyarray, anyelement);
  create operator @>` 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_greatest,
    commutator  =    @>`
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] @>` 12.5
  drop operator if exists @>` (anyelement, anyarray);
  create operator @>` 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_greatest,
    commutator  =    @>`
  );
  -- select (-15.6) @>` array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists @` (none, anyarray);
create operator @` 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_abs
);
-- select @` array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] 
-- select @` - array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] 
-- select @` (- array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] )
-- -------------------------------------------------------------------------------------------------------


drop operator if exists ~=` (decimal[], int);
create operator ~=` 
(
  leftarg   =    decimal[]           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_round
);
-- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ~=` 2
  -- 重载
  -- -- -- pg14 好像不支持 右单目
  drop operator if exists ~=` (decimal[], none);
  create operator ~=` 
  (
    leftarg   =    decimal[]           ,
    function  =    sm_sc.fv_opr_round
  );
  -- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ~=`
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ~<` (decimal[], int);
create operator ~<` 
(
  leftarg   =    decimal[]           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_floor
);
-- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ~<` 2
  -- 重载
  -- -- -- pg14 好像不支持 右单目
  drop operator if exists ~<` (decimal[], none);
  create operator ~<` 
  (
    leftarg   =    decimal[]           ,
    function  =    sm_sc.fv_opr_floor
  );
  -- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ~<`
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ~>` (decimal[], int);
create operator ~>` 
(
  leftarg   =    decimal[]           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_ceil
);
-- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ~>` 2
  -- 重载
  -- -- -- pg14 好像不支持 右单目
  drop operator if exists ~>` (decimal[], none);
  create operator ~>` 
  (
    leftarg   =    decimal[]           ,
    function  =    sm_sc.fv_opr_ceil
  );
  -- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ~>`
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ><` (decimal[], int);
create operator ><` 
(
  leftarg   =    decimal[]           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_trunc
);
-- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ><` 2
  -- 重载
  -- -- -- pg14 好像不支持 右单目
  drop operator if exists ><` (decimal[], none);
  create operator ><` 
  (
    leftarg   =    decimal[]           ,
    function  =    sm_sc.fv_opr_trunc
  );
  -- select array[array[32.55345, 1.264834, 33.68373], array[-9.133, 8.6387, 4.6921]] ><`
-- -------------------------------------------------------------------------------------------------------

drop operator if exists ||~| (none, anyarray);
create operator ||~| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_mirror_y
);
-- select ||~| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |-~| (none, anyarray);
create operator |-~| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_mirror_x
);
-- select |-~| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |<~| (none, anyarray);
create operator |<~| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_turn_left
);
-- select |<~| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |>~| (none, anyarray);
create operator |>~| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_turn_right
);
-- select |>~| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |~~| (none, anyarray);
create operator |~~| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_turn_back
);
-- select |~~| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |^~| (none, anyarray);
create operator |^~| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_transpose
);
-- select |^~| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] 
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |^~`| (none, sm_sc.typ_l_complex[]);
create operator |^~`| 
(
  rightarg  =    sm_sc.typ_l_complex[]           ,
  function  =    sm_sc.fv_opr_conjugate_i
);
-- -- select |^~`| array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex]
-- select |^~`| array[array[(12.3, -25.1)::sm_sc.typ_l_complex, (-2.56, 3.25)::sm_sc.typ_l_complex, (-1, 3)::sm_sc.typ_l_complex], array[(-3, 1)::sm_sc.typ_l_complex, (12.3, 0.0)::sm_sc.typ_l_complex, (0.0, 3.25)::sm_sc.typ_l_complex]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |~^| (none, anyarray);
create operator |~^| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_transpose_i
);
-- select |~^| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] 
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |-|| (anyarray, anyarray);
create operator |-|| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_concat_y
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |-|| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[32.5, 1.26, 33.6] |-|| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |-|| array[12.5, 21.26, 43.6]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |-|| array[array[12.5], array[21.26], array[43.6]]
-- select array[array[12.5], array[21.26], array[43.6]] |-|| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- 重载
  drop operator if exists |-|| (anyelement, anyarray);
  create operator |-|| 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_concat_y
  );
  -- select 12.8 |-|| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
  drop operator if exists |-|| (anyarray, anyelement);
  create operator |-|| 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_concat_y
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |-|| (-12.8)
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |||| (anyarray, anyarray);
create operator |||| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_concat_x
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |||| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5], array[1.26]] -| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |||| array[array[12.5], array[21.26]]
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |||| array[12.5, 21.26]
-- select array[12.5, 21.26] |||| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- 重载
  drop operator if exists |||| (anyelement, anyarray);
  create operator |||| 
  (
    leftarg   =    anyelement           ,
    rightarg  =    anyarray           ,
    function  =    sm_sc.fv_opr_concat_x
  );
  -- select 4.25 |||| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
  drop operator if exists |||| (anyarray, anyelement);
  create operator |||| 
  (
    leftarg   =    anyarray           ,
    rightarg  =    anyelement           ,
    function  =    sm_sc.fv_opr_concat_x
  );
  -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |||| 4.25
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |`| (anyarray, anyarray);
create operator |`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_prod_inner  ,
  commutator  =    |`|
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |`| array[array[12.5, 21.26, 43.6], array[-19.1, 28.6, 64.69]]
-- -------------------------------------------------------------------------------------------------------

drop operator if exists |**| (float[], float[]);
create operator |**| 
(
  leftarg   =    float[]           ,
  rightarg  =    float[]           ,
  function  =    sm_sc.fv_opr_prod_mx_py
);
-- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |**| array[array[12.5, 21.26], array[-19.1, 43.6], array[28.6, 64.69]]
-- select array[array[12.5, 21.26], array[-19.1, 43.6], array[28.6, 64.69]] |**| array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]]
  -- -- -- pg14 好像不支持 右单目
  drop operator if exists |**| (float[], none);
  create operator |**| 
  (
    leftarg   =    float[]           ,
    function  =    sm_sc.fv_opr_prod_mx_left
  );
  -- select array[array[1.0000,2.0000,3.0000], array[4.0000,5.0000,6.0000]] |**|
  drop operator if exists |**| (none, float[]);
  create operator |**| 
  (
    rightarg  =    float[]           ,
    function  =    sm_sc.fv_opr_prod_mx_right
  );
  -- select |**| array[array[1.0000,2.0000,3.0000], array[4.0000,5.0000,6.0000]]
-- -------------------------------------------------------------------------------------------------------

-- -- drop operator if exists |~*| (anyarray, anyarray);
-- -- create operator |~*| 
-- -- (
-- --   leftarg   =    anyarray           ,
-- --   rightarg  =    anyarray           ,
-- --   function  =    sm_sc.fv_opr_prod_conv
-- -- );
-- -- -- select array[array[32.5, 1.26, 33.6], array[-9.1, 8.6, 4.69]] |~*| array[array[12.5, 21.26, -19.1], array[43.6, 28.6, 64.69]]
-- -- -- select array[32.5, 1.26, 33.6, -9.1, 8.6, 4.69] |~*| array[12.5, 21.26, -19.1, 43.6, 28.6, 64.69]


--  sm_sc.fv_aggr------------------------------------------
drop operator if exists |-=| (none, anyarray);
create operator |-=| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_coalesce
);
-- select |-=| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-&`| (none, boolean[]);
create operator |-&`| 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_aggr_x_and
);
-- select |-&`| array[[true, false, false], [true, false, false],[false, true, true]]

drop operator if exists |-&`| (none, bit[]);
create operator |-&`| 
(
  rightarg  =    bit[]           ,
  function  =    sm_sc.fv_aggr_x_and
);
-- select |-&`| array[[B'10101', B'10101', B'10101'], [B'101', B'101', B'110'], [B'1101', B'1001', B'1101']]

drop operator if exists |-|`| (none, boolean[]);
create operator |-|`| 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_aggr_x_or
);
-- select |-|`| array[[true, false, false], [true, false, false],[false, true, true]]

drop operator if exists |-|`| (none, bit[]);
create operator |-|`| 
(
  rightarg  =    bit[]           ,
  function  =    sm_sc.fv_aggr_x_or
);
-- select |-|`| array[[B'10101', B'10101', B'10101'], [B'101', B'101', B'110'], [B'1101', B'1001', B'1101']]

drop operator if exists |-||| (none, anyarray);
create operator |-||| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_concat
);
-- select |-||| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-/<| (none, anyarray);
create operator |-/<| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_median
);
-- select |-/<| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-/>| (none, anyarray);
create operator |-/>| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_mode
);
-- select |-/>| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-%`| (none, anyarray);
create operator |-%`| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_stddev_samp
);
-- select |-%`| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-%| (none, anyarray);
create operator |-%| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_stddev_pop
);
-- select |-%| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-#`| (none, anyarray);
create operator |-#`| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_var_samp
);
-- select |-#`| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-#| (none, anyarray);
create operator |-#| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_var_pop
);
-- select |-#| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-/=| (none, anyarray);
create operator |-/=| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_ptp
);
-- select |-/=| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-<| (none, anyarray);
create operator |-<| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_min
);
-- select |-<| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |->| (none, anyarray);
create operator |->| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_max
);
-- select |->| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-/| (none, anyarray);
create operator |-/| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_avg
);
-- select |-/| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-*| (none, anyarray);
create operator |-*| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_prod
);
-- select |-*| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |-+| (none, anyarray);
create operator |-+| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_x_sum
);
-- select |-+| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||=| (none, anyarray);
create operator ||=| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_coalesce
);
-- select ||=| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||&`| (none, boolean[]);
create operator ||&`| 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_aggr_y_and
);
-- select ||&`| array[[true, false, false], [true, false, true], [false, false, true]]

drop operator if exists ||&`| (none, bit[]);
create operator ||&`| 
(
  rightarg  =    bit[]           ,
  function  =    sm_sc.fv_aggr_y_and
);
-- select ||&`| array[[B'10101', B'101', B'1101'], [B'10101', B'101', B'1101'], [B'10101', B'101', B'1101']]

drop operator if exists |||`| (none, boolean[]);
create operator |||`| 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_aggr_y_or
);
-- select |||`| array[[true, false, false], [true, false, false], [false, true, true]]

drop operator if exists |||`| (none, bit[]);
create operator |||`| 
(
  rightarg  =    bit[]           ,
  function  =    sm_sc.fv_aggr_y_or
);
-- select |||`| array[[B'10101', B'101', B'1101'], [B'10001', B'001', B'1101'], [B'10101', B'101', B'1001']]

drop operator if exists ||||| (none, anyarray);
create operator ||||| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_concat
);
-- select ||||| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||/<| (none, anyarray);
create operator ||/<| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_median
);
-- select ||/<| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||/>| (none, anyarray);
create operator ||/>| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_mode
);
-- select ||/>| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||%`| (none, anyarray);
create operator ||%`| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_stddev_samp
);
-- select ||%`| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||%| (none, anyarray);
create operator ||%| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_stddev_pop
);
-- select ||%| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||#`| (none, anyarray);
create operator ||#`| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_var_samp
);
-- select ||#`| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||#| (none, anyarray);
create operator ||#| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_var_pop
);
-- select ||#| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||/=| (none, anyarray);
create operator ||/=| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_ptp
);
-- select ||/=| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||<| (none, anyarray);
create operator ||<| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_min
);
-- select ||<| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||>| (none, anyarray);
create operator ||>| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_max
);
-- select ||>| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||/| (none, anyarray);
create operator ||/| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_avg
);
-- select ||/| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||*| (none, anyarray);
create operator ||*| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_prod
);
-- select ||*| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists ||+| (none, anyarray);
create operator ||+| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_y_sum
);
-- select ||+| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@=| (none, anyarray);
create operator |@=| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_coalesce
);
-- select |@=| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@&`| (none, boolean[]);
create operator |@&`| 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_aggr_slice_and
);
-- select |@&`| array[[true, false, false, true], [false, true, false, true], [true, false, false, false], [false, false, true, true], [true, true, false, true]]

drop operator if exists |@&`| (none, bit[]);
create operator |@&`| 
(
  rightarg  =    bit[]           ,
  function  =    sm_sc.fv_aggr_slice_and
);
-- select |@&`| array[[B'010', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011']]

drop operator if exists |@|`| (none, boolean[]);
create operator |@|`| 
(
  rightarg  =    boolean[]           ,
  function  =    sm_sc.fv_aggr_slice_or
);
-- select |@|`| array[[true, false, false, true], [false, true, false, true], [true, false, false, false], [false, false, true, true], [true, true, false, true]]

drop operator if exists |@|`| (none, bit[]);
create operator |@|`| 
(
  rightarg  =    bit[]           ,
  function  =    sm_sc.fv_aggr_slice_or
);
-- select |@|`| array[[B'010', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011'], [B'101', B'011', B'010', B'011']]

drop operator if exists |@||| (none, anyarray);
create operator |@||| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_concat
);
-- select |@||| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@/<| (none, anyarray);
create operator |@/<| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_median
);
-- select |@/<| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@/>| (none, anyarray);
create operator |@/>| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_mode
);
-- select |@/>| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@%`| (none, anyarray);
create operator |@%`| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_stddev_samp
);
-- select |@%`| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@%| (none, anyarray);
create operator |@%| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_stddev_pop
);
-- select |@%| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@#`| (none, anyarray);
create operator |@#`| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_var_samp
);
-- select |@#`| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@#| (none, anyarray);
create operator |@#| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_var_pop
);
-- select |@#| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@/=| (none, anyarray);
create operator |@/=| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_ptp
);
-- select |@/=| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@<| (none, anyarray);
create operator |@<| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_min
);
-- select |@<| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@>| (none, anyarray);
create operator |@>| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_max
);
-- select |@>| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@/| (none, anyarray);
create operator |@/| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_avg
);
-- select |@/| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@*| (none, anyarray);
create operator |@*| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_prod
);
-- select |@*| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

drop operator if exists |@+| (none, anyarray);
create operator |@+| 
(
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_aggr_slice_sum
);
-- select |@+| array[[32.5, 1.26, 33.6], [-9.1, 8.6, 4.69], [-2.1, 3.6, -6.69]]

-- 方阵幂运算
-- ---------------------------------------------------------------------------------------------------------------
drop operator if exists |`^| (anyarray, anyelement);
create operator |`^| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyelement           ,
  function  =    sm_sc.fv_opr_prod_inner_pow
);
-- select array[array[32.5, 1.26, 33.6], array[9.1, 8.6, 4.69]] |`^| (-1.5)

-- ---------------------------------------------------------------------------------------------------------------
drop operator if exists |*^| (float[], int);
create operator |*^| 
(
  leftarg   =    float[]           ,
  rightarg  =    int           ,
  function  =    sm_sc.fv_opr_prod_mx_pow
);
-- select array[array[32.5, 1.26], array[8.6, 4.69]] |*^| 7

-- 组播运算
-- ---------------------------------------------------------------------------------------------------------------
drop operator if exists +`| (anyarray, anyarray);
create operator +`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_add
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] +`| array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] +`| array[0.7, 2.9, 0.68, 4.5]

drop operator if exists -`| (anyarray, anyarray);
create operator -`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_sub
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] -`| array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] -`| array[0.7, 2.9, 0.68, 4.5]

drop operator if exists |-` (anyarray, anyarray);
create operator |-` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_de_sub
);
-- select array[[0.7, 2.9], [0.68, 4.5]] |-` array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]]
-- select array[0.7, 2.9, 0.68, 4.5] |-` array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7]

drop operator if exists *`| (anyarray, anyarray);
create operator *`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_mul
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] *`| array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] *`| array[0.7, 2.9, 0.68, 4.5]

drop operator if exists /`| (anyarray, anyarray);
create operator /`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_div
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] /`| array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] /`| array[0.7, 2.9, 0.68, 4.5]

drop operator if exists |/` (anyarray, anyarray);
create operator |/` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_de_div
);
-- select array[[0.7, 2.9], [0.68, 4.5]] |/` array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]]
-- select array[0.7, 2.9, 0.68, 4.5] |/` array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7]

drop operator if exists ^`| (anyarray, anyarray);
create operator ^`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_pow
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] ^`| array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] ^`| array[0.7, 2.9, 0.68, 4.5]

drop operator if exists |^` (anyarray, anyarray);
create operator |^` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_de_pow
);
-- select array[[0.7, 2.9], [0.68, 4.5]] |^` array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]]
-- select array[0.7, 2.9, 0.68, 4.5] |^` array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7]

drop operator if exists ^!`| (anyarray, anyarray);
create operator ^!`| 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_log
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] ^!`| array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] ^!`| array[0.7, 2.9, 0.68, 4.5]

drop operator if exists |^!` (anyarray, anyarray);
create operator |^!` 
(
  leftarg   =    anyarray           ,
  rightarg  =    anyarray           ,
  function  =    sm_sc.fv_opr_conv_de_log
);
-- select array[[0.7, 2.9], [0.68, 4.5]] |^!` array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]]
-- select array[0.7, 2.9, 0.68, 4.5] |^!` array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7]

drop operator if exists |*` (float[], float[]);
create operator |*` 
(
  leftarg   =    float[]           ,
  rightarg  =    float[]           ,
  function  =    sm_sc.fv_opr_conv_prod
);
-- select array[[2.5, 1.26, 3.3], [8.6, 4.69, 9.7], [8.6, 4.69, 9.7]] |*` array[[0.7, 2.9], [0.68, 4.5]]
-- select array[2.5, 1.26, 3.3, 8.6, 4.69, 9.7, 8.6, 4.69, 9.7] |*` array[0.7, 2.9, 0.68, 4.5]
