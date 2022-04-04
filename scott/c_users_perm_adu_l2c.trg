CREATE OR REPLACE TRIGGER SCOTT.C_USERS_PERM_ADU_L2C
  AFTER delete or update on SCOTT.C_USERS_PERM
begin
  if lower(user) <> 'gen' and scott.p_java.C_USERS_PERM_updated_cnt > 1
      then
    scott.p_java.evictl2cregion(p_region => 'BillDirectEntitiesCacheUserPerm');
  end if;

end;
/

