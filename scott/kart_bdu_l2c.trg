CREATE OR REPLACE TRIGGER SCOTT.KART_BDU_L2C
  BEFORE delete or update on SCOTT.KART
begin
  scott.p_java.kart_updated_cnt := 0;
end;
/

