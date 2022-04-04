CREATE OR REPLACE TRIGGER SCOTT.T_OBJXPAR_ADU_L2C
  AFTER delete or update on SCOTT.T_OBJXPAR
begin
  if lower(user) <> 'gen' and scott.p_java.t_objxpar_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheObjPar');
  end if;

end;
/

