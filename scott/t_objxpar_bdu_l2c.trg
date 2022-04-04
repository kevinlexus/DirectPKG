CREATE OR REPLACE TRIGGER SCOTT.T_OBJXPAR_BDU_L2C
  BEFORE delete or update on SCOTT.T_OBJXPAR
begin
  scott.p_java.t_objxpar_updated_cnt := 0;
end;
/

