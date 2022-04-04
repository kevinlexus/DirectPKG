CREATE OR REPLACE TRIGGER EXS.TASKXPAR_BDU_L2C
  BEFORE delete or update on EXS.TASKXPAR
begin
  scott.p_java.taskxpar_updated_cnt := 0;
end;
/

