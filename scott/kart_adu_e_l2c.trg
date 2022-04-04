CREATE OR REPLACE TRIGGER SCOTT.KART_ADU_E_L2C
  AFTER delete or update on SCOTT.KART
  FOR EACH ROW
begin
  if lower(user) <> 'gen' and scott.p_java.kart_updated_cnt = 0
    and nvl(c_charges.trg_klsk_flag,0)=0 -- только в триггере Kart, чтобы не выполнилось каскадом от KART_AUID
    then
    scott.p_java.evictl2centity(p_entity => 'com.dic.bill.model.scott.Kart',
                        p_id => :old.lsk);
  end if;
  scott.p_java.kart_updated_cnt:=scott.p_java.kart_updated_cnt+1;

end;
/

