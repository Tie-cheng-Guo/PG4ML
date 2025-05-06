-- 创建高维数据点类型，用于聚类计算
-- create extension cube
drop type if exists typ_arr_point_cube;
create type typ_arr_point_cube as
(
  point_id    varchar(64)      ,
  point_arr   cube
);
