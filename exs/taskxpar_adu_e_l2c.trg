CREATE OR REPLACE TRIGGER EXS.TASKXPAR_ADU_E_L2C
  AFTER delete or update on EXS.TASKXPAR
  FOR EACH ROW
begin
  if lower(user) <> 'gen' and scott.p_java.TASKXPAR_updated_cnt = 0 then
    scott.p_java.evictl2centity(p_entity => 'com.dic.bill.model.exs.TaskPar',
                        p_id => :old.id);
  end if;
  scott.p_java.TASKXPAR_updated_cnt:=scott.p_java.taskxpar_updated_cnt+1;

end;
/

