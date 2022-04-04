CREATE OR REPLACE TRIGGER SCOTT.METER_ADU_L2C
  AFTER delete or update on SCOTT.METER
begin
  if lower(user) <> 'gen' and scott.p_java.meter_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheMeter');
  end if;

end;
/

