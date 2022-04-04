CREATE OR REPLACE TRIGGER SCOTT.KART_ADU_L2C
  AFTER delete or update on SCOTT.KART
begin
  if lower(user) <> 'gen' and scott.p_java.kart_updated_cnt > 1
      and nvl(c_charges.trg_klsk_flag,0)=0 -- только в триггере Kart, чтобы не выполнилось каскадом от KART_AUID
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheKart');
  end if;

end;
/

