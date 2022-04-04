CREATE OR REPLACE TRIGGER SCOTT.K_LSK_BDU_L2C
  BEFORE delete or update on SCOTT.K_LSK
begin
  scott.p_java.k_lsk_updated_cnt := 0;
end;
/

