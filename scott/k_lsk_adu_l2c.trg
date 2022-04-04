CREATE OR REPLACE TRIGGER SCOTT.K_LSK_ADU_L2C
  AFTER delete or update on SCOTT.K_LSK
begin
  if lower(user) <> 'gen' and scott.p_java.k_lsk_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheKo');
  end if;

end;
/

