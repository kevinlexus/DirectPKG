CREATE OR REPLACE TRIGGER EXS.EOLINK_ADU_L2C
  AFTER delete or update on EXS.EOLINK
begin
  if lower(user) <> 'gen' and scott.p_java.eolink_updated_cnt > 1 then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheEolink');
  end if;

end;
/

