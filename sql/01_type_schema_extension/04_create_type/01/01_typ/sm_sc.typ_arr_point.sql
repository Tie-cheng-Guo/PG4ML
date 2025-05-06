drop type if exists typ_arr_point;
create type typ_arr_point as
(
  point_id    varchar(64)      ,
  point_arr   float[]
);