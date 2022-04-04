CREATE OR REPLACE TRIGGER EXS.TASKXPAR_ADU_L2C
  AFTER delete or update on EXS.TASKXPAR
begin
  if lower(user) <> 'gen' and scott.p_java.taskxpar_updated_cnt > 1 then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheTaskPar');
  end if;

end;
/

