-- set search_path to sm_sc;
-- drop function if exists sm_sc.fv_opr_prod_mx_quantum_py(float[], float[], int);
create or replace function sm_sc.fv_opr_prod_mx_quantum_py
(
  i_left         float[]
, i_right        float[]
, i_threads_cnt  int      default 16
)
returns float[]
as
$$
  import numpy as np
  # import concurrent.futures
  # import threading
  import sys
  import asyncio
  # import numba as nb

  if "v_quantum_dic" in GD:
    v_quantum_dic = GD["v_quantum_dic"]
  else:
    v_quantum_dic = np.float64( \
                      plpy.execute("""select
                                        array[0 || sign_reciprocal_quantum_arr || 'inf' :: real] as sign_reciprocal_quantum_arr
                                      from sm_sc.__vt_prod_mx_quantum_dic_arr""" \
                                  , 1)[0]["sign_reciprocal_quantum_arr"] \
                                )
    GD["v_quantum_dic"] = v_quantum_dic
    
  if "v_quantum_antilogarithm" in GD:
    v_quantum_antilogarithm = GD["v_quantum_antilogarithm"]
  else:
    v_quantum_antilogarithm = np.float64( \
                                plpy.execute("""select
                                                  2.0 ^ (1.0 / sign_reciprocal_quantum_arr_desc[1]) as quantum_antilogarithm
                                                from sm_sc.__vt_prod_mx_quantum_dic_arr""" \
                                              , 1)[0]["quantum_antilogarithm"] \
                                        )
    GD["v_quantum_antilogarithm"] = v_quantum_antilogarithm
    
  if "v_quantum_range_abs" in GD:
    v_quantum_range_abs = GD["v_quantum_range_abs"]
  else:
    v_quantum_range_abs = int( \
                            plpy.execute("""select
                                              sign_reciprocal_quantum_arr_desc[1] * sign_reciprocal_quantum_arr_desc[2] as quantum_range_abs
                                            from sm_sc.__vt_prod_mx_quantum_dic_arr""" \
                                        , 1)[0]["quantum_range_abs"] \
                             )
    GD["v_quantum_range_abs"] = v_quantum_range_abs

  v_left = np.float64(i_left)  
  v_right = np.float64(i_right)  
  
  # 对矩阵整体缩放，
  # 既考虑寻找矩阵最大值，如果可能越界 v_quantum_dic 的最大量级范围；
  # 又考虑将量级迁移至 1 附近，尽量提高精度
  # 还考虑 0 值和 inf 值
  v_abs_left = abs(v_left)
  v_abs_right = abs(v_right)
  
  v_scale_factor_left = np.nan_to_num(np.nanmax(np.where((v_abs_left == 0) & (v_abs_left == np.inf), np.nan, v_abs_left)),nan = 1.0)
  v_scale_factor_right = np.nan_to_num(np.nanmax(np.where((v_abs_right == 0) & (v_abs_right == np.inf), np.nan, v_abs_right)),nan = 1.0)

  v_left /= v_scale_factor_left
  v_right /= v_scale_factor_right
  
  # python 数组的下标从 0 开始，而不能像 pg 的 array 一样指定下标上标
  # 所以以下要对其中一目 v_right_log(_ex) 的 log 结果偏移，与 v_quantum_dic 一致
  v_left_log = np.int32(np.round(np.nan_to_num(np.log2(abs(v_left)) / np.log2(v_quantum_antilogarithm), neginf = -(2 ** 30 - 1))))
  v_right_log_ex = np.int32(np.round(np.nan_to_num(np.log2(abs(v_right)) / np.log2(v_quantum_antilogarithm), neginf = -(2 ** 30 - 1)))) + (v_quantum_range_abs + 1)
  v_left_sign = np.sign(v_left)
  v_right_sign = np.sign(v_right)
  
  if v_left.ndim == 2 & v_right.ndim == 2 :
    v_heigh = v_left.shape[0]
    v_width = v_right.shape[1]
    v_thick = v_right.shape[0]
    
    v_threads_cnt = min([i_threads_cnt, v_thick])
    v_ret = dict(zip(np.arange(v_threads_cnt), np.zeros([v_threads_cnt, v_heigh, v_width])))
    
    # 以下部分要做并行化和非连续内存分配策略，SIMD, DMA, scatter/gather gpu 等改造
    
    # v_locks = {}
    
    # def cur_thick(v_cur_thick):
    async def cur_thick(v_cur_thick): 
      # global v_quantum_dic, v_left_log, v_right_log_ex, v_left_sign, v_right_sign
      v_ret_abs = np.take_along_axis(v_quantum_dic \
                                     , np.minimum(np.maximum(v_left_log[:, v_cur_thick : v_cur_thick + 1] + v_right_log_ex[v_cur_thick : v_cur_thick + 1, :], 0), v_quantum_range_abs + 1) \
                                     , axis=1)
      v_lock_no = v_cur_thick % v_threads_cnt  # int(round(np.random.rand() * v_threads_cnt))
      # v_locks[v_lock_no] = threading.Lock()
      # with v_locks[v_lock_no]:
      # #   plpy.info("thread_id: ", threading.current_thread().ident)
      v_ret[v_lock_no] \
              += np.where(v_left_sign[:, v_cur_thick : v_cur_thick + 1] == v_right_sign[v_cur_thick : v_cur_thick + 1, :] \
                         , v_ret_abs \
                         , -v_ret_abs)

    # # with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:   
    # with concurrent.futures.ProcessPoolExecutor() as executor:   
    #   # executor.submit(cur_thick, v_cur_thick) : v_cur_thick for v_cur_thick in range(v_thick)  
    #   executor.map(cur_thick, range(v_thick))        

    async def main():
      v_tasks = [asyncio.create_task(cur_thick(v_cur_thick)) for v_cur_thick in range(v_thick)]
      await asyncio.gather(*v_tasks)
      
    asyncio.run(main())

  # elif v_left.ndim == 3 & v_right.ndim == 3 :
  
  
  if v_scale_factor_left * v_scale_factor_right == 1.0 :
    return np.float64([*v_ret.values()]).sum(axis = 0).tolist()
  else :
    return (np.float64([*v_ret.values()]).sum(axis = 0) * (v_scale_factor_left * v_scale_factor_right)).tolist()
$$
language plpython3u stable
parallel safe
cost 100;
-- -- set search_path to sm_sc;
-- select sm_sc.fv_opr_prod_mx_quantum_py
--   (
--     array[array[1.,2.,3.], array[4.,5.,6.]],
--     array[array[1.,3.,5.,7. ], array[5.,7.,9.,11.], array[9.,11.,13.,15.]]
--   ) :: decimal[] ~=` 5; -- {{38,50,62,74},{83,113,143,173}};
-- select sm_sc.fv_opr_prod_mx_quantum_py
--   (
--     array[array[0.,0.,0.], array[4.,5.,6.]],
--     array[array[1.,3.,5.,7. ], array[0.,0.,0.,0.], array[9.,11.,13.,15.]]
--   );

-- with 
-- cte_arr as 
-- (
--   select 
--     sm_sc.fv_new_randn(0.0, 1.0, array[3, 4]) as a_left
--   , sm_sc.fv_new_randn(0.0, 1.0, array[4, 5]) as a_right
-- )
-- select 
--   sm_sc.fv_opr_prod_mx_quantum_py(a_left, a_right) :: decimal[] ~=` 6
-- , sm_sc.fv_opr_prod_mx_py(a_left, a_right) :: decimal[] ~=` 6
-- from cte_arr

-- select array_dims(
--   sm_sc.fv_opr_prod_mx_quantum_py
--   (
--     sm_sc.fv_new_randn(0.0, 1.0, array[5000, 1])
--   , sm_sc.fv_new_randn(0.0, 1.0, array[1, 5000])
--   ))
-- select array_dims(
--   sm_sc.fv_opr_prod_mx_py
--   (
--     sm_sc.fv_new_randn(0.0, 1.0, array[5000, 1])
--   , sm_sc.fv_new_randn(0.0, 1.0, array[1, 5000])
--   ))