CREATE OR REPLACE TRIGGER EXS.TASK_BDU_L2C
  BEFORE delete or update on EXS.TASK
begin
  scott.p_java.task_updated_cnt := 0;
end;
/

