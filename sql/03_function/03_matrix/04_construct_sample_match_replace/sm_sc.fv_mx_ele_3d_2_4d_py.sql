-- drop function if exists sm_sc.fv_mx_ele_3d_2_4d_py(float[], int, int, int, boolean);
create or replace function sm_sc.fv_mx_ele_3d_2_4d_py
(
  i_array_3d               float[]      
, i_cnt_per_grp            int                  -- 每个切分分组元素个数
, i_dim_from               int                  -- 被拆分维度
, i_dim_new                int                  -- 新生维度
, i_if_dim_pin_ele_on_from boolean              -- 是否在 from 维度保留元素顺序，否则在 new 维度保留元素顺序
)
returns float[]
as
$$
-- declare
begin
  -- 审计
  if current_setting('pg4ml._v_is_debug_check', true) = '1'
  then
    if array_ndims(i_array_3d) <> 3
    then 
      raise exception 'ndims should be 3.';
    end if;
    
    if array_length(i_array_3d, i_dim_from) % i_cnt_per_grp > 0
      or i_cnt_per_grp not between 1 and array_length(i_array_3d, i_dim_from)
    then 
      raise exception 'unperfect such i_cnt_per_grp.';
    end if;
    
    if i_dim_new not between 1 and 4
    then 
      raise exception 'unsupport such i_dim_new.';
    end if;
  end if;
 
  if i_array_3d is null 
  then 
    return null;
  elsif i_dim_from = 1
  then 
    if i_dim_new in (1, 2)
    then
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from        -- i_dim_new = 2
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from   -- i_dim_new = 1
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3)
            ]
          )
          |^~| array[1, 2]
        ;
        
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3)
            ]
          )
        ;
        
      end if;
    elsif i_dim_new = 3
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d |^~| array[1, 2]
          , array
            [
              array_length(i_array_3d, 2)
            , array_length(i_array_3d, 1) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 3)
            ]
          )
          |^~| array[3, 2] |^~| array[2, 1]
        ;
        
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3)
            ]
          )
          |^~| array[3, 2]
        ;
        
      end if;
    elsif i_dim_new = 4
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d |^~| array[1, 2] |^~| array[2, 3]
          , array
            [
              array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3)
            , array_length(i_array_3d, 1) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[3, 4] |^~| array[2, 3] |^~| array[1, 2]
        ;
        
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d |^~| array[1, 2] |^~| array[2, 3]
          , array
            [
              array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3)
            , array_length(i_array_3d, 1) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[2, 3] |^~| array[1, 2]
        ;
        
      end if;
    end if;
  elsif i_dim_from = 2
  then 
    if i_dim_new = 1
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 3)
            ]
          )
          |^~| array[1, 2]
        ;
        
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 3)
            ]
          )
          |^~| array[2, 3] |^~| array[1, 2]
        ;
        
      end if;
    elsif i_dim_new in (2, 3)
    then
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 3)
            ]
          )
          |^~| array[2, 3]
        ;
        
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2) / i_cnt_per_grp
            , i_cnt_per_grp
            , array_length(i_array_3d, 3)
            ]
          )
        ;
        
      end if;
    elsif i_dim_new = 4
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d |^~| array[2, 3]
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 3)
            , array_length(i_array_3d, 2) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[3, 4] |^~| array[2, 3]
        ;
        
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d |^~| array[2, 3]
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 3)
            , array_length(i_array_3d, 2) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[2, 3]
        ;
        
      end if;
    end if;
  elsif i_dim_from = 3
  then 
    if i_dim_new = 1
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[3, 2] |^~| array[2, 1]
        ;
        
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d 
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[4, 3] |^~| array[3, 2] |^~| array[2, 1]
        ;
        
      end if;
    elsif i_dim_new = 2
    then
      if i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[2, 3]
        ;
        
      elsif not i_if_dim_pin_ele_on_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[3, 4] |^~| array[2, 3]
        ;
        
      end if;
    elsif i_dim_new in (3, 4)
    then
      if i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or not i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
          |^~| array[3, 4]
        ;
        
      elsif not i_if_dim_pin_ele_on_from and i_dim_new <> i_dim_from
        or i_if_dim_pin_ele_on_from and i_dim_new = i_dim_from
      then 
        return 
          sm_sc.fv_opr_reshape_py
          (
            i_array_3d
          , array
            [
              array_length(i_array_3d, 1)
            , array_length(i_array_3d, 2)
            , array_length(i_array_3d, 3) / i_cnt_per_grp
            , i_cnt_per_grp
            ]
          )
        ;
        
      end if;
    end if;
  end if;
end
$$
language plpgsql stable
parallel safe
cost 100;


-- select 
--   sm_sc.fv_mx_ele_3d_2_4d_py
--   (
--     array
--     [
--       [[1,2,3,4,5,6],[11,12,13,14,15,16],[21,22,23,24,25,26],[31,32,33,34,35,36]]
--     , [[41,42,43,44,45,46],[51,52,53,54,55,56],[61,62,63,64,65,66],[71,72,73,74,75,76]]
--     , [[-1,-2,-3,-4,-5,-6],[11,-12,-13,-14,-15,-16],[21,-22,-23,-24,-25,-26],[-31,-32,-33,-34,-35,-36]]
--     , [[-41,-42,-43,-44,-45,-46],[-51,-52,-53,-54,-55,-56],[-61,-62,-63,-64,-65,-66],[-71,-72,-73,-74,-75,-76]]
--     , [[10,20,30,40,50,60],[110,120,130,140,150,160],[210,220,230,240,250,260],[310,320,330,340,350,360]]
--     , [[410,420,430,440,450,460],[510,520,530,540,550,560],[610,620,630,640,650,660],[710,720,730,740,750,760]]
--     , [[-10,-20,-30,-40,-50,-60],[110,-120,-130,-140,-150,-160],[210,-220,-230,-240,-250,-260],[-310,-320,-330,-340,-350,-360]]
--     , [[-410,-420,-430,-440,-450,-460],[-510,-520,-530,-540,-550,-560],[-610,-620,-630,-640,-650,-660],[-710,-720,-730,-740,-750,-760]]
--     ]
--   , 2
--   , 3   -- a_dim_from
--   , 1   -- a_dim_new
--   , true   -- a_dim_pin_ele_on_from
--   )
-- from 
--   generate_series(1, 3) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 4) tb_a_dim_new(a_dim_new)
-- , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)

-- select 
--   a_dim_from
-- , a_dim_new
-- , a_dim_pin_ele_on_from
-- , array_dims
--   (
--     sm_sc.fv_mx_ele_3d_2_4d_py
--     (
--       sm_sc.fv_new_rand(array[6,8,10])
--     , 2
--     , a_dim_from
--     , a_dim_new
--     , a_dim_pin_ele_on_from
--     )
--   )
-- from 
--   generate_series(1, 3) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 4) tb_a_dim_new(a_dim_new)
-- , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)
-- order by a_dim_from, a_dim_new, a_dim_pin_ele_on_from

-- select 
--   a_dim_from
-- , a_dim_new
-- , a_dim_pin_ele_on_from
-- , sm_sc.fv_mx_ele_3d_2_4d_py
--   (
--     a_arr
--   , 2
--   , a_dim_from
--   , a_dim_new
--   , a_dim_pin_ele_on_from
--   )
-- , sm_sc.fv_mx_ele_3d_2_4d
--   (
--     a_arr
--   , 2
--   , a_dim_from
--   , a_dim_new
--   , a_dim_pin_ele_on_from
--   )
-- from 
--   (select 
--      array 
--      [[[  0,  1,  2,  3,  4,  5,  6,  7,  8,  9]
--       ,[ 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
--       ,[ 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
--       ,[ 30, 31, 32, 33, 34, 35, 36, 37, 38, 39]
--       ,[ 40, 41, 42, 43, 44, 45, 46, 47, 48, 49]
--       ,[ 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
--       ,[ 60, 61, 62, 63, 64, 65, 66, 67, 68, 69]
--       ,[ 70, 71, 72, 73, 74, 75, 76, 77, 78, 79]]
--      ,[[ 80, 81, 82, 83, 84, 85, 86, 87, 88, 89]
--       ,[ 90, 91, 92, 93, 94, 95, 96, 97, 98, 99]
--       ,[100,101,102,103,104,105,106,107,108,109]
--       ,[110,111,112,113,114,115,116,117,118,119]
--       ,[120,121,122,123,124,125,126,127,128,129]
--       ,[130,131,132,133,134,135,136,137,138,139]
--       ,[140,141,142,143,144,145,146,147,148,149]
--       ,[150,151,152,153,154,155,156,157,158,159]]
--      ,[[160,161,162,163,164,165,166,167,168,169]
--       ,[170,171,172,173,174,175,176,177,178,179]
--       ,[180,181,182,183,184,185,186,187,188,189]
--       ,[190,191,192,193,194,195,196,197,198,199]
--       ,[200,201,202,203,204,205,206,207,208,209]
--       ,[210,211,212,213,214,215,216,217,218,219]
--       ,[220,221,222,223,224,225,226,227,228,229]
--       ,[230,231,232,233,234,235,236,237,238,239]]
--      ,[[240,241,242,243,244,245,246,247,248,249]
--       ,[250,251,252,253,254,255,256,257,258,259]
--       ,[260,261,262,263,264,265,266,267,268,269]
--       ,[270,271,272,273,274,275,276,277,278,279]
--       ,[280,281,282,283,284,285,286,287,288,289]
--       ,[290,291,292,293,294,295,296,297,298,299]
--       ,[300,301,302,303,304,305,306,307,308,309]
--       ,[310,311,312,313,314,315,316,317,318,319]]
--      ,[[320,321,322,323,324,325,326,327,328,329]
--       ,[330,331,332,333,334,335,336,337,338,339]
--       ,[340,341,342,343,344,345,346,347,348,349]
--       ,[350,351,352,353,354,355,356,357,358,359]
--       ,[360,361,362,363,364,365,366,367,368,369]
--       ,[370,371,372,373,374,375,376,377,378,379]
--       ,[380,381,382,383,384,385,386,387,388,389]
--       ,[390,391,392,393,394,395,396,397,398,399]]
--      ,[[400,401,402,403,404,405,406,407,408,409]
--       ,[410,411,412,413,414,415,416,417,418,419]
--       ,[420,421,422,423,424,425,426,427,428,429]
--       ,[430,431,432,433,434,435,436,437,438,439]
--       ,[440,441,442,443,444,445,446,447,448,449]
--       ,[450,451,452,453,454,455,456,457,458,459]
--       ,[460,461,462,463,464,465,466,467,468,469]
--       ,[470,471,472,473,474,475,476,477,478,479]]]
--      :: float[] as a_arr
--   ) tb_a_arr
-- , generate_series(1, 3) tb_a_dim_from(a_dim_from)
-- , generate_series(1, 4) tb_a_dim_new(a_dim_new)
-- , (select true as a_dim_pin_ele_on_from union all select false as a_dim_pin_ele_on_from) tb_a_dim_pin_ele_on_from(a_dim_pin_ele_on_from)
-- order by a_dim_from, a_dim_new, a_dim_pin_ele_on_from