CREATE OR REPLACE TRIGGER SCOTT.t_org_adu_l2c
  -- после удаления, обновления (но не добавления, при добавлении сам загрузит в L2C)
  -- TODO: плохо будет это работать, так как Java увидит изменения только после коммита, а обновит старые данные... ред. 04.06.2019
  after delete or update on t_org
begin
  -- очистить кэш Hibernate L2C
  p_java.evictL2Cache;

end t_org_adu_l2c;
/

