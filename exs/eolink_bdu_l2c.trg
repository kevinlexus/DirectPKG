CREATE OR REPLACE TRIGGER EXS.EOLINK_BDU_L2C
  BEFORE delete or update on EXS.EOLINK
begin
  scott.p_java.eolink_updated_cnt := 0;
end;
/

