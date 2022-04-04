CREATE OR REPLACE TRIGGER SCOTT.T_OBJXPAR_ADU_E_L2C
  AFTER delete or update on SCOTT.T_OBJXPAR
  FOR EACH ROW
begin
  if lower(user) <> 'gen' and scott.p_java.t_objxpar_updated_cnt = 0
    then
    scott.p_java.evictl2centity(p_entity => 'com.dic.bill.model.scott.ObjPar',
                        p_id => :old.id);
  end if;
  scott.p_java.t_objxpar_updated_cnt:=scott.p_java.t_objxpar_updated_cnt+1;

end;
/

