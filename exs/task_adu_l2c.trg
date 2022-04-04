CREATE OR REPLACE TRIGGER EXS.TASK_ADU_L2C
  AFTER delete or update on EXS.TASK
begin
  if lower(user) <> 'gen' and scott.p_java.TASK_updated_cnt > 1 then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheTask');
  end if;

end;
/

