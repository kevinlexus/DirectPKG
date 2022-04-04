CREATE OR REPLACE TRIGGER SCOTT.C_HOUSES_ADU_L2C
  AFTER delete or update on SCOTT.C_HOUSES
begin
  if lower(user) <> 'gen' and scott.p_java.c_houses_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheHouse');
  end if;

end;
/

