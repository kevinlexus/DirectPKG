CREATE OR REPLACE TRIGGER SCOTT.NABOR_ADU_L2C
  AFTER delete or update on SCOTT.NABOR
begin
  if lower(user) <> 'gen' and scott.p_java.nabor_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheNabor');
  end if;

end;
/

