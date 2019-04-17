CREATE OR REPLACE TRIGGER SCOTT.prices_adu_l2c
  -- после удаления, обновления (но не добавления, при добавлении сам загрузит в L2C)
  after delete or update on prices
begin
  -- очистить кэш Hibernate L2C
  p_java.evictL2Cache;

end prices_adu_l2c;
/

