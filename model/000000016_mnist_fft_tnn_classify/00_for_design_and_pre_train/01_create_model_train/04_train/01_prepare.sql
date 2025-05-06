
-- 参数一：work_no
-- 参数二：训练次数，改参数可在一波训练后，修改为更大次数，继续准备->执行
call sm_sc.prc_nn_prepare_p
(
  i_work_no             =>  -000000016  
, i_limit_train_times   =>  500              
, i_batch_amt_per_range =>  array_fill(2, array[10])
, i_batch_range         =>  
  array
  [
    int4range(    1,  4000, '[]')
  , int4range( 5924,  9924, '[]')
  , int4range(12666, 16666, '[]')
  , int4range(18624, 22624, '[]')
  , int4range(24755, 28755, '[]')
  , int4range(30597, 34597, '[]')
  , int4range(36018, 40018, '[]')
  , int4range(41936, 45936, '[]')
  , int4range(48201, 52201, '[]')
  , int4range(54053, 58053, '[]')
  --   array[1    , 5924 , 12666, 18624, 24755, 30597, 36018, 41936, 48201, 54053]
  -- , array[4000 , 9924 , 16666, 22624, 28755, 34597, 40018, 45936, 52201, 58053]   -- 每类别 4000 共 40000， 当做训练集
  ]
);
