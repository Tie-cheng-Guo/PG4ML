-- sigmoid: i_depdt = 1.0 :: float/ (1.0 :: float+ exp(-i_indepdt))
-- https://baijiahao.baidu.com/s?id=1653421414340022957
-- https://blog.csdn.net/qq_29831163/article/details/89887655
-- drop function if exists sm_sc.fv_sigmoid(float);
create or replace function sm_sc.fv_sigmoid
(
  i_indepdt                float
)
returns float
as
$$
-- declare
begin
  if i_indepdt >= 0 
  then
    return 
      -- 幂运算下溢元素，用 -inf 替代
      1.0 :: float
      / 
      (
        1.0 :: float
        + 
        exp
        (
          case 
            when i_indepdt > 7.45e2 
              then '-inf' 
            else -i_indepdt 
          end
        )
      )
    ;
  else 
    -- 上溢，直接返回
    if i_indepdt < -7.09e2 :: float 
    then 
      return 0.0 :: float;
    else 
      return 
        -- 幂运算下溢元素，用 -inf 替代
        1.0 :: float
        / 
        (
          1.0 :: float
          + 
          exp
          (
            -i_indepdt
          )
        )
      ;
    end if;
  end if;
end
$$
language plpgsql stable;


-- select sm_sc.fv_sigmoid(-2.0 :: float)
-- select sm_sc.fv_sigmoid(0.0 :: float)
-- select sm_sc.fv_sigmoid(1.0 :: float)
