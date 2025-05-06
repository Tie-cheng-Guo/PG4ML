  do
  $$
    declare 
      w32  float[]    :=  array[[-10.0], [20.0]]    ;   -- 30000002     ， 权重
      
      x0   float      := 1.0;    -- x[0], 偏移量
      x    float[]    := array[[0.0]]    -- array[[0.0]], array[[1.0]]    ，属性值
                               :: float[]
                            +` sm_sc.fv_new_randn(0.0, 0.1, array[1, 1]);  
                            
   -- y    float       := 0.0;                 -- 0.0,               1.0   ，期望判断结果
    begin
      raise notice 'x: %', x;
      raise notice 'y: ;%',
          sm_sc.fv_sigmoid
          (
            x0 * w32[1][1] + x[1][1] * w32[2][1]   -- 40000001   -- (x0 |||| x) |**| w32
          )    -- 50000001
      ;
    end
  $$
  language plpgsql;