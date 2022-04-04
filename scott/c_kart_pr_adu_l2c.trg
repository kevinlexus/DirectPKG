CREATE OR REPLACE TRIGGER SCOTT.C_KART_PR_ADU_L2C
  AFTER delete or update on SCOTT.C_KART_PR
begin
  if lower(user) <> 'gen' and scott.p_java.c_kart_pr_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheKartPr');
  end if;

end;
/

