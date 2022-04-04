CREATE OR REPLACE TRIGGER SCOTT.C_KART_PR_BDU_L2C
  BEFORE delete or update on SCOTT.C_KART_PR
begin
  scott.p_java.c_kart_pr_updated_cnt := 0;
end;
/

