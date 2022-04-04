CREATE OR REPLACE TRIGGER EXS.EOLXPAR_ADU_E_L2C
  AFTER delete or update on EXS.EOLXPAR
  FOR EACH ROW
begin
  if lower(user) <> 'gen' and scott.p_java.EOLXPAR_updated_cnt = 0 then
    scott.p_java.evictl2centity(p_entity => 'com.dic.bill.model.exs.EolinkPar',
                        p_id => :old.id);
  end if;
  scott.p_java.EOLXPAR_updated_cnt:=scott.p_java.eolxpar_updated_cnt+1;

end;
/

