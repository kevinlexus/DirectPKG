CREATE OR REPLACE TRIGGER SCOTT.usl_round_adu_l2c
  -- после удаления, обновления (но не добавления, при добавлении сам загрузит в L2C)
  after delete or update on usl_round
begin
  -- очистить кэш Hibernate L2C
  p_java.evictL2Cache;

end usl_round_adu_l2c;
/

