-- drop function if exists sm_sc.fv_sgn_fft(sm_sc.typ_l_complex[]);
create or replace function sm_sc.fv_sgn_fft
(
  i_array           sm_sc.typ_l_complex[]
)
returns sm_sc.typ_l_complex[]
as
$$
-- -- declare -- here
-- -- -- 如果要返回任意长度，要做循环卷积改造 https://blog.csdn.net/weixin_34128237/article/details/94637989
-- --   v_len_1_ex     int   := case when array_ndims(i_array) = 1 then power(2.0, ceil(log(2.0, array_length(i_array, 1)))) :: int else null end;     -- 时域补零至就近的power(2,n)，频域升采样
-- --   v_w            sm_sc.typ_l_complex     :=   (exp(1)::sm_sc.typ_l_complex) ^ ((0.0 :: float, -2 * pi() / v_len_1_ex)::sm_sc.typ_l_complex);
-- --   v_w_wheel      sm_sc.typ_l_complex     :=   (1.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex;
-- --   v_arr_even     sm_sc.typ_l_complex[]   :=   (select array_agg(coalesce(i_array[a_even_no], (0.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex) order by a_even_no) from generate_series(1, v_len_1_ex, 2) tb_a_even_no(a_even_no));
-- --   v_arr_odd      sm_sc.typ_l_complex[]   :=   (select array_agg(coalesce(i_array[a_odd_no], (0.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex) order by a_odd_no) from generate_series(2, v_len_1_ex, 2) tb_a_odd_no(a_odd_no));
-- --   v_ret          sm_sc.typ_l_complex[]   :=   array_fill(0.0 :: float, array[v_len_1_ex]);
-- --   v_cur          int;
-- -- 
-- -- begin
-- --   if array_ndims(i_array) = 1
-- --   then 
-- --     if v_len_1_ex = 1
-- --     then 
-- --       return array[coalesce(i_array[1], (0.0 :: float, 0.0 :: float)::sm_sc.typ_l_complex)];
-- --     end if;
-- --     
-- --     v_arr_even := sm_sc.fv_sgn_fft(v_arr_even);    -- sm_sc.fv_sgn_fft(v_arr_even[1] || (v_arr_even[2 : ] |+~| 1));
-- --     v_arr_odd := sm_sc.fv_sgn_fft(v_arr_odd);    -- sm_sc.fv_sgn_fft(v_arr_odd[1] || (v_arr_odd[2 : ] |+~| 1));
-- --     
-- --     for v_cur in 1 .. (v_len_1_ex / 2)
-- --     loop
-- --       v_ret[v_cur] := v_arr_even[v_cur] + (v_w_wheel * v_arr_odd[v_cur]);
-- --       v_ret[v_cur + v_len_1_ex / 2] := v_arr_even[v_cur] - (v_w_wheel * v_arr_odd[v_cur]);
-- --       v_w_wheel := v_w_wheel * v_w;
-- --     end loop;
-- --     
-- --     return v_ret;    -- v_ret[1] || (v_ret[2 : ] |+~| 1); 
-- --   else
-- --     raise exception 'error dim!';
-- --   end if;
-- -- end 
declare 
  v_fft   float[]    :=    
    sm_sc.__fv_sgn_fft_py
    (
      sm_sc.fv_opr_real(i_array)
    , sm_sc.fv_opr_imaginary(i_array)
    )
  ;
begin 
  return 
    sm_sc.fv_mx_descend_dim_py(v_fft[1 : 1]) :: sm_sc.typ_l_complex[] 
    +` 
    (sm_sc.fv_mx_descend_dim_py(v_fft[2 : 2]) :: sm_sc.typ_l_complex[] *` ((0,1) :: sm_sc.typ_l_complex))
  ;
end
$$
language plpgsql stable
cost 100;

-- select sm_sc.fv_sgn_fft
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
-- --     [ 1.00000000e+00+0.00000000e+00j  1.61497357e+01+1.59061014e+00j
-- --      -3.53833224e-01-7.03818042e-02j -1.26604779e-01-3.84051399e-02j
-- --      -6.41365736e-02-2.65662386e-02j -3.75538211e-02-2.00729356e-02j
-- --      -2.37109631e-02-1.58431590e-02j -1.55930224e-02-1.27968628e-02j
-- --      -1.04489194e-02-1.04489194e-02j -7.01356383e-03-8.54605226e-03j
-- --      -4.63822579e-03-6.94159545e-03j -2.96316279e-03-5.54368767e-03j
-- --      -1.77736596e-03-4.29094101e-03j -9.52464878e-04-3.13985591e-03j
-- --      -4.09315616e-04-2.05776856e-03j -1.00322243e-04-1.01858882e-03j
-- --       2.22044605e-16+0.00000000e+00j -1.00322243e-04+1.01858882e-03j
-- --      -4.09315616e-04+2.05776856e-03j -9.52464878e-04+3.13985591e-03j
-- --      -1.77736596e-03+4.29094101e-03j -2.96316279e-03+5.54368767e-03j
-- --      -4.63822579e-03+6.94159545e-03j -7.01356383e-03+8.54605226e-03j
-- --      -1.04489194e-02+1.04489194e-02j -1.55930224e-02+1.27968628e-02j
-- --      -2.37109631e-02+1.58431590e-02j -3.75538211e-02+2.00729356e-02j
-- --      -6.41365736e-02+2.65662386e-02j -1.26604779e-01+3.84051399e-02j
-- --      -3.53833224e-01+7.03818042e-02j  1.61497357e+01-1.59061014e+00j]


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