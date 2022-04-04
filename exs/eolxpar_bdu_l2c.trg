CREATE OR REPLACE TRIGGER EXS.EOLXPAR_BDU_L2C
  BEFORE delete or update on EXS.EOLXPAR
begin
  scott.p_java.eolxpar_updated_cnt := 0;
end;
/

