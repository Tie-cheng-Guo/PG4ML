-- drop function if exists sm_sc.fv_sgn_ifft(sm_sc.typ_l_complex[]);
create or replace function sm_sc.fv_sgn_ifft
(
  i_array           sm_sc.typ_l_complex[]
)
returns sm_sc.typ_l_complex[]
as
$$
declare -- here
-- 如果要返回任意长度，要做循环卷积改造 https://blog.csdn.net/weixin_34128237/article/details/94637989
  v_len_1_ex     int   := case when array_ndims(i_array) = 1 then power(2, ceil(log(2, array_length(i_array, 1) :: float))) :: int else null end;     -- 时域补零至就近的power(2,n)，频域升采样
  v_w            sm_sc.typ_l_complex     :=   (exp(1)::sm_sc.typ_l_complex) ^ ((0.0 :: float, -2 * pi() / v_len_1_ex)::sm_sc.typ_l_complex);
  v_w_wheel      sm_sc.typ_l_complex     :=   (1.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex;
  v_arr_even     sm_sc.typ_l_complex[]   :=   (select array_agg(coalesce(i_array[a_even_no], (0.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex) order by a_even_no) from generate_series(1, v_len_1_ex, 2) tb_a_even_no(a_even_no));
  v_arr_odd      sm_sc.typ_l_complex[]   :=   (select array_agg(coalesce(i_array[a_odd_no], (0.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex) order by a_odd_no) from generate_series(2, v_len_1_ex, 2) tb_a_odd_no(a_odd_no));
  v_ret          sm_sc.typ_l_complex[]   :=   array_fill(0.0 :: float, array[v_len_1_ex]);
  v_cur          int;

begin
  if array_ndims(i_array) = 1
  then 
    if v_len_1_ex = 1
    then 
      return array[coalesce(i_array[1], (0.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex)];
    end if;
    
    v_arr_even := sm_sc.fv_sgn_ifft(v_arr_even);
    v_arr_odd := sm_sc.fv_sgn_ifft(v_arr_odd);
    
    for v_cur in 1 .. (v_len_1_ex / 2)
    loop
      v_ret[v_cur] := (v_arr_even[v_cur] + (v_w_wheel * v_arr_odd[v_cur])) / 2;
      v_ret[v_cur + v_len_1_ex / 2] := (v_arr_even[v_cur] - (v_w_wheel * v_arr_odd[v_cur])) / 2;
      v_w_wheel := v_w_wheel * v_w;
    end loop;
    
    return v_ret;  
  else
    raise exception 'error dim!';
  end if;
end 
$$
language plpgsql stable
cost 100;

-- select sm_sc.fv_sgn_ifft
-- (
-- array
-- [ 
--   1.        ,  0.97952994,  0.91895781,  0.82076344,  0.68896692,  0.52896401,
--   0.34730525,  0.15142778, -0.05064917, -0.25065253, -0.44039415, -0.61210598,
--  -0.75875812, -0.87434662, -0.95413926, -0.99486932, -0.99486932, -0.95413926,
--  -0.87434662, -0.75875812, -0.61210598, -0.44039415, -0.25065253, -0.05064917,
--   0.15142778,  0.34730525,  0.52896401,  0.68896692,  0.82076344,  0.91895781,
--   0.97952994,  1.        
-- ]
-- ):: sm_sc.typ_l_complex[]
-- -- 预期结果：
-- --   (0.03125001,0.00000000)
-- --   (0.50467925,0.04970657)
-- --   (-0.01105730,-0.00219944)
-- --   (-0.00395641,-0.00120017)
-- --   (-0.00200427,-0.00083020)
-- --   (-0.00117356,-0.00062728)
-- --   (-0.00074097,-0.00049510)
-- --   (-0.00048728,-0.00039991)
-- --   (-0.00032653,-0.00032653)
-- --   (-0.00021918,-0.00026707)
-- --   (-0.00014495,-0.00021693)
-- --   (-0.00009260,-0.00017324)
-- --   (-0.00005554,-0.00013409)
-- --   (-0.00002977,-0.00009812)
-- --   (-0.00001279,-0.00006431)
-- --   (-0.00000314,-0.00003183)
-- --   (0.00000000,0.00000000)
-- --   (-0.00000314,0.00003183)
-- --   (-0.00001279,0.00006431)
-- --   (-0.00002977,0.00009812)
-- --   (-0.00005554,0.00013409)
-- --   (-0.00009260,0.00017324)
-- --   (-0.00014495,0.00021693)
-- --   (-0.00021917,0.00026707)
-- --   (-0.00032653,0.00032653)
-- --   (-0.00048729,0.00039991)
-- --   (-0.00074097,0.00049510)
-- --   (-0.00117356,0.00062728)
-- --   (-0.00200427,0.00083020)
-- --   (-0.00395641,0.00120017)
-- --   (-0.01105730,0.00219944)
-- --   (0.50467924,-0.04970657)


-- -- # python numpy 的验证    
-- --     import numpy as np
-- --     x = np.linspace(0, 2 * np.pi, 32) #创建一个包含30个点的余弦波信号
-- --     wave = np.cos(x)
-- --     print(wave)
-- --     transformed = np.fft.fft(wave)  #使用fft函数对余弦波信号进行傅里叶变换。
-- --     itransformed = np.fft.ifft(wave)  #使用ifft函数对余弦波信号进行傅里叶逆变换。
-- --     print(np.fft.ifft(transformed))
-- --     print(transformed)
-- --     print(itransformed)