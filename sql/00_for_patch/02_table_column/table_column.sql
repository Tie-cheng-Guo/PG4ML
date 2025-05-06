-- create table
drop table if exists sm_sc.__vt_prod_mx_quantum_dic;
create unlogged table sm_sc.__vt_prod_mx_quantum_dic
(
  sign_reciprocal_quantum_key              int
, sign_reciprocal_quantum_val              float   
, sign_reciprocal_quantum_desc             varchar
, primary key(sign_reciprocal_quantum_key)
);

comment on table  sm_sc.__vt_prod_mx_quantum_dic                                   is '用于近似矩阵乘法的整指数能态字典';
comment on column sm_sc.__vt_prod_mx_quantum_dic.sign_reciprocal_quantum_key       is '能态序号，能态量级'     ;
comment on column sm_sc.__vt_prod_mx_quantum_dic.sign_reciprocal_quantum_val       is '能态数值'               ;
comment on column sm_sc.__vt_prod_mx_quantum_dic.sign_reciprocal_quantum_desc      is '能态描述'               ;

create index on sm_sc.__vt_prod_mx_quantum_dic using hash (sign_reciprocal_quantum_key) ;

drop table if exists sm_sc.__vt_prod_mx_quantum_dic_arr;
create unlogged table sm_sc.__vt_prod_mx_quantum_dic_arr
(
  sign_reciprocal_quantum_arr          float[]
, sign_reciprocal_quantum_arr_desc     int[2]
);

comment on table  sm_sc.__vt_prod_mx_quantum_dic_arr                                    is '用于近似矩阵乘法的整指数能态字典的数组类型，用于内存变量';
comment on column sm_sc.__vt_prod_mx_quantum_dic_arr.sign_reciprocal_quantum_arr        is '整指数能态字典的数组类型'                   ;
comment on column sm_sc.__vt_prod_mx_quantum_dic_arr.sign_reciprocal_quantum_arr_desc   is '整指数能态字典的数组类型量级和范围描述'     ;
