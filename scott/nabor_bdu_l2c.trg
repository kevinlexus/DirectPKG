CREATE OR REPLACE TRIGGER SCOTT.NABOR_BDU_L2C
  BEFORE delete or update on SCOTT.NABOR
begin
  scott.p_java.nabor_updated_cnt := 0;
end;
/

