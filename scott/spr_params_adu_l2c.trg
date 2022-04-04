CREATE OR REPLACE TRIGGER SCOTT.spr_params_adu_l2c
  -- после удаления, обновления (но не добавления, при добавлении сам загрузит в L2C)
  after delete or update on spr_params
begin
  -- очистить кэш Hibernate L2C
  p_java.evictL2Cache;

end spr_params_adu_l2c;
/

