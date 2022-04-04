CREATE OR REPLACE TRIGGER SCOTT.METER_BDU_L2C
  BEFORE delete or update on SCOTT.METER
begin
  scott.p_java.meter_updated_cnt := 0;
end;
/

