CREATE OR REPLACE TRIGGER SCOTT.C_HOUSES_BDU_L2C
  BEFORE delete or update on SCOTT.C_HOUSES
begin
  scott.p_java.c_houses_updated_cnt := 0;
end;
/

