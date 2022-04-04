CREATE OR REPLACE TRIGGER SCOTT.METER_ADU_E_L2C
  AFTER delete or update on SCOTT.METER
  FOR EACH ROW
begin
  if lower(user) <> 'gen' and scott.p_java.meter_updated_cnt = 0
    then
    scott.p_java.evictl2centity(p_entity => 'com.dic.bill.model.scott.Meter',
                        p_id => :old.id);
  end if;
  scott.p_java.meter_updated_cnt:=scott.p_java.meter_updated_cnt+1;

end;
/

