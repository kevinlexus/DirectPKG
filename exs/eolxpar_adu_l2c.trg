CREATE OR REPLACE TRIGGER EXS.EOLXPAR_ADU_L2C
  AFTER delete or update on EXS.EOLXPAR
begin
  if lower(user) <> 'gen' and scott.p_java.eolxpar_updated_cnt > 1 then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheEolinkPar');
  end if;

end;
/

