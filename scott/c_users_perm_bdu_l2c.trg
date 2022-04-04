CREATE OR REPLACE TRIGGER SCOTT.C_USERS_PERM_BDU_L2C
  BEFORE delete or update on SCOTT.C_USERS_PERM
begin
  scott.p_java.C_USERS_PERM_updated_cnt := 0;
end;
/

